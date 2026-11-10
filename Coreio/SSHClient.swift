import Foundation
import Darwin

struct SSHResult {
    let exitCode: Int32
    let output: String
    var isSuccess: Bool { exitCode == 0 }
}

enum SSHError: LocalizedError {
    case notAvailable
    case spawnFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "未检测到可用的 OpenSSH（/var/jb/usr/bin/ssh）"
        case let .spawnFailed(code): return "无法启动 ssh 进程（错误码 \(code)）"
        }
    }
}

enum RiskLevel {
    case safe
    case risky
}

enum SSHCommandAnalyzer {
    private static let readOnly: Set<String> = [
        "ls", "cat", "ps", "df", "du", "id", "uname", "pwd", "echo", "find", "grep",
        "head", "tail", "which", "stat", "file", "date", "uptime", "wc", "sort",
        "uniq", "cut", "tr", "mount", "ifconfig", "free", "sysctl", "whoami",
        "printenv", "md5sum", "sha256sum", "netstat", "basename", "dirname", "xxd",
        "strings", "sw_vers", "top", "lsof", "locale", "pidof",
    ]

    /// 判定一条命令是只读还是高风险（用于「风险确认」模式）
    static func level(for command: String) -> RiskLevel {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .safe }
        if trimmed.contains(">") || trimmed.contains("$(") || trimmed.contains("`") {
            return .risky
        }
        let parts = trimmed
            .replacingOccurrences(of: ";", with: "|")
            .replacingOccurrences(of: "&&", with: "|")
            .components(separatedBy: "|")
        for part in parts {
            let tokens = part.split(separator: " ").map(String.init)
            guard let first = tokens.first, !first.isEmpty else { continue }
            let name = (first as NSString).lastPathComponent
            if !readOnly.contains(name) { return .risky }
        }
        return .safe
    }
}

/// 通过 rootless 环境里的 ssh 二进制，在设备本机执行命令
enum SSHRunner {
    private final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    static func run(_ command: String, config: SSHConfig) throws -> SSHResult {
        guard let ssh = JailbreakEnv.sshPath else { throw SSHError.notAvailable }

        var args: [String] = [
            ssh,
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "LogLevel=ERROR",
            "-o", "ConnectTimeout=8",
            "-p", String(config.port),
        ]

        if !config.keyPath.trimmingCharacters(in: .whitespaces).isEmpty {
            args += ["-i", config.keyPath,
                     "-o", "PubkeyAuthentication=yes",
                     "-o", "PreferredAuthentications=publickey"]
        } else {
            args += ["-o", "PubkeyAuthentication=no",
                     "-o", "PreferredAuthentications=password",
                     "-o", "NumberOfPasswordPrompts=1",
                     "-o", "PasswordAuthentication=yes"]
        }

        args += ["\(config.user)@\(config.host)", command]

        var env: [String: String] = [
            "PATH": "/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": NSHomeDirectory(),
            "TERM": "dumb",
        ]

        if config.keyPath.trimmingCharacters(in: .whitespaces).isEmpty {
            // 密码登录：写一个 askpass 脚本，交给系统 /bin/sh 执行，不需要额外可执行文件
            let dir = FileManager.default.temporaryDirectory
            let script = dir.appendingPathComponent("coreio_askpass.sh")
            let passFile = dir.appendingPathComponent("coreio_pass.txt")
            try? config.password.write(to: passFile, atomically: true, encoding: .utf8)
            try? "#!/bin/sh\nexec cat \"$COREIO_PASS_FILE\"\n".write(to: script, atomically: true, encoding: .utf8)
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: script.path)
            env["SSH_ASKPASS"] = script.path
            env["SSH_ASKPASS_REQUIRE"] = "force"
            env["DISPLAY"] = ":0"
            env["COREIO_PASS_FILE"] = passFile.path
        }

        return try exec(ssh, args, environment: env)
    }

    static func exec(_ path: String, _ args: [String], environment: [String: String]) throws -> SSHResult {
        var outFds: [Int32] = [0, 0]
        var errFds: [Int32] = [0, 0]
        guard pipe(&outFds) == 0 else { throw SSHError.spawnFailed(-1) }
        guard pipe(&errFds) == 0 else {
            close(outFds[0]); close(outFds[1])
            throw SSHError.spawnFailed(-2)
        }

        var actions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&actions)

        posix_spawn_file_actions_adddup2(&actions, outFds[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&actions, errFds[1], STDERR_FILENO)
        posix_spawn_file_actions_addclose(&actions, outFds[0])
        posix_spawn_file_actions_addclose(&actions, errFds[0])
        posix_spawn_file_actions_addclose(&actions, outFds[1])
        posix_spawn_file_actions_addclose(&actions, errFds[1])

        var argv = args.map { strdup($0) }
        argv.append(nil)
        var envp = environment.map { strdup("\($0.key)=\($0.value)") }
        envp.append(nil)

        var pid: pid_t = 0
        let spawned = posix_spawn(&pid, path, &actions, nil, &argv, &envp)
        posix_spawn_file_actions_destroy(&actions)

        close(outFds[1])
        close(errFds[1])

        guard spawned == 0 else {
            close(outFds[0]); close(errFds[0])
            throw SSHError.spawnFailed(Int32(spawned))
        }

        let outBox = Box(Data())
        let errBox = Box(Data())
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            outBox.value = readAll(outFds[0])
            group.leave()
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            errBox.value = readAll(errFds[0])
            group.leave()
        }
        group.wait()

        var status: Int32 = 0
        waitpid(pid, &status, 0)
        close(outFds[0])
        close(errFds[0])

        let exitCode = Int32((status >> 8) & 0xFF)
        let stdout = String(data: outBox.value, encoding: .utf8) ?? ""
        let stderr = String(data: errBox.value, encoding: .utf8) ?? ""
        let merged = [stdout, stderr].filter { !$0.isEmpty }.joined(separator: stderr.isEmpty ? "" : "\n")
        return SSHResult(exitCode: exitCode, output: merged.isEmpty ? "(无输出)" : merged)
    }

    private static func readAll(_ fd: Int32) -> Data {
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let n = buffer.withUnsafeMutableBytes { read(fd, $0.baseAddress, 4096) }
            if n <= 0 { break }
            data.append(contentsOf: buffer.prefix(Int(n)))
        }
        return data
    }
}

import Foundation

/// 越狱环境识别结果
enum JailbreakStatus: Equatable {
    case notJailbroken
    case rootless
    case roothide

    var title: String {
        switch self {
        case .notJailbroken: return "未越狱"
        case .rootless: return "Rootless 越狱"
        case .roothide: return "Roothide 越狱"
        }
    }

    var isAvailable: Bool { self != .notJailbroken }
}

enum ShellError: LocalizedError {
    case notJailbroken
    case cancelled
    case spawnFailed(String)
    case nonZeroExit(Int)

    var errorDescription: String? {
        switch self {
        case .notJailbroken: return "设备未越狱，终端不可用"
        case .cancelled: return "已取消执行"
        case .spawnFailed(let msg): return "启动 Shell 失败：\(msg)"
        case .nonZeroExit(let code): return "命令退出，状态码 \(code)"
        }
    }
}

struct ShellLine: Identifiable, Equatable {
    enum Kind { case input, output, error }
    let id: UUID
    let kind: Kind
    let text: String

    init(id: UUID = UUID(), kind: Kind, text: String) {
        self.id = id
        self.kind = kind
        self.text = text
    }
}

/// 终端命令执行器。
/// 仅在越狱环境下通过 /bin/sh 执行命令；非越狱环境直接返回不可用错误。
final class ShellExecutor: ObservableObject {
    @Published var lines: [ShellLine] = []

    /// 检测当前设备越狱类型
    static func detect() -> JailbreakStatus {
        let fm = FileManager.default

        // 1) RootHide（隐根）：隐藏根目录 .jbroot-XXXX 放在 App 包内或其同级目录，
        //    这是沙盒内唯一能可靠看见的 roothide 特征。
        let bundleDirs = [
            Bundle.main.bundleURL.path,
            Bundle.main.bundleURL.deletingLastPathComponent().path,
            "/var/containers/Bundle/Application"
        ]
        for dir in bundleDirs {
            if let items = try? fm.contentsOfDirectory(atPath: dir),
               items.contains(where: { $0.hasPrefix(".jbroot-") }) {
                return .roothide
            }
        }

        // 2) roothide 其它痕迹
        let roothidePaths = [
            "/var/roothide",
            "/private/var/roothide",
            "/var/mobile/Library/Preferences/com.roothide.prefs.plist",
            "/var/mobile/Library/Preferences/com.roothide.prefs",
            "/var/containers/Bundle/Application/.jbroot"
        ]
        if roothidePaths.contains(where: { fm.fileExists(atPath: $0) }) { return .roothide }

        // 3) rootless（Dopamine / palera1n rootless 等）
        let rootlessPaths = [
            "/var/jb",
            "/private/var/jb",
            "/var/jb/usr/bin",
            "/var/jb/usr/sbin",
            "/var/jb/usr/lib/dyld",
            "/usr/lib/libjailbreak.dylib"
        ]
        if rootlessPaths.contains(where: { fm.fileExists(atPath: $0) }) { return .rootless }

        // 4) 传统（非 rootless）越狱痕迹
        let legacyPaths = [
            "/Applications/Cydia.app",
            "/private/var/stash",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/mobile/Library/MobileSubstrate",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/usr/sbin/sshd",
            "/bin/bash"
        ]
        if legacyPaths.contains(where: { fm.fileExists(atPath: $0) }) { return .rootless }

        // 5) 兜底：App 包内存在 jbroot 的软链/marker
        if let items = try? fm.contentsOfDirectory(atPath: Bundle.main.bundleURL.path),
           items.contains(where: { $0.hasPrefix(".jbroot") || $0.hasPrefix("jbroot") }) {
            return .roothide
        }

        return .notJailbroken
    }

    /// 高危命令关键词（小写匹配）
    private static let riskyKeywords = [
        "rm ", "rm -", "sudo", "su ", "dd ", "mkfs", "killall", "kill ",
        "launchctl", "uicache", "mount", "umount", "chmod", "chown",
        "nvram", "reboot", "shutdown", "halt", "nvram", "cp ", "mv ",
        "bash ", "zsh ", "wget ", "curl "
    ]

    func isRisky(_ command: String) -> Bool {
        let lower = command.lowercased()
        return Self.riskyKeywords.contains { lower.contains($0) }
    }

    /// 根据权限模式判断该命令是否需要先弹窗确认
    func shouldConfirm(command: String, permission: ShellPermissionMode) -> Bool {
        switch permission {
        case .ask: return true
        case .risk: return isRisky(command)
        case .allow: return false
        }
    }

    /// 执行命令。confirmed 表示用户已在确认弹窗中同意（无需确认的模式忽略该参数）。
    func execute(_ command: String, permission: ShellPermissionMode, confirmed: Bool) async throws -> String {
        let status = Self.detect()
        guard status.isAvailable else { throw ShellError.notJailbroken }

        switch permission {
        case .ask:
            guard confirmed else { throw ShellError.cancelled }
        case .risk:
            if isRisky(command) { guard confirmed else { throw ShellError.cancelled } }
        case .allow:
            break
        }

        return try await Task.detached { try Self.runShell(command) }.value
    }

    private static func runShell(_ command: String) throws -> String {
        // iOS 上不存在 Process(NSTask)，改用 posix_spawn 启动 /bin/sh
        var fds: [Int32] = [0, 0]
        guard pipe(&fds) == 0 else { throw ShellError.spawnFailed("pipe 创建失败") }

        var actions: posix_spawn_file_actions_t?
        posix_spawn_file_actions_init(&actions)
        posix_spawn_file_actions_adddup2(&actions, fds[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&actions, fds[1], STDERR_FILENO)
        posix_spawn_file_actions_addclose(&actions, fds[0])
        posix_spawn_file_actions_addclose(&actions, fds[1])

        var argv: [UnsafeMutablePointer<CChar>?] = [strdup("/bin/sh"), strdup("-c"), strdup(command), nil]
        var envp: [UnsafeMutablePointer<CChar>?] = [
            strdup("PATH=/var/jb/usr/bin:/var/jb/sbin:/var/jb/bin:/usr/bin:/bin:/usr/sbin:/sbin"),
            strdup("HOME=/var/mobile"),
            nil
        ]

        var pid: pid_t = 0
        let spawned = posix_spawn(&pid, "/bin/sh", &actions, nil, &argv, &envp)
        posix_spawn_file_actions_destroy(&actions)
        argv.forEach { if let p = $0 { free(p) } }
        envp.forEach { if let p = $0 { free(p) } }

        close(fds[1])
        guard spawned == 0, pid > 0 else {
            close(fds[0])
            throw ShellError.spawnFailed("posix_spawn 返回 \(spawned)")
        }

        var output = ""
        var buf = [UInt8](repeating: 0, count: 4096)
        while true {
            var n = 0
            buf.withUnsafeMutableBytes { raw in
                n = Int(read(fds[0], raw.baseAddress, 4096))
            }
            if n <= 0 { break }
            if let chunk = String(bytes: buf[0..<n], encoding: .utf8) {
                output += chunk
            } else if let chunk = String(bytes: buf[0..<n], encoding: .isoLatin1) {
                output += chunk
            }
        }
        close(fds[0])

        var status: Int32 = 0
        waitpid(pid, &status, 0)
        let exitCode = (status >> 8) & 0xFF
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if exitCode != 0 && trimmed.isEmpty {
            throw ShellError.nonZeroExit(Int(exitCode))
        }
        return trimmed.isEmpty ? "(无输出)" : trimmed
    }

    func append(_ line: ShellLine) {
        lines.append(line)
    }

    func clear() {
        lines.removeAll()
    }
}

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

        let roothidePaths = ["/private/var/roothide", "/var/roothide"]
        if roothidePaths.contains(where: fm.fileExists) { return .roothide }

        let rootlessPaths = ["/var/jb", "/private/var/jb", "/var/jb/usr/bin"]
        if rootlessPaths.contains(where: fm.fileExists) { return .rootless }

        let legacyPaths = [
            "/Applications/Cydia.app",
            "/private/var/stash",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/mobile/Library/MobileSubstrate"
        ]
        if legacyPaths.contains(where: fm.fileExists) { return .rootless }

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
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
        } catch {
            throw ShellError.spawnFailed(error.localizedDescription)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        let output = String(data: data, encoding: .utf8) ?? ""
        if task.terminationStatus != 0 && output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ShellError.nonZeroExit(Int(task.terminationStatus))
        }
        return output
    }

    func append(_ line: ShellLine) {
        lines.append(line)
    }

    func clear() {
        lines.removeAll()
    }
}

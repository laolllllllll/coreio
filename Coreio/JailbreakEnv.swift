import Foundation

/// rootless / 越狱环境探测
enum JailbreakEnv {
    static let candidates = [
        "/var/jb/usr/bin/ssh",
        "/var/jb/bin/ssh",
        "/usr/bin/ssh",
        "/var/jb/usr/bin/dbclient",
    ]

    static var rootPrefix: String {
        FileManager.default.fileExists(atPath: "/var/jb") ? "/var/jb" : ""
    }

    static var isRootless: Bool {
        FileManager.default.fileExists(atPath: "/var/jb")
    }

    static var sshPath: String? {
        for path in candidates {
            if FileManager.default.fileExists(atPath: path) { return path }
        }
        return nil
    }

    static var hasOpenSSH: Bool { sshPath != nil }

    /// 满足「rootless + 已安装 OpenSSH」才会出现设备工具
    static var deviceToolsAvailable: Bool { isRootless && hasOpenSSH }

    static var describe: String {
        if !isRootless { return "未检测到 rootless 环境（正常自签 / 未越狱）" }
        if let ssh = sshPath { return "rootless 已就绪，OpenSSH：\(ssh)" }
        return "rootless 已就绪，但未找到 OpenSSH，请先安装 openssh"
    }
}

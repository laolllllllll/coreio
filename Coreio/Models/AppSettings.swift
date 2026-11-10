import Foundation
import SwiftUI

/// 外观模式
enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// 终端工具的权限确认模式
enum ShellPermissionMode: String, Codable, CaseIterable, Identifiable {
    case ask      // 按需确认：每条命令执行前都要确认
    case risk     // 风险确认：仅高危命令需要确认
    case allow    // 全部允许：不再弹窗（有风险）
    var id: String { rawValue }

    var title: String {
        switch self {
        case .ask: return "按需确认"
        case .risk: return "风险确认"
        case .allow: return "全部允许"
        }
    }

    var subtitle: String {
        switch self {
        case .ask: return "每条命令执行前都需要你确认"
        case .risk: return "仅高危命令需要确认，其余直接执行"
        case .allow: return "不弹窗直接执行，请确认了解风险"
        }
    }
}

final class AppSettings: ObservableObject {
    @Published var apiBaseURL: String { didSet { persist() } }
    @Published var apiKey: String { didSet { persist() } }
    @Published var modelID: String { didSet { persist() } }
    @Published var appearance: AppearanceMode { didSet { persist() } }
    @Published var shellPermission: ShellPermissionMode { didSet { persist() } }
    @Published var didCompleteOnboarding: Bool { didSet { persist() } }

    private let defaults = UserDefaults.standard

    private enum Key {
        static let apiBaseURL = "settings.apiBaseURL"
        static let apiKey = "settings.apiKey"
        static let modelID = "settings.modelID"
        static let appearance = "settings.appearance"
        static let shellPermission = "settings.shellPermission"
        static let didCompleteOnboarding = "settings.didCompleteOnboarding"
    }

    init() {
        apiBaseURL = defaults.string(forKey: Key.apiBaseURL) ?? "https://api.openai.com/v1"
        apiKey = defaults.string(forKey: Key.apiKey) ?? ""
        modelID = defaults.string(forKey: Key.modelID) ?? ""
        if let raw = defaults.string(forKey: Key.appearance), let mode = AppearanceMode(rawValue: raw) {
            appearance = mode
        } else {
            appearance = .system
        }
        if let raw = defaults.string(forKey: Key.shellPermission), let mode = ShellPermissionMode(rawValue: raw) {
            shellPermission = mode
        } else {
            shellPermission = .ask
        }
        didCompleteOnboarding = defaults.bool(forKey: Key.didCompleteOnboarding)
    }

    private func persist() {
        defaults.set(apiBaseURL, forKey: Key.apiBaseURL)
        defaults.set(apiKey, forKey: Key.apiKey)
        defaults.set(modelID, forKey: Key.modelID)
        defaults.set(appearance.rawValue, forKey: Key.appearance)
        defaults.set(shellPermission.rawValue, forKey: Key.shellPermission)
        defaults.set(didCompleteOnboarding, forKey: Key.didCompleteOnboarding)
    }

    /// 重置引导（清空 API 配置回到首屏）
    func resetOnboarding() {
        didCompleteOnboarding = false
        apiKey = ""
        modelID = ""
    }
}

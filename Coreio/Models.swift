import Foundation

enum ChatRole: String, Codable, Hashable {
    case system
    case user
    case assistant
}

struct ChatMessage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var role: ChatRole
    var content: String
    var date: Date = Date()
    /// true 表示这条消息是设备工具的本地回显（不发给模型当 assistant 内容使用）
    var isToolOutput: Bool = false
}

struct Conversation: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String = "新对话"
    var messages: [ChatMessage] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var isArchived: Bool = false
}

struct APIConfig: Codable, Equatable {
    var baseURL: String = ""
    var apiKey: String = ""
    var model: String = ""

    var isValid: Bool {
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

enum ToolPermissionMode: String, Codable, CaseIterable, Identifiable {
    case onDemand
    case risky
    case allowAll

    var id: String { rawValue }

    var label: String {
        switch self {
        case .onDemand: return "按需确认"
        case .risky: return "风险确认"
        case .allowAll: return "全部允许"
        }
    }

    var detail: String {
        switch self {
        case .onDemand: return "AI 每执行一条命令都需要你点头"
        case .risky: return "只读命令自动放行，改文件 / 删东西 / 重启这类高风险命令才弹确认"
        case .allowAll: return "全部自动执行，不弹任何确认，请自己承担风险"
        }
    }
}

struct SSHConfig: Codable, Equatable {
    var host: String = "127.0.0.1"
    var port: Int = 22
    var user: String = "root"
    var password: String = "alpine"
    var keyPath: String = ""
}

struct ModelPreset: Identifiable {
    let id = UUID()
    let name: String
    let baseURL: String
    let model: String
    let note: String
}

enum Presets {
    static let list: [ModelPreset] = [
        ModelPreset(name: "智谱 GLM", baseURL: "https://open.bigmodel.cn/api/paas/v4", model: "glm-4-flash", note: "国内直连，长期免费层"),
        ModelPreset(name: "DeepSeek", baseURL: "https://api.deepseek.com/v1", model: "deepseek-chat", note: "便宜稳定，中文强"),
        ModelPreset(name: "Groq", baseURL: "https://api.groq.com/openai/v1", model: "llama-3.3-70b-versatile", note: "速度极快，免费层"),
        ModelPreset(name: "OpenAI", baseURL: "https://api.openai.com/v1", model: "gpt-4o-mini", note: "通用"),
        ModelPreset(name: "OpenRouter", baseURL: "https://openrouter.ai/api/v1", model: "deepseek/deepseek-chat", note: "一个 key 打通多模型"),
        ModelPreset(name: "Gemini", baseURL: "https://generativelanguage.googleapis.com/v1beta/openai", model: "gemini-2.5-flash", note: "免费额度大，支持识图"),
    ]
}

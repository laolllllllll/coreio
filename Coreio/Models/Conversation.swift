import Foundation

/// 单条聊天消息
struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID
    var role: MessageRole
    var content: String
    var toolCalls: [ToolCall]?
    var createdAt: Date

    init(id: UUID = UUID(), role: MessageRole, content: String, toolCalls: [ToolCall]? = nil, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.createdAt = createdAt
    }
}

enum MessageRole: String, Codable {
    case system, user, assistant, tool
}

/// 模型返回的工具调用
struct ToolCall: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var arguments: String
}

/// 一个对话会话
struct Conversation: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var messages: [ChatMessage]
    var isArchived: Bool
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, messages: [ChatMessage] = [], isArchived: Bool = false, updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.messages = messages
        self.isArchived = isArchived
        self.updatedAt = updatedAt
    }
}

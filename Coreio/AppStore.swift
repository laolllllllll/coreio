import Foundation
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    // 配置
    @Published var config = APIConfig() { didSet { persist() } }
    @Published var conversations: [Conversation] = [] { didSet { persist() } }
    @Published var currentID: UUID? { didSet { persist() } }
    @Published var appearance: AppearanceMode = .system { didSet { persist() } }
    @Published var ssh = SSHConfig() { didSet { persist() } }
    @Published var permission: ToolPermissionMode = .onDemand { didSet { persist() } }
    @Published var forceShowTools = false { didSet { persist() } }
    @Published var isConfigured = false { didSet { persist() } }

    // 运行时
    @Published var streamingText = ""
    @Published var isSending = false
    @Published var statusNote: String?
    @Published var approvalCommand: String?

    private var approvalContinuation: CheckedContinuation<Bool, Never>?
    private var loaded = false

    struct Snapshot: Codable {
        var config: APIConfig
        var conversations: [Conversation]
        var currentID: UUID?
        var appearance: AppearanceMode
        var ssh: SSHConfig
        var permission: ToolPermissionMode
        var forceShowTools: Bool
        var isConfigured: Bool
    }

    private static let storageKey = "coreio.snapshot.v1"

    init() {
        load()
        loaded = true
    }

    // MARK: - 派生状态

    var activeConversations: [Conversation] {
        conversations.filter { !$0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var archivedConversations: [Conversation] {
        conversations.filter { $0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var currentConversation: Conversation? {
        guard let currentID else { return nil }
        return conversations.first { $0.id == currentID }
    }

    var deviceToolsVisible: Bool {
        forceShowTools || JailbreakEnv.deviceToolsAvailable
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    // MARK: - 持久化

    private func persist() {
        guard loaded else { return }
        let snapshot = Snapshot(config: config, conversations: conversations, currentID: currentID,
                                appearance: appearance, ssh: ssh, permission: permission,
                                forceShowTools: forceShowTools, isConfigured: isConfigured)
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        config = snapshot.config
        conversations = snapshot.conversations
        currentID = snapshot.currentID
        appearance = snapshot.appearance
        ssh = snapshot.ssh
        permission = snapshot.permission
        forceShowTools = snapshot.forceShowTools
        isConfigured = snapshot.isConfigured
    }

    // MARK: - 连接测试

    /// 发一条测试请求，模型应当只回复 1
    func verify(_ candidate: APIConfig) async throws -> String {
        try await LLMClient(config: candidate).complete(
            messages: [ChatRequestMessage(role: "user",
                                          content: "现在开始连接测试。请只回复一个数字 1，不要输出任何解释、标点或其它文字。")],
            maxTokens: 16
        )
    }

    func finishSetup(with candidate: APIConfig) {
        config = candidate
        isConfigured = true
        if conversations.isEmpty { newConversation() }
        statusNote = nil
    }

    func resetSetup() {
        isConfigured = false
        config = APIConfig(baseURL: config.baseURL, apiKey: "", model: config.model)
    }

    // MARK: - 会话管理

    @discardableResult
    func newConversation() -> UUID {
        let convo = Conversation()
        conversations.insert(convo, at: 0)
        currentID = convo.id
        return convo.id
    }

    func select(_ id: UUID) {
        currentID = id
    }

    func delete(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        if currentID == id {
            currentID = activeConversations.first?.id
        }
    }

    func toggleArchive(_ id: UUID) {
        guard let idx = index(of: id) else { return }
        conversations[idx].isArchived.toggle()
        if conversations[idx].isArchived, currentID == id {
            currentID = activeConversations.first?.id
        }
    }

    func clearAllConversations() {
        conversations.removeAll()
        currentID = nil
        newConversation()
    }

    // MARK: - 发送消息

    func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        if currentConversation == nil { newConversation() }
        guard let id = currentID, let idx = index(of: id) else { return }

        conversations[idx].messages.append(ChatMessage(role: .user, content: trimmed))
        if conversations[idx].title == "新对话" {
            let line = trimmed.replacingOccurrences(of: "\n", with: " ")
            conversations[idx].title = String(line.prefix(18))
        }
        conversations[idx].updatedAt = Date()

        Task { await complete(conversationID: id, round: 0) }
    }

    private func complete(conversationID: UUID, round: Int) async {
        guard let idx = index(of: conversationID) else { return }
        isSending = true
        streamingText = ""
        statusNote = nil

        var buffer = ""
        var errorText: String?
        do {
            for try await chunk in LLMClient(config: config).stream(messages: payload(for: conversations[idx].messages)) {
                buffer += chunk
                streamingText = buffer
            }
        } catch {
            errorText = error.localizedDescription
        }
        streamingText = ""
        isSending = false

        if buffer.isEmpty {
            let note = errorText ?? "没有收到任何内容"
            statusNote = note
            append(ChatMessage(role: .assistant, content: "⚠️ \(note)"), to: conversationID)
            return
        }

        append(ChatMessage(role: .assistant, content: buffer), to: conversationID)

        let ranTools = await runToolCommands(in: buffer, conversationID: conversationID)
        if ranTools, round < 2, deviceToolsVisible {
            await complete(conversationID: conversationID, round: round + 1)
        }
    }

    private func payload(for messages: [ChatMessage]) -> [ChatRequestMessage] {
        var result: [ChatRequestMessage] = [ChatRequestMessage(role: "system", content: systemPrompt)]
        for m in messages.suffix(24) {
            switch m.role {
            case .user:
                result.append(ChatRequestMessage(role: "user", content: m.content))
            case .assistant:
                result.append(ChatRequestMessage(role: "assistant", content: m.content))
            case .system:
                result.append(ChatRequestMessage(role: "user", content: "[设备工具输出]\n\(m.content)"))
            }
        }
        return result
    }

    private var systemPrompt: String {
        var parts: [String] = [
            "你是 Coreio，一个运行在用户 iPhone 上的 AI 助手。回答简洁、直接、可执行，默认使用中文。"
        ]
        if deviceToolsVisible {
            parts.append("""
            你可以操作这台设备：把要执行的命令写进 ```ssh 代码块里，每条命令独占一行，App 会真正执行并把输出回传给你。环境是 rootless 越狱（路径前缀 /var/jb），已装 OpenSSH，通过 ssh root@127.0.0.1 执行。
            动手改东西之前，先用只读命令（ls / cat / ps / df / id）确认现状；删除、覆盖、重启这类操作先说明后果。
            """)
        }
        return parts.joined(separator: "\n\n")
    }

    // MARK: - 工具执行

    private func runToolCommands(in text: String, conversationID: UUID) async -> Bool {
        let commands = ToolCommandParser.commands(in: text)
        guard !commands.isEmpty else { return false }

        var ran = false
        for command in commands {
            let allowed = await shouldRun(command)
            guard allowed else {
                append(ChatMessage(role: .system, content: "已跳过命令（用户拒绝）：\(command)", isToolOutput: true),
                       to: conversationID)
                continue
            }

            let config = ssh
            let text: String
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try SSHRunner.run(command, config: config)
                }.value
                text = "$ \(command)\n[exit \(result.exitCode)]\n\(result.output)"
            } catch {
                text = "$ \(command)\n❌ \(error.localizedDescription)"
            }
            append(ChatMessage(role: .system, content: text, isToolOutput: true), to: conversationID)
            ran = true
        }
        return ran
    }

    private func shouldRun(_ command: String) async -> Bool {
        switch permission {
        case .allowAll:
            return true
        case .risky:
            if SSHCommandAnalyzer.level(for: command) == .safe { return true }
            return await askApproval(command)
        case .onDemand:
            return await askApproval(command)
        }
    }

    private func askApproval(_ command: String) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            approvalContinuation = continuation
            approvalCommand = command
        }
    }

    func resolveApproval(_ allowed: Bool) {
        approvalCommand = nil
        approvalContinuation?.resume(returning: allowed)
        approvalContinuation = nil
    }

    // MARK: - 小工具

    private func index(of id: UUID) -> Int? {
        conversations.firstIndex { $0.id == id }
    }

    private func append(_ message: ChatMessage, to conversationID: UUID) {
        guard let idx = index(of: conversationID) else { return }
        conversations[idx].messages.append(message)
        conversations[idx].updatedAt = Date()
        if message.role == .assistant, conversations[idx].title == "新对话" {
            conversations[idx].title = String(message.content.prefix(18))
        }
    }
}

enum ToolCommandParser {
    /// 从模型输出中解析 ```ssh 代码块，按行拆分
    static func commands(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "```(?:ssh|sh|shell|bash)\\s*\\n([\\s\\S]*?)```", options: []) else {
            return []
        }
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        var result: [String] = []
        for match in matches {
            guard match.numberOfRanges > 1 else { continue }
            let body = ns.substring(with: match.range(at: 1))
            for line in body.components(separatedBy: .newlines) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
                result.append(trimmed)
            }
        }
        return result
    }
}

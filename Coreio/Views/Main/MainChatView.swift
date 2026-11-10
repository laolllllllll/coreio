import SwiftUI

struct MainChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: ConversationStore
    @EnvironmentObject private var registry: ToolRegistry

    @State private var sidebarOpen = false
    @State private var activeID: UUID?
    @State private var draft = ""
    @State private var sending = false
    @State private var showSettings = false
    @State private var showTools = false

    private var activeConversation: Conversation? {
        guard let activeID else { return nil }
        return store.conversation(id: activeID)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            chatColumn

            if sidebarOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { sidebarOpen = false } }
                sidebarPanel
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showTools) { DeviceToolsView() }
        .onAppear { ensureConversation() }
    }

    private var chatColumn: some View {
        VStack(spacing: 0) {
            header
            messageList
            inputBar
        }
    }

    private var header: some View {
        HStack {
            Button {
                withAnimation { sidebarOpen = true }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
            }
            Text("Coreio").font(.headline)
            Spacer()
        }
        .padding()
    }

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let conv = activeConversation, !conv.messages.isEmpty {
                    ForEach(conv.messages) { message in
                        MessageBubble(message: message)
                    }
                } else {
                    VStack(spacing: 8) {
                        Text("开始新对话").font(.title3.bold())
                        Text("在下方输入消息，连接已配置的 AI 服务。")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 80)
                }
            }
            .padding(.vertical)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("发送消息…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await send() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || sending)
        }
        .padding()
    }

    private var sidebarPanel: some View {
        SidebarView(
            activeID: activeID,
            onSelect: { id in
                activeID = id
                withAnimation { sidebarOpen = false }
            },
            onNew: {
                let conv = store.newConversation()
                activeID = conv.id
                withAnimation { sidebarOpen = false }
            },
            onSettings: { showSettings = true },
            onTools: { showTools = true }
        )
        .frame(width: 300)
        .background(Color(.systemBackground))
        .transition(.move(edge: .leading))
    }

    private func ensureConversation() {
        if activeID == nil || store.conversation(id: activeID!) == nil {
            let conv = store.newConversation()
            activeID = conv.id
        }
    }

    private func send() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !sending else { return }
        ensureConversation()
        guard let conv = store.conversation(id: activeID!) else { return }

        var working = conv
        working.messages.append(ChatMessage(role: .user, content: text))
        store.update(working)
        draft = ""
        sending = true
        defer { sending = false }

        let client = APIClient(
            baseURL: settings.apiBaseURL,
            apiKey: settings.apiKey,
            modelID: settings.modelID
        )
        let payload = working.messages.map { msg -> [String: Any] in
            ["role": msg.role.rawValue, "content": msg.content]
        }

        do {
            let reply = try await client.send(messages: payload, tools: registry.schemaPayload())
            guard var updated = store.conversation(id: conv.id) else { return }
            updated.messages.append(ChatMessage(
                role: .assistant,
                content: reply.isEmpty ? "（空回复）" : reply
            ))
            store.update(updated)
        } catch {
            guard var updated = store.conversation(id: conv.id) else { return }
            updated.messages.append(ChatMessage(
                role: .assistant,
                content: "⚠️ \(error.localizedDescription)"
            ))
            store.update(updated)
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer() }
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundColor(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: 280, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer() }
        }
        .padding(.horizontal)
    }
}

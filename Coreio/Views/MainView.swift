import SwiftUI

struct MainView: View {
    @EnvironmentObject private var store: AppStore
    @State private var drawerOpen = false
    @State private var showSettings = false
    @State private var showTools = false
    @State private var input = ""

    var body: some View {
        ZStack(alignment: .leading) {
            chatScreen

            if drawerOpen {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { closeDrawer() }
                DrawerView(onClose: closeDrawer)
                    .frame(width: UIScreen.main.bounds.width * 0.82)
                    .background(.regularMaterial)
                    .ignoresSafeArea(edges: .vertical)
                    .transition(.move(edge: .leading))
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
        .sheet(isPresented: $showTools) {
            DeviceToolsView().environmentObject(store)
        }
        .alert("执行设备命令？",
               isPresented: Binding(
                get: { store.approvalCommand != nil },
                set: { if !$0 { store.resolveApproval(false) } }
               ),
               presenting: store.approvalCommand) { _ in
            Button("拒绝", role: .cancel) { store.resolveApproval(false) }
            Button("允许") { store.resolveApproval(true) }
        } message: { command in
            Text(command)
        }
    }

    // MARK: - 聊天界面

    private var chatScreen: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messageList
            Divider()
            composer
        }
        .background(Color(uiColor: .systemBackground))
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) { drawerOpen = true }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 34, height: 30, alignment: .leading)
            }
            .accessibilityLabel("会话列表")

            VStack(alignment: .leading, spacing: 1) {
                Text(store.currentConversation?.title ?? "Coreio")
                    .font(.headline)
                    .lineLimit(1)
                Text(store.config.model)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                store.newConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .semibold))
            }
            .accessibilityLabel("新建对话")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(store.currentConversation?.messages ?? []) { message in
                        MessageBubble(message: message).id(message.id)
                    }
                    if store.isSending {
                        MessageBubble(message: ChatMessage(role: .assistant,
                                                           content: store.streamingText.isEmpty ? "…" : store.streamingText))
                            .id("streaming")
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
            .onChange(of: store.currentConversation?.messages.count ?? 0) { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: store.streamingText) { _ in
                scrollToBottom(proxy)
            }
            .onChange(of: store.currentID) { _ in
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("发消息…", text: $input, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(uiColor: .secondarySystemBackground)))

                Button(action: send) {
                    Image(systemName: store.isSending ? "hourglass" : "arrow.up.circle.fill")
                        .font(.system(size: 27))
                }
                .disabled(store.isSending || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("发送")
            }

            HStack(spacing: 20) {
                Button { showSettings = true } label: {
                    Label("设置", systemImage: "gearshape")
                }
                if store.deviceToolsVisible {
                    Button { showTools = true } label: {
                        Label("设备工具", systemImage: "wrench.and.screwdriver")
                    }
                }
                Spacer()
                if let note = store.statusNote {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            .font(.footnote)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(.regularMaterial)
    }

    // MARK: - 动作

    private func send() {
        let text = input
        input = ""
        store.send(text)
    }

    private func closeDrawer() {
        withAnimation(.easeIn(duration: 0.18)) { drawerOpen = false }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.15)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        if message.isToolOutput {
            VStack(alignment: .leading, spacing: 5) {
                Label("设备工具", systemImage: "terminal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(message.content)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .secondarySystemBackground)))
        } else if message.role == .user {
            HStack {
                Spacer(minLength: 44)
                Text(message.content)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor.opacity(0.16)))
                    .textSelection(.enabled)
            }
        } else if message.role == .assistant {
            Text(message.content)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 2)
        } else {
            Text(message.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

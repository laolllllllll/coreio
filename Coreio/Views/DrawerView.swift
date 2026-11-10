import SwiftUI

struct DrawerView: View {
    @EnvironmentObject private var store: AppStore
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("会话").font(.title2.weight(.bold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 58)
            .padding(.bottom, 12)

            Button {
                store.newConversation()
                onClose()
            } label: {
                Label("新建对话", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 11)
                    .padding(.horizontal, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.13)))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            List {
                Section {
                    if store.activeConversations.isEmpty {
                        Text("还没有对话").font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(store.activeConversations) { convo in
                        row(convo)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    store.delete(convo.id)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                                Button {
                                    store.toggleArchive(convo.id)
                                } label: {
                                    Label("归档", systemImage: "archivebox")
                                }
                                .tint(.gray)
                            }
                    }
                } header: {
                    Text("对话")
                }

                if !store.archivedConversations.isEmpty {
                    Section {
                        ForEach(store.archivedConversations) { convo in
                            row(convo)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        store.delete(convo.id)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                    Button {
                                        store.toggleArchive(convo.id)
                                    } label: {
                                        Label("恢复", systemImage: "tray.and.arrow.up")
                                    }
                                    .tint(.blue)
                                }
                        }
                    } header: {
                        Text("已归档")
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func row(_ convo: Conversation) -> some View {
        Button {
            store.select(convo.id)
            onClose()
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(convo.title)
                    .font(.subheadline.weight(store.currentID == convo.id ? .semibold : .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(convo.messages.last?.content.replacingOccurrences(of: "\n", with: " ") ?? "空对话")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 2)
        }
        .contextMenu {
            Button {
                store.toggleArchive(convo.id)
            } label: {
                Label(convo.isArchived ? "取消归档" : "归档", systemImage: "archivebox")
            }
            Button(role: .destructive) {
                store.delete(convo.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

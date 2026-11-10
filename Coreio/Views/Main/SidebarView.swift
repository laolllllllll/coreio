import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: ConversationStore

    let activeID: UUID?
    let onSelect: (UUID) -> Void
    let onNew: () -> Void
    let onSettings: () -> Void
    let onTools: () -> Void

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("对话").font(.title2.bold())
                Spacer()
                Button(action: onNew) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            List {
                Section("活跃") {
                    ForEach(store.active) { conv in
                        row(for: conv)
                    }
                }
                Section("归档") {
                    ForEach(store.archived) { conv in
                        row(for: conv)
                    }
                }
            }
            .listStyle(.plain)

            Divider()

            VStack(spacing: 10) {
                Button {
                    onSettings()
                } label: {
                    Label("设置", systemImage: "gearshape")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    onTools()
                } label: {
                    Label("设备工具", systemImage: "terminal")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }

    private func row(for conv: Conversation) -> some View {
        Button {
            onSelect(conv.id)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(conv.title).lineLimit(1)
                    Text(Self.timeFormatter.string(from: conv.updatedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if conv.id == activeID {
                    Image(systemName: "checkmark").foregroundColor(.accentColor)
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.delete(conv.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
            Button {
                store.toggleArchive(conv.id)
            } label: {
                Label(conv.isArchived ? "取消归档" : "归档", systemImage: "archivebox")
            }
            .tint(.blue)
        }
    }
}

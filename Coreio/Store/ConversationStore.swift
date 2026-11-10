import Foundation
import Combine

final class ConversationStore: ObservableObject {
    @Published var conversations: [Conversation] = []

    private let defaults = UserDefaults.standard
    private let key = "store.conversations"

    init() {
        load()
    }

    var active: [Conversation] {
        conversations.filter { !$0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    var archived: [Conversation] {
        conversations.filter { $0.isArchived }.sorted { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    func newConversation() -> Conversation {
        let conv = Conversation(title: "新对话")
        conversations.insert(conv, at: 0)
        save()
        return conv
    }

    func conversation(id: UUID) -> Conversation? {
        conversations.first { $0.id == id }
    }

    func update(_ conv: Conversation) {
        guard let idx = conversations.firstIndex(where: { $0.id == conv.id }) else { return }
        var updated = conv
        updated.updatedAt = Date()
        if updated.messages.count == 1, let first = updated.messages.first, first.role == .user {
            updated.title = String(first.content.prefix(20))
        }
        conversations[idx] = updated
        save()
    }

    func delete(_ id: UUID) {
        conversations.removeAll { $0.id == id }
        save()
    }

    func toggleArchive(_ id: UUID) {
        guard let idx = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[idx].isArchived.toggle()
        conversations[idx].updatedAt = Date()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(conversations) {
            defaults.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Conversation].self, from: data)
        else { return }
        conversations = decoded
    }
}

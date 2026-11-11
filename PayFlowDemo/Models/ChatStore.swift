import Foundation
import SwiftUI
import Combine

/// Persists the editable home list to a local JSON file.
/// Nothing here touches the network, so the demo works fully offline.
final class ChatStore: ObservableObject {
    @Published var items: [ChatItem] = [] {
        didSet { persist() }
    }

    private let storageURL: URL
    private var isLoaded = false

    init(fileName: String = "chats.json") {
        let fileManager = FileManager.default
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        let folder = base.appendingPathComponent("PayFlowDemo", isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        storageURL = folder.appendingPathComponent(fileName)
        load()
        isLoaded = true
    }

    // MARK: - Mutations

    func add(_ item: ChatItem) {
        items.append(item)
    }

    func update(_ item: ChatItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let previous = items[index]
        if previous.avatarImageName != item.avatarImageName {
            AvatarStore.delete(previous.avatarImageName)
        }
        items[index] = item
    }

    func delete(_ id: UUID) {
        if let item = items.first(where: { $0.id == id }) {
            AvatarStore.delete(item.avatarImageName)
        }
        items.removeAll { $0.id == id }
    }

    func resetToSamples() {
        items = ChatItem.seeds
    }

    // MARK: - Persistence

    private func load() {
        guard
            let data = try? Data(contentsOf: storageURL),
            let decoded = try? JSONDecoder().decode([ChatItem].self, from: data)
        else {
            items = ChatItem.seeds
            return
        }
        items = decoded
    }

    private func persist() {
        guard isLoaded else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

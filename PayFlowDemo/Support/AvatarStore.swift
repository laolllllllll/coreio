import UIKit

/// Stores photo avatars as small JPEGs inside the app sandbox.
enum AvatarStore {
    private static let cache = NSCache<NSString, UIImage>()

    static let folder: URL = {
        let fileManager = FileManager.default
        let base = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent("PayFlowDemo/Avatars", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    /// Downsizes to 320pt and returns the stored file name.
    static func save(imageData: Data) -> String? {
        guard let image = UIImage(data: imageData) else { return nil }
        let side: CGFloat = 320
        let longest = max(image.size.width, image.size.height, 1)
        let scale = min(side / longest, 1)
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let data = resized.jpegData(compressionQuality: 0.85) else { return nil }
        let name = UUID().uuidString + ".jpg"
        do {
            try data.write(to: folder.appendingPathComponent(name), options: .atomic)
        } catch {
            return nil
        }
        cache.setObject(resized, forKey: name as NSString)
        return name
    }

    static func load(_ name: String?) -> UIImage? {
        guard let name, !name.isEmpty else { return nil }
        if let cached = cache.object(forKey: name as NSString) {
            return cached
        }
        guard let image = UIImage(contentsOfFile: folder.appendingPathComponent(name).path) else {
            return nil
        }
        cache.setObject(image, forKey: name as NSString)
        return image
    }

    static func delete(_ name: String?) {
        guard let name, !name.isEmpty else { return }
        cache.removeObject(forKey: name as NSString)
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(name))
    }
}

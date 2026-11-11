import Foundation

/// A single row on the demo home screen. Every field is user editable.
struct ChatItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var avatarEmoji: String
    var avatarColorHex: String
    /// File name inside the app's avatar folder. When set it wins over the emoji.
    var avatarImageName: String? = nil
    var lastMessage: String
    var timeText: String
    var isMuted: Bool = false

    static let seeds: [ChatItem] = [
        ChatItem(
            name: "阿杰",
            avatarEmoji: "🧑‍💻",
            avatarColorHex: "#34C759",
            lastMessage: "晚点把演示视频发你",
            timeText: "00:27"
        ),
        ChatItem(
            name: "演示小店",
            avatarEmoji: "🛍️",
            avatarColorHex: "#FF9500",
            lastMessage: "扫码体验一次模拟支付",
            timeText: "昨天"
        ),
        ChatItem(
            name: "小林",
            avatarEmoji: "🌱",
            avatarColorHex: "#0A84FF",
            lastMessage: "收到，谢谢！",
            timeText: "周一",
            isMuted: true
        )
    ]
}

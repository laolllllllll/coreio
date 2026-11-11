import SwiftUI

struct ChatRow: View {
    let item: ChatItem

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(emoji: item.avatarEmoji, colorHex: item.avatarColorHex, imageName: item.avatarImageName, size: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(item.lastMessage.isEmpty ? "（没有消息）" : item.lastMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text(item.timeText)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                if item.isMuted {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

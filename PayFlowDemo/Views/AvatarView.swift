import SwiftUI

struct AvatarView: View {
    let emoji: String
    let colorHex: String
    var imageName: String? = nil
    var size: CGFloat = 52

    private var photo: UIImage? {
        AvatarStore.load(imageName)
    }

    var body: some View {
        Group {
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(hex: colorHex)
                    Text(emoji.isEmpty ? "🙂" : emoji)
                        .font(.system(size: size * 0.48))
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .padding(size * 0.08)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.24, style: .continuous))
        .accessibilityHidden(true)
    }
}

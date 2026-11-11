import SwiftUI

struct DemoBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 12, weight: .semibold))
            Text("演示模式：本应用不会发起真实支付，也不会联网")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color(red: 0.42, green: 0.33, blue: 0.10))
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(DemoTheme.warnBackground)
        .overlay(alignment: .bottom) {
            Rectangle().fill(DemoTheme.warnBorder.opacity(0.4)).frame(height: 0.5)
        }
    }
}

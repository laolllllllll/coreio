import SwiftUI

struct SuccessCard: View {
    let target: PayTarget
    let amountText: String
    var onDone: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            DemoWatermark()

            VStack(spacing: 0) {
                HStack {
                    Text("演示收据")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DemoTheme.accentDeep)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(DemoTheme.accent.opacity(0.12)))

                    Spacer()

                    Text("非真实交易")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(Color(red: 0.78, green: 0.16, blue: 0.16))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .overlay(
                            Capsule().stroke(Color(red: 0.78, green: 0.16, blue: 0.16).opacity(0.55), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)

                Spacer(minLength: 16)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(DemoTheme.accent)

                Text("模拟支付成功")
                    .font(.system(size: 25, weight: .bold))
                    .padding(.top, 12)

                Text("仅用于界面演示，未发生任何真实扣款")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                VStack(spacing: 6) {
                    AvatarView(emoji: "🧾", colorHex: "#34C759", size: 54)
                    Text(target.name)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                    Text("演示对象")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 26)

                Text("¥ \(amountText)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .padding(.top, 16)

                Text(target.source == .qr ? "来源：二维码文本（仅解析）" : "来源：演示会话")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Spacer()

                Button {
                    onDone()
                } label: {
                    Text("完成")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(DemoTheme.accent)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)

                Text("返回首页后不会产生任何账单记录")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DemoWatermark: View {
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 40) {
                ForEach(0..<5, id: \.self) { _ in
                    Text("DEMO · 非真实交易")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(Color.black.opacity(0.055))
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geo.size.width * 1.5, height: geo.size.height * 1.5)
            .rotationEffect(.degrees(-24))
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .allowsHitTesting(false)
        .clipped()
    }
}

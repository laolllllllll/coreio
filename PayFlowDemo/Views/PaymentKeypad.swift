import SwiftUI

struct PaymentKeypad: View {
    let canPay: Bool
    var onKey: (String) -> Void
    var onPay: () -> Void

    private let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], [".", "0", "⌫"]]
    private let keyHeight: CGFloat = 56
    private let spacing: CGFloat = 8

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: spacing) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { key in
                            keyButton(key)
                        }
                    }
                }
            }

            Button(action: onPay) {
                VStack(spacing: 3) {
                    Text("模拟支付")
                        .font(.system(size: 17, weight: .semibold))
                    Text("非真实交易")
                        .font(.system(size: 9, weight: .medium))
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canPay ? DemoTheme.accent : DemoTheme.payButtonDisabled)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canPay)
            .frame(width: 96)
            .frame(height: keyHeight * 4 + spacing * 3)
        }
    }

    private func keyButton(_ key: String) -> some View {
        Button {
            onKey(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20, weight: .medium))
                } else {
                    Text(key)
                        .font(.system(size: 24, weight: .regular))
                }
            }
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: keyHeight)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(white: 0.97))
            )
        }
        .buttonStyle(.plain)
    }
}

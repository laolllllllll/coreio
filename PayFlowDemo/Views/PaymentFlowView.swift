import SwiftUI
import UIKit

struct PaymentFlowView: View {
    enum Phase: Equatable {
        case enter
        case success
    }

    let target: PayTarget

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @State private var phase: Phase = .enter

    init(target: PayTarget) {
        self.target = target
        _amountText = State(initialValue: target.amountText ?? "")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if phase == .enter { dismiss() }
                    }

                if phase == .enter {
                    card
                        .frame(maxHeight: geo.size.height - 44)
                        .transition(.move(edge: .bottom))
                } else {
                    SuccessCard(target: target, amountText: displayAmount) {
                        dismiss()
                    }
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 38, height: 5)
                .padding(.top, 8)

            header

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    payeeBlock
                    amountBlock
                    noticeCard
                    methodRow
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 6)
            }

            PaymentKeypad(canPay: canPay, onKey: handleKey, onPay: pay)
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(
                cornerRadii: .init(topLeading: 22, bottomLeading: 0, bottomTrailing: 0, topTrailing: 22),
                style: .continuous
            )
            .fill(Color.white)
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("模拟支付")
                .font(.system(size: 17, weight: .semibold))

            Spacer()

            Text("演示")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(Color(red: 0.72, green: 0.42, blue: 0.05))
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Capsule().fill(DemoTheme.warnBackground))
                .overlay(Capsule().stroke(DemoTheme.warnBorder.opacity(0.6), lineWidth: 0.8))
                .frame(width: 44)
        }
        .padding(.horizontal, 8)
        .padding(.top, 2)
    }

    private var payeeBlock: some View {
        HStack(spacing: 12) {
            AvatarView(emoji: "🧾", colorHex: "#34C759", size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("演示对象")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(target.name)
                    .font(.system(size: 20, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(target.source == .qr ? "名称解析自二维码文本" : "名称来自演示会话")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
    }

    private var amountBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("付款金额（演示）")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("¥")
                    .font(.system(size: 28, weight: .medium))
                Text(displayAmount)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
            }
            .foregroundStyle(amountText.isEmpty ? Color.secondary.opacity(0.55) : Color.primary)

            Rectangle()
                .fill(Color.black.opacity(0.07))
                .frame(height: 0.8)
                .padding(.top, 2)
        }
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("这是演示页面，不会扣款")
                    .font(.system(size: 13, weight: .semibold))
            }

            Text("本应用不联网、不接入任何支付 SDK；二维码只作为纯文本读取。")
                .font(.system(size: 12))
                .fixedSize(horizontal: false, vertical: true)

            if target.source == .qr {
                Text("内容：\(target.rawPreview)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .foregroundStyle(Color(red: 0.42, green: 0.33, blue: 0.10))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DemoTheme.warnBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DemoTheme.warnBorder.opacity(0.45), lineWidth: 0.8)
        )
    }

    private var methodRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 17))
                .foregroundStyle(DemoTheme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(DemoTheme.accent.opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text("演示钱包（模拟）")
                    .font(.system(size: 14, weight: .medium))
                Text("本地模拟，不涉及任何真实资金")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(DemoTheme.accent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: 0.97))
        )
    }

    // MARK: - Amount

    private var amountValue: Double {
        Double(amountText) ?? 0
    }

    private var canPay: Bool {
        amountValue > 0 && amountValue <= 99999
    }

    private var displayAmount: String {
        guard !amountText.isEmpty else { return "0.00" }
        let parts = amountText.split(separator: ".", omittingEmptySubsequences: false)
        let integer = parts.first.map(String.init) ?? "0"
        let fraction = parts.count > 1 ? String(parts[1]) : ""
        let padded = String((fraction + "00").prefix(2))
        return "\(integer.isEmpty ? "0" : integer).\(padded)"
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if !amountText.isEmpty {
                amountText.removeLast()
            }
        case ".":
            if amountText.isEmpty {
                amountText = "0."
            } else if !amountText.contains(".") {
                amountText += "."
            }
        default:
            if let dotIndex = amountText.firstIndex(of: ".") {
                let decimals = amountText.distance(from: dotIndex, to: amountText.endIndex) - 1
                if decimals >= 2 { return }
            }
            let integerDigits = amountText.split(separator: ".").first?.count ?? 0
            if integerDigits >= 6 { return }
            if amountText == "0" {
                amountText = key
            } else {
                amountText += key
            }
        }
    }

    private func pay() {
        guard canPay else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .success
        }
    }
}

import SwiftUI
import UIKit

/// Shows a QR code that this demo understands, so the scan flow can be tested
/// with a second device (or a printed code).
struct DemoQRCodeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = "演示小店"
    @State private var amount = "0.01"
    @State private var copied = false

    private var payload: String {
        let safeName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let safeAmount = amount.isEmpty ? "0.01" : amount
        return "paydemo://pay?name=\(safeName)&amount=\(safeAmount)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("演示二维码")
                            .font(.system(size: 20, weight: .bold))
                        Text("用另一台设备打开本应用扫码，或把它打印出来")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    Group {
                        if let image = QRCodeImage.make(from: payload, size: 300) {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 240, height: 240)
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.08)))
                        } else {
                            Text("二维码生成失败")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(width: 240, height: 240)
                        }
                    }

                    Text(payload)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)

                    VStack(spacing: 10) {
                        TextField("演示对象名称", text: $name)
                            .textFieldStyle(.roundedBorder)
                        TextField("金额，例如 0.01", text: $amount)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = payload
                            copied = true
                        } label: {
                            Label(copied ? "已复制" : "复制内容", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(RoundedRectangle(cornerRadius: 11).fill(Color(white: 0.94)))
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("关闭")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(RoundedRectangle(cornerRadius: 11).fill(DemoTheme.accent))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("提示：模拟器没有摄像头，可在扫码页点“手动输入内容”粘贴上面的地址。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
                .padding(20)
            }
            .background(Color(white: 0.97))
            .navigationTitle("生成演示二维码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

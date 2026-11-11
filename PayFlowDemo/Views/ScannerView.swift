import SwiftUI
import AVFoundation
import UIKit

/// Camera scan screen. Reads QR text only — no payment semantics at all.
struct ScannerView: View {
    var onCancel: () -> Void
    var onCode: (String) -> Void

    @StateObject private var scanner = QRScannerController()
    @State private var torchOn = false
    @State private var manualText = ""
    @State private var showManualInput = false
    @State private var delivered = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if scanner.state == .running {
                CameraPreview(session: scanner.session)
                    .ignoresSafeArea()
            } else if scanner.state == .denied || scanner.state == .unavailable {
                unavailableView
            }

            GeometryReader { geo in
                let side = min(min(geo.size.width, geo.size.height) * 0.62, 300)
                let hole = CGRect(
                    x: (geo.size.width - side) / 2,
                    y: (geo.size.height - side) / 2 - 30,
                    width: side,
                    height: side
                )
                ZStack {
                    Path { path in
                        path.addRect(CGRect(origin: .zero, size: geo.size))
                        path.addRect(hole)
                    }
                    .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))

                    ScanBrackets(rect: hole)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                Spacer()
                Text("仅读取二维码文本 · 不会发起任何真实支付")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                Spacer().frame(height: 24)
                bottomBar
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .onAppear { scanner.start() }
        .onDisappear { scanner.stop() }
        .onChange(of: scanner.detectedCode) { code in
            handle(code)
        }
        .alert("手动输入二维码内容", isPresented: $showManualInput) {
            TextField("例如 张三 或 paydemo://pay?name=演示小店", text: $manualText)
            Button("用这段内容演示") { handle(manualText) }
            Button("取消", role: .cancel) { manualText = "" }
        } message: {
            Text("模拟器没有摄像头时，用它来走通后续流程。短文本会被当作演示对象名称。")
        }
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack {
            Button {
                scanner.stop()
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            Spacer()
            VStack(spacing: 2) {
                Text("扫一扫（演示）")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("二维码只会被当作纯文本解析")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 14) {
            Button {
                torchOn.toggle()
                scanner.setTorch(torchOn)
            } label: {
                Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(torchOn ? Color.black : .white)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(torchOn ? Color.yellow : Color.white.opacity(0.16)))
            }

            Button {
                manualText = ""
                showManualInput = true
            } label: {
                Label("手动输入内容", systemImage: "keyboard")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 52)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
            }

            Spacer(minLength: 0)
        }
    }

    private var unavailableView: some View {
        VStack(spacing: 14) {
            Image(systemName: scanner.state == .denied ? "camera.badge.ellipsis" : "camera.metering.unknown")
                .font(.system(size: 46, weight: .light))
                .foregroundStyle(.white.opacity(0.8))
            Text(scanner.state == .denied ? "没有相机权限" : "相机不可用")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
            Text(scanner.failureMessage ?? "请在系统设置中允许本应用访问相机，或直接手动输入内容继续演示。")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            if scanner.state == .denied {
                Button("打开系统设置") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 18)
                .frame(height: 42)
                .background(Capsule().fill(Color.white))
            }
            Button("手动输入内容") {
                manualText = ""
                showManualInput = true
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
        }
    }

    // MARK: - Handling

    private func handle(_ raw: String?) {
        guard !delivered, let raw else { return }
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        delivered = true
        scanner.stop()
        onCode(text)
    }
}

private struct ScanBrackets: View {
    let rect: CGRect

    var body: some View {
        let length: CGFloat = 26
        let lineWidth: CGFloat = 3
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))

            path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))

            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))

            path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        }
        .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}

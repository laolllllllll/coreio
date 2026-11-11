import AVFoundation
import Combine
import UIKit

/// Thin AVFoundation wrapper for QR scanning.
/// The scanner only ever produces the raw text of a code.
final class QRScannerController: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case starting
        case running
        case denied
        case unavailable
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var detectedCode: String?
    @Published private(set) var failureMessage: String?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "com.example.paydemo.camera.session")
    private var isConfigured = false
    private var shouldRun = false
    private var videoDevice: AVCaptureDevice?

    // MARK: - Lifecycle

    func start() {
        shouldRun = true
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            state = .starting
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                DispatchQueue.main.async {
                    if granted {
                        self.configureAndRun()
                    } else {
                        self.state = .denied
                    }
                }
            }
        default:
            state = .denied
        }
    }

    func pause() {
        shouldRun = false
        let captureSession = session
        sessionQueue.async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }

    func stop() {
        pause()
    }

    func setTorch(_ isOn: Bool) {
        guard let device = videoDevice, device.hasTorch, device.isTorchAvailable else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Torch is a nicety; ignore failures.
        }
    }

    // MARK: - Configuration

    private func configureAndRun() {
        state = .starting
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                do {
                    try self.configureSession()
                    self.isConfigured = true
                } catch {
                    DispatchQueue.main.async {
                        self.state = .unavailable
                        self.failureMessage = (error as? ScannerError)?.message ?? error.localizedDescription
                    }
                    return
                }
            }
            guard self.shouldRun else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
            DispatchQueue.main.async {
                if self.shouldRun {
                    self.state = .running
                } else {
                    self.state = .idle
                }
            }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw ScannerError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw ScannerError.configurationFailed }
        session.addInput(input)
        videoDevice = device

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { throw ScannerError.configurationFailed }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        // `.qr` is supported by every camera-capable iOS device; querying
        // availableMetadataObjectTypes before commitConfiguration() is unreliable.
        output.metadataObjectTypes = [.qr]
    }

    deinit {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard detectedCode == nil,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        detectedCode = value
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let captureSession = session
        shouldRun = false
        sessionQueue.async {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }
}

enum ScannerError: Error {
    case noCamera
    case configurationFailed
    case noQRSupport

    var message: String {
        switch self {
        case .noCamera:
            return "当前设备没有可用的后置摄像头（模拟器不支持相机）。"
        case .configurationFailed:
            return "相机初始化失败，请重启应用后重试。"
        case .noQRSupport:
            return "当前相机不支持二维码识别。"
        }
    }
}

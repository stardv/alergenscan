import AVFoundation
import CoreImage
import SwiftUI

/// Owns the capture session and hands back a still frame on demand.
@MainActor
final class CameraController: NSObject, ObservableObject {

    enum Access { case unknown, granted, denied }

    @Published private(set) var access: Access = .unknown

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var captureContinuation: CheckedContinuation<CGImage?, Never>?
    private let ciContext = CIContext()

    func start() async {
        guard await requestAccess() else {
            access = .denied
            return
        }
        access = .granted
        configureIfNeeded()

        let session = self.session
        await Task.detached { if !session.isRunning { session.startRunning() } }.value
    }

    func stop() {
        let session = self.session
        Task.detached { if session.isRunning { session.stopRunning() } }
    }

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .video)
        default: return false
        }
    }

    private func configureIfNeeded() {
        guard session.inputs.isEmpty else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video,
                                                position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)

            // Ingredient lists are small print, often read close up.
            try? device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            device.unlockForConfiguration()
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()
    }

    /// Capture one frame for Vision to work on.
    func capture() async -> CGImage? {
        guard access == .granted, session.isRunning else { return nil }

        return await withCheckedContinuation { continuation in
            self.captureContinuation = continuation
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        let cgImage: CGImage? = {
            guard error == nil,
                  let data = photo.fileDataRepresentation(),
                  let source = CGImageSourceCreateWithData(data as CFData, nil) else {
                return nil
            }
            return CGImageSourceCreateImageAtIndex(source, 0, nil)
        }()

        Task { @MainActor in
            self.captureContinuation?.resume(returning: cgImage)
            self.captureContinuation = nil
        }
    }
}

/// Live viewfinder.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}

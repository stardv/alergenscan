import AVFoundation
import SwiftUI
import UIKit
import Vision

/// Owns the capture session and hands back a still frame on demand.
@MainActor
final class CameraController: NSObject, ObservableObject {

    enum Access { case unknown, granted, denied }

    /// Whether what is currently in front of the lens is worth scanning.
    ///
    /// This gates the Scan button. It is a usability judgement, not a safety
    /// one — the scan itself still re-reads the frame properly and still
    /// answers "Couldn't check this" when the read comes back empty.
    enum Readiness: Equatable {
        case waiting
        case focusing
        case barcode
        case ingredients

        var isReady: Bool {
            switch self {
            case .barcode, .ingredients: return true
            case .waiting, .focusing:    return false
            }
        }

        var message: String {
            switch self {
            case .waiting:     return "Point at the ingredients list, or the barcode."
            case .focusing:    return "Hold still while it focuses…"
            case .barcode:     return "Barcode in view."
            case .ingredients: return "Ingredients in view."
            }
        }
    }

    @Published private(set) var access: Access = .unknown

    /// True once the preview has been unreadable long enough that refusing to
    /// scan at all would just be in the way. The button comes back as "Scan
    /// anyway" rather than staying dead — a bad read is handled safely
    /// downstream, but a button that never enables is a dead end.
    @Published private(set) var allowsOverride = false

    @Published private var content: Readiness = .waiting
    @Published private var isFocusing = false

    var readiness: Readiness { isFocusing ? .focusing : content }

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let analysisQueue = DispatchQueue(label: "alergenscan.frame-analysis")
    private var analyzer: FrameAnalyzer?
    private var focusObservation: NSKeyValueObservation?
    private var overrideTask: Task<Void, Never>?
    private var captureContinuation: CheckedContinuation<CGImage?, Never>?

    func start() async {
        guard await requestAccess() else {
            access = .denied
            return
        }
        access = .granted
        configureIfNeeded()
        scheduleOverride()

        let session = self.session
        await Task.detached { if !session.isRunning { session.startRunning() } }.value
    }

    func stop() {
        overrideTask?.cancel()
        content = .waiting
        allowsOverride = false

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

            // Nothing read mid-focus is trustworthy, so the button goes dark
            // while the lens hunts.
            focusObservation = device.observe(\.isAdjustingFocus, options: [.new]) {
                [weak self] _, change in
                let adjusting = change.newValue ?? false
                Task { @MainActor in self?.isFocusing = adjusting }
            }
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        let analyzer = FrameAnalyzer { [weak self] readiness in
            Task { @MainActor in self?.apply(readiness) }
        }
        self.analyzer = analyzer
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(analyzer, queue: analysisQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    private func apply(_ readiness: Readiness) {
        content = readiness
        if readiness.isReady {
            overrideTask?.cancel()
            allowsOverride = false
        } else if !allowsOverride {
            scheduleOverride()
        }
    }

    /// Arms the "Scan anyway" escape hatch, restarting the countdown each time
    /// the preview goes back to being unreadable.
    private func scheduleOverride() {
        overrideTask?.cancel()
        overrideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            guard !Task.isCancelled else { return }
            self?.allowsOverride = true
        }
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

/// Samples the live preview a few times a second and decides whether there is
/// anything worth scanning in front of the lens.
///
/// Deliberately off the main actor: this runs Vision on every sampled frame,
/// which has no business on the thread driving the viewfinder.
private final class FrameAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    /// Enough lines, and enough characters, to look like an ingredients list
    /// rather than a brand name caught in passing.
    private let minimumLines = 4
    private let minimumCharacters = 40
    private let interval: TimeInterval = 0.4

    private var lastRun = Date.distantPast
    private let onResult: @Sendable (CameraController.Readiness) -> Void

    init(onResult: @escaping @Sendable (CameraController.Readiness) -> Void) {
        self.onResult = onResult
    }

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastRun) >= interval,
              let pixels = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastRun = now
        onResult(readiness(of: pixels))
    }

    private func readiness(of pixels: CVPixelBuffer) -> CameraController.Readiness {
        // The back camera hands frames over a quarter turn from how the phone
        // is being held in portrait.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixels, orientation: .right)

        let barcodes = VNDetectBarcodesRequest()
        barcodes.symbologies = [.ean13, .ean8, .upce]

        let text = VNRecognizeTextRequest()
        // Fast is the right trade here: this only decides whether the button
        // lights up. The scan itself re-reads the frame with .accurate.
        text.recognitionLevel = .fast
        text.usesLanguageCorrection = false
        text.minimumTextHeight = 0.012

        try? handler.perform([barcodes, text])

        let found = (barcodes.results ?? []).contains {
            !($0.payloadStringValue ?? "").isEmpty
        }
        if found { return .barcode }

        let lines = (text.results ?? []).compactMap { $0.topCandidates(1).first }
            .filter { $0.confidence > 0.3 }
            .map(\.string)

        let characters = lines.reduce(0) { $0 + $1.count }
        if lines.count >= minimumLines && characters >= minimumCharacters {
            return .ingredients
        }

        return .waiting
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

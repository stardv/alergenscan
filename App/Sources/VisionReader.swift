import Foundation
import Vision
import CoreGraphics

/// What a single captured frame yielded.
struct FrameReading {
    /// All text Vision could recognise, joined into one blob. Empty when the
    /// label was unreadable.
    let text: String
    /// First product barcode found in the frame, if any.
    let barcode: String?

    var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
}

/// Reads ingredient text and barcodes out of one image.
///
/// Both come from the same captured frame, which is why the app only needs a
/// single "Scan" action: you point at the package, and whichever of the two is
/// present gets used.
enum VisionReader {

    /// Vision's `perform` is synchronous and slow enough to block a frame, so
    /// the whole read happens off the main actor. Deliberately *not* built on
    /// continuations: a request whose completion handler fires **and** whose
    /// `perform` throws would resume the same continuation twice and trap.
    static func read(_ image: CGImage) async -> FrameReading {
        await Task.detached(priority: .userInitiated) {
            FrameReading(text: recognizeText(in: image),
                         barcode: detectBarcode(in: image))
        }.value
    }

    private static func recognizeText(in image: CGImage) -> String {
        let request = VNRecognizeTextRequest()

        // Accurate beats fast here. A misread ingredient is a wrong answer,
        // and the user is holding the packet still anyway.
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en-US", "fr-FR", "de-DE", "es-ES", "it-IT"]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        guard (try? handler.perform([request])) != nil else { return "" }

        let observations = request.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return lines.joined(separator: "\n")
    }

    private static func detectBarcode(in image: CGImage) -> String? {
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.ean13, .ean8, .upce]

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        guard (try? handler.perform([request])) != nil else { return nil }

        let observations = request.results ?? []
        let productCode = observations.first { observation in
            observation.symbology == .ean13
                || observation.symbology == .ean8
                || observation.symbology == .upce
        }
        return productCode?.payloadStringValue
    }
}

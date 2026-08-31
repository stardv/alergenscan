import Foundation
import Vision
import CoreImage

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

    static func read(_ image: CGImage) async -> FrameReading {
        async let text = recognizeText(in: image)
        async let barcode = detectBarcode(in: image)
        return FrameReading(text: await text, barcode: await barcode)
    }

    private static func recognizeText(in image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            // Accurate beats fast here. A misread ingredient is a wrong answer,
            // and the user is holding the packet still anyway.
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US", "fr-FR", "de-DE", "es-ES", "it-IT"]

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    private static func detectBarcode(in image: CGImage) async -> String? {
        await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, _ in
                let observations = request.results as? [VNBarcodeObservation] ?? []
                let productCode = observations.first { observation in
                    observation.symbology == .ean13
                        || observation.symbology == .ean8
                        || observation.symbology == .upce
                }
                continuation.resume(returning: productCode?.payloadStringValue)
            }
            request.symbologies = [.ean13, .ean8, .upce]

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

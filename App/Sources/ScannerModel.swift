import Foundation
import AllergenEngine

/// Drives one scan: read the label, look up the barcode, cross-reference, answer.
///
/// Order matters and follows the safest reading. The **label is primary**: it
/// is the packet in your hand and cannot be out of date. The **database is the
/// fallback**, used when the label can't be read and as a second opinion when
/// it can. Their findings are unioned, so a flag from either one survives.
@MainActor
final class ScannerModel: ObservableObject {

    enum State: Equatable {
        case idle
        case working(String)
        case done(ScanResult, OFFProduct?)
        case failed(String)

        static func == (a: State, b: State) -> Bool {
            switch (a, b) {
            case (.idle, .idle): return true
            case let (.working(x), .working(y)): return x == y
            case (.done, .done): return true
            case let (.failed(x), .failed(y)): return x == y
            default: return false
            }
        }
    }

    @Published private(set) var state: State = .idle

    private let engine = AllergenEngine()
    private let off = OpenFoodFactsClient()

    func reset() { state = .idle }

    func scan(using camera: CameraController, profile: Set<Allergen>) async {
        guard !profile.isEmpty else {
            state = .failed("Choose which allergens to watch for first.")
            return
        }

        state = .working("Reading the label…")

        guard let image = await camera.capture() else {
            state = .failed("Couldn't take a picture. Check camera permissions.")
            return
        }

        let frame = await VisionReader.read(image)

        // ── Source 1: the label itself ───────────────────────────────────
        let labelReading = SourceReading(
            source: .label,
            findings: frame.hasText ? engine.analyze(labelText: frame.text) : nil
        )

        // ── Source 2: Open Food Facts, by barcode ────────────────────────
        var product: OFFProduct?
        var databaseReading = SourceReading(source: .database, findings: nil)

        if let barcode = frame.barcode {
            state = .working("Checking Open Food Facts…")
            do {
                let fetched = try await off.fetch(barcode: barcode)
                product = fetched
                databaseReading = SourceReading(source: .database,
                                                findings: engine.analyze(product: fetched))
            } catch {
                // A database miss is not a failure — the label may still have
                // told us everything we need.
                databaseReading = SourceReading(source: .database, findings: nil)
            }
        }

        let result = engine.combine(
            readings: [labelReading, databaseReading],
            profile: profile,
            labelText: frame.hasText ? frame.text : nil,
            databaseText: product?.ingredientsText,
            productName: product?.displayName.isEmpty == false ? product?.displayName : nil
        )
        state = .done(result, product)
    }

    /// Look a product up by barcode alone, with no photo — used when the user
    /// types a barcode in by hand.
    func lookUp(barcode: String, profile: Set<Allergen>) async {
        guard !profile.isEmpty else {
            state = .failed("Choose which allergens to watch for first.")
            return
        }

        state = .working("Checking Open Food Facts…")
        do {
            let fetched = try await off.fetch(barcode: barcode)
            let reading = SourceReading(source: .database,
                                        findings: engine.analyze(product: fetched))
            let result = engine.combine(
                readings: [reading],
                profile: profile,
                databaseText: fetched.ingredientsText,
                productName: fetched.displayName.isEmpty ? nil : fetched.displayName
            )
            state = .done(result, fetched)
        } catch {
            state = .failed((error as? OFFError)?.errorDescription
                            ?? "Couldn't look that barcode up.")
        }
    }
}

import Foundation

/// Where a piece of evidence came from.
public enum EvidenceSource: String, Codable, Sendable, CaseIterable {
    /// Read off the physical package by the camera. Freshest possible source:
    /// it is the label currently in your hand.
    case label
    /// Looked up in Open Food Facts by barcode. May lag a reformulation.
    case database
}

/// The verdict for one allergen. Deliberately only three states — the whole
/// point of this app is that a result is never ambiguous.
public enum AllergenStatus: Int, Codable, Sendable, Comparable {
    /// Not found in anything we read. NOT the same as "safe" — we may simply
    /// not have been able to read it.
    case notDetected = 0
    /// Found only in a precautionary statement ("may contain", "traces of").
    case mayContain = 1
    /// Named in the ingredients.
    case contains = 2

    public static func < (a: AllergenStatus, b: AllergenStatus) -> Bool {
        a.rawValue < b.rawValue
    }
}

/// One allergen's outcome, with the words that produced it.
public struct AllergenFinding: Identifiable, Codable, Sendable {
    public let allergen: Allergen
    public let status: AllergenStatus
    /// The exact phrases matched, so the result can always be justified to the
    /// user. "Milk — because we found: whey, butter."
    public let evidence: [String]
    /// Which sources contributed. Empty when `status == .notDetected`.
    public let sources: [EvidenceSource]

    public var id: String { allergen.rawValue }

    public init(allergen: Allergen,
                status: AllergenStatus,
                evidence: [String],
                sources: [EvidenceSource]) {
        self.allergen = allergen
        self.status = status
        self.evidence = evidence
        self.sources = sources
    }
}

/// What one source (a label photo, or a database record) yielded.
public struct SourceReading: Sendable {
    public let source: EvidenceSource
    /// nil when the source produced nothing at all — no text recognised, or
    /// the barcode was not in the database. Distinct from "read it, found
    /// nothing", which is an empty dictionary.
    public let findings: [Allergen: (AllergenStatus, [String])]?

    public init(source: EvidenceSource,
                findings: [Allergen: (AllergenStatus, [String])]?) {
        self.source = source
        self.findings = findings
    }
}

/// Raw text from one evidence source, for display on the result screen.
public struct IngredientsText: Sendable {
    public let source: EvidenceSource
    public let text: String

    public init(source: EvidenceSource, text: String) {
        self.source = source
        self.text = text
    }
}

/// The combined answer shown to the user.
public struct ScanResult: Sendable {
    /// One entry per allergen in the user's profile, worst-first.
    public let findings: [AllergenFinding]
    /// Sources that actually returned something.
    public let sourcesConsulted: [EvidenceSource]
    /// True when no source could be read at all. The UI must say "could not
    /// check" rather than showing a reassuring all-clear.
    public let isInconclusive: Bool
    /// Raw ingredients text from each source, for display.
    public let ingredientsTexts: [IngredientsText]
    /// Product name from barcode lookup or best-guess from label.
    public let productName: String?
    /// How confident we are that the scanned text is actually a label.
    public let labelConfidence: Double?

    public init(findings: [AllergenFinding],
                sourcesConsulted: [EvidenceSource],
                isInconclusive: Bool,
                ingredientsTexts: [IngredientsText] = [],
                productName: String? = nil,
                labelConfidence: Double? = nil) {
        self.findings = findings
        self.sourcesConsulted = sourcesConsulted
        self.isInconclusive = isInconclusive
        self.ingredientsTexts = ingredientsTexts
        self.productName = productName
        self.labelConfidence = labelConfidence
    }

    /// Anything the user needs to react to.
    public var flagged: [AllergenFinding] {
        findings.filter { $0.status != .notDetected }
    }

    /// The single headline state for the result screen.
    public var headline: Headline {
        if isInconclusive { return .couldNotCheck }
        if findings.contains(where: { $0.status == .contains }) { return .contains }
        if findings.contains(where: { $0.status == .mayContain }) { return .mayContain }
        return .noneDetected
    }

    public enum Headline: Sendable {
        case contains
        case mayContain
        case noneDetected
        case couldNotCheck
    }
}

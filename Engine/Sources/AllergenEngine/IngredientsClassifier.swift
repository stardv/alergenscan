import Foundation

/// Deterministic classifier that scores whether OCR text actually looks like
/// an ingredients declaration on a food label.
///
/// This exists to make the scan result MORE cautious, never less. When the
/// text doesn't look like ingredients (e.g. a novel page, a poster, a menu),
/// the result should say "Couldn't check this" rather than "None of your
/// allergens found". If allergens ARE found in non-label text, they are STILL
/// FLAGGED — the classifier can turn green -> inconclusive, never red/amber
/// -> green.
///
/// Multi-signal scoring:
/// - "ingredients" keyword in 5+ languages
/// - "contains" / "may contain" markers
/// - Comma density (ingredient lists are comma-heavy)
/// - Allergen dictionary token overlap
/// - E-number codes (E100–E1599)
/// - Percentage values (common in EU labels)
public enum IngredientsClassifier {

    /// The result of classifying a piece of text.
    public struct Classification: Sendable {
        /// A score from 0.0 (definitely not a label) to 1.0 (definitely a label).
        public let score: Double
        /// True when the score is high enough that we trust this is an
        /// ingredients declaration.
        public var looksLikeLabel: Bool { score >= Self.threshold }

        /// The threshold above which text is considered a label.
        static let threshold: Double = 0.3
    }

    // MARK: - Ingredients keywords (multi-language)

    /// "Ingredients" in the major EU label languages, normalized (no accents).
    private static let ingredientsKeywords: [String] = [
        "ingredients",      // English
        "ingredient",       // English singular
        "ingredientes",     // Spanish / Portuguese
        "ingredienti",      // Italian
        "ingredienten",     // Dutch
        "zutaten",          // German
        "sammensetning",    // Norwegian
        "sammansattning",   // Swedish
        "ainekset",         // Finnish
        "skladniki",        // Polish
        "slozeni",          // Czech
        "zlozenie",         // Slovak
        "osszetevok",       // Hungarian
        "ingrediente",      // Romanian
        "sastojci",         // Croatian / Serbian
        "sudetis",          // Lithuanian
        "sastav",           // Bosnian
        "koostumus",        // Estonian
    ]

    /// "Ingrédients" needs special handling because TextNormalizer folds
    /// accents, so we match the folded form above. But we also want to catch
    /// "INGRÉDIENTS:" as a header via prefix matching on the raw text.
    private static let ingredientsHeaderPrefixes: [String] = [
        "ingredients",
        "ingredientes",
        "ingredienti",
        "ingredienten",
        "zutaten",
    ]

    // MARK: - Contains / may contain markers

    private static let containsMarkers: [[String]] = [
        ["contains"],
        ["may", "contain"],
        ["may", "contains"],
        ["traces", "of"],
        ["trace", "of"],
        ["contient"],       // French
        ["peut", "contenir"], // French
        ["enthalt"],        // German (enthält -> enthalt after folding)
        ["kann", "enthalten"], // German
        ["contiene"],       // Spanish / Italian
        ["puede", "contener"], // Spanish
        ["puo", "contenere"],  // Italian
    ]

    // MARK: - E-number pattern

    /// Matches E-numbers like E220, E471, E1520.
    private static let eNumberPattern = try! NSRegularExpression(
        pattern: "\\be[0-9]{3,4}\\b",
        options: .caseInsensitive
    )

    /// Matches percentages like "13%", "7.4%", "6,6%".
    private static let percentagePattern = try! NSRegularExpression(
        pattern: "[0-9]+[.,]?[0-9]*\\s*%",
        options: []
    )

    // MARK: - Public API

    /// Classify whether `text` looks like an ingredients label.
    public static func classify(_ text: String) -> Classification {
        let normalized = TextNormalizer.normalize(text)
        let words = normalized.split(separator: " ").map(String.init)

        guard !words.isEmpty else {
            return Classification(score: 0)
        }

        var score: Double = 0

        // Signal 1: "ingredients" keyword (strong signal, worth 0.35)
        if hasIngredientsKeyword(words) {
            score += 0.35
        }

        // Signal 2: "contains" / "may contain" markers (0.15)
        if hasContainsMarker(words) {
            score += 0.15
        }

        // Signal 3: Comma density (0.2)
        // Real ingredient lists have lots of commas. A page of a novel does not.
        let commaScore = commaDensityScore(text)
        score += commaScore * 0.2

        // Signal 4: Allergen dictionary token overlap (0.15)
        let overlapScore = dictionaryOverlapScore(words)
        score += overlapScore * 0.15

        // Signal 5: E-number codes (0.1)
        if hasENumbers(text) {
            score += 0.1
        }

        // Signal 6: Percentage values (0.05)
        if hasPercentages(text) {
            score += 0.05
        }

        return Classification(score: min(score, 1.0))
    }

    /// Best-guess product name from label text. Returns the first line or
    /// sentence fragment that precedes the "ingredients" keyword, if any.
    /// This is DISPLAY ONLY and must never feed the allergen verdict.
    public static func guessProductName(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Find the line that contains an "ingredients" keyword.
        for (index, line) in lines.enumerated() {
            let normalizedLine = TextNormalizer.normalize(line)
            let lineWords = normalizedLine.split(separator: " ").map(String.init)
            if lineWords.contains(where: { ingredientsKeywords.contains($0) }) {
                // Everything before this line could be the product name.
                if index > 0 {
                    // Take the first non-trivial line before "Ingredients:".
                    for i in 0..<index {
                        let candidate = lines[i]
                        // Skip very short or very long lines (likely disclaimers).
                        if candidate.count >= 2 && candidate.count <= 80 {
                            return candidate
                        }
                    }
                }
                // If "Ingredients:" is on the first line, try text before the colon.
                if let colonRange = line.range(of: ":"),
                   let kwRange = line.range(of: "ingredients", options: .caseInsensitive),
                   kwRange.lowerBound < colonRange.lowerBound || kwRange.lowerBound == line.startIndex {
                    let before = line[line.startIndex..<kwRange.lowerBound]
                        .trimmingCharacters(in: .whitespaces)
                    if before.count >= 2 && before.count <= 80 {
                        return before
                    }
                }
                break
            }
        }
        return nil
    }

    // MARK: - Signal helpers

    private static func hasIngredientsKeyword(_ words: [String]) -> Bool {
        words.contains { ingredientsKeywords.contains($0) }
    }

    private static func hasContainsMarker(_ words: [String]) -> Bool {
        for marker in containsMarkers {
            guard marker.count <= words.count else { continue }
            for start in 0...(words.count - marker.count) {
                if Array(words[start..<(start + marker.count)]) == marker {
                    return true
                }
            }
        }
        return false
    }

    private static func commaDensityScore(_ text: String) -> Double {
        let commaCount = text.filter { $0 == "," }.count
        let wordCount = max(text.split(whereSeparator: { $0.isWhitespace }).count, 1)
        // A typical ingredient list has roughly one comma every 2-4 words.
        // A ratio of 0.15+ is a strong signal; 0.05 is weak.
        let ratio = Double(commaCount) / Double(wordCount)
        if ratio >= 0.15 { return 1.0 }
        if ratio >= 0.08 { return 0.6 }
        if ratio >= 0.03 { return 0.2 }
        return 0
    }

    private static func dictionaryOverlapScore(_ words: [String]) -> Double {
        // Count how many words overlap with known allergen/food terms.
        let knownTermWords = Set(
            AllergenDictionary.terms
                .flatMap { $0.phrase.split(separator: " ").map(String.init) }
        )
        let hits = words.filter { knownTermWords.contains($0) }.count
        let ratio = Double(hits) / Double(max(words.count, 1))
        if ratio >= 0.15 { return 1.0 }
        if ratio >= 0.08 { return 0.5 }
        if ratio >= 0.03 { return 0.2 }
        return 0
    }

    private static func hasENumbers(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return eNumberPattern.firstMatch(in: text, range: range) != nil
    }

    private static func hasPercentages(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return percentagePattern.firstMatch(in: text, range: range) != nil
    }
}

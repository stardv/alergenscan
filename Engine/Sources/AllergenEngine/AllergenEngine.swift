import Foundation

/// Finds allergens in label text and in Open Food Facts records, and merges
/// the two into a single unambiguous answer.
///
/// Two rules govern everything here:
///
/// 1. **Longest phrase wins, and consumes its words.** "Coconut milk" is
///    matched and its words are marked used, so plain "milk" can never then
///    match inside it. This is what stops peanut butter reading as dairy.
///
/// 2. **Sources are unioned, never averaged.** If the label says no milk but
///    the database says milk, the answer is milk. Disagreement always resolves
///    to the more cautious reading, so a conflict produces a false alarm
///    rather than a missed allergen.
public struct AllergenEngine {

    public init() {}

    // MARK: - Precautionary statements

    /// Phrases that mark the start of "may contain" territory. Everything from
    /// one of these to the end of its segment is treated as a trace warning
    /// rather than a declared ingredient.
    private static let precautionaryMarkers: [[String]] = [
        ["may", "contain"],
        ["may", "also", "contain"],
        ["may", "contains"],
        ["traces", "of"],
        ["trace", "of"],
        ["produced", "in", "a", "factory"],
        ["produced", "in", "a", "facility"],
        ["made", "in", "a", "factory"],
        ["made", "in", "a", "facility"],
        ["packed", "in", "a", "factory"],
        ["packed", "in", "a", "facility"],
        ["packed", "in", "an", "environment"],
        ["handled", "in", "a", "facility"],
        ["prepared", "in", "a", "kitchen"],
        ["not", "suitable", "for"],
        ["cannot", "guarantee"],
    ].sorted { $0.count > $1.count }

    /// Words that, immediately after a match, negate it: "gluten free".
    private static let trailingNegators: Set<String> = ["free"]

    /// Word sequences that, immediately before a match, negate it.
    private static let leadingNegators: [[String]] = [
        ["free", "from"],
        ["free", "of"],
        ["does", "not", "contain"],
        ["contains", "no"],
        ["without"],
        ["no"],
        // Same claim in the other big EU label languages.
        ["sans"],        // French
        ["ohne"],        // German
        ["frei", "von"], // German
        ["sin"],         // Spanish
        ["senza"],       // Italian
        ["sem"],         // Portuguese
    ].sorted { $0.count > $1.count }

    // MARK: - Label text

    /// Analyse raw text read off a package by OCR.
    public func analyze(labelText raw: String) -> [Allergen: (AllergenStatus, [String])] {
        var results: [Allergen: (AllergenStatus, [String])] = [:]

        for segment in Self.segments(of: raw) {
            let words = TextNormalizer.normalize(segment)
                .split(separator: " ")
                .map(String.init)
            guard !words.isEmpty else { continue }

            // Split the segment at the first precautionary marker, if any.
            let (declared, precautionary) = Self.splitAtPrecautionaryMarker(words)

            merge(Self.match(declared, status: .contains), into: &results)
            merge(Self.match(precautionary, status: .mayContain), into: &results)
        }

        return results
    }

    // MARK: - Open Food Facts

    /// Analyse an Open Food Facts product record.
    ///
    /// OFF gives us two things: curated `allergens_tags` / `traces_tags`, and
    /// the raw `ingredients_text`. We use **both** and union them, because the
    /// tags are frequently absent even when the ingredients name an allergen
    /// plainly.
    public func analyze(product: OFFProduct) -> [Allergen: (AllergenStatus, [String])] {
        var results: [Allergen: (AllergenStatus, [String])] = [:]

        for tag in product.allergenTags {
            guard let allergen = Allergen.from(openFoodFactsTag: tag) else { continue }
            merge([allergen: (.contains, [tag])], into: &results)
        }

        for tag in product.traceTags {
            guard let allergen = Allergen.from(openFoodFactsTag: tag) else { continue }
            merge([allergen: (.mayContain, [tag])], into: &results)
        }

        if let text = product.ingredientsText, !text.isEmpty {
            merge(analyze(labelText: text), into: &results)
        }

        return results
    }

    // MARK: - Cross-referencing

    /// Merge every source into one result, taking the most cautious status per
    /// allergen. Only allergens in `profile` are reported.
    ///
    /// When `labelText` is provided, the ingredients classifier scores whether
    /// it actually looks like a label. If it doesn't AND no allergens were
    /// found, the result becomes inconclusive (fail-safe). If allergens WERE
    /// found, they are still reported — the classifier can only make results
    /// more cautious, never less.
    public func combine(readings: [SourceReading],
                        profile: Set<Allergen>,
                        labelText: String? = nil,
                        databaseText: String? = nil,
                        productName: String? = nil) -> ScanResult {

        let usable = readings.filter { $0.findings != nil }
        guard !usable.isEmpty else {
            return ScanResult(findings: [], sourcesConsulted: [], isInconclusive: true)
        }

        var merged: [Allergen: (AllergenStatus, [String], Set<EvidenceSource>)] = [:]

        for reading in usable {
            guard let findings = reading.findings else { continue }
            for (allergen, value) in findings {
                guard profile.contains(allergen) else { continue }
                let (status, evidence) = value

                if let existing = merged[allergen] {
                    merged[allergen] = (
                        max(existing.0, status),                       // union, never average
                        Self.dedupe(existing.1 + evidence),
                        existing.2.union([reading.source])
                    )
                } else {
                    merged[allergen] = (status, Self.dedupe(evidence), [reading.source])
                }
            }
        }

        let findings: [AllergenFinding] = profile
            .map { allergen in
                if let hit = merged[allergen] {
                    return AllergenFinding(
                        allergen: allergen,
                        status: hit.0,
                        evidence: hit.1,
                        sources: hit.2.sorted { $0.rawValue < $1.rawValue }
                    )
                }
                return AllergenFinding(allergen: allergen,
                                       status: .notDetected,
                                       evidence: [],
                                       sources: [])
            }
            .sorted {
                if $0.status != $1.status { return $0.status > $1.status }
                return $0.allergen.displayName < $1.allergen.displayName
            }

        // Run the ingredients classifier on label text.
        let classification = labelText.map { IngredientsClassifier.classify($0) }
        let hasDatabase = readings.contains { $0.source == .database && $0.findings != nil }
        let hasAnyAllergens = findings.contains { $0.status != .notDetected }

        // FAIL-SAFE: If the label text doesn't look like ingredients, AND we
        // have no database source, AND no allergens were found, mark as
        // inconclusive. This prevents "None of your allergens found" on a
        // photo of a novel page. But if allergens WERE found, keep them —
        // the classifier never suppresses a hit.
        let isInconclusive: Bool
        if let classification, !classification.looksLikeLabel, !hasDatabase, !hasAnyAllergens {
            isInconclusive = true
        } else {
            isInconclusive = false
        }

        // Collect raw ingredient texts for display.
        var ingredientsTexts: [IngredientsText] = []
        if let text = labelText, !text.isEmpty {
            ingredientsTexts.append(IngredientsText(source: .label, text: text))
        }
        if let text = databaseText, !text.isEmpty {
            ingredientsTexts.append(IngredientsText(source: .database, text: text))
        }

        // Product name: prefer the one passed in (from barcode/OFF), fall
        // back to a best-guess from label text (display only).
        let resolvedName = productName
            ?? labelText.flatMap { IngredientsClassifier.guessProductName(from: $0) }

        return ScanResult(
            findings: findings,
            sourcesConsulted: usable.map(\.source),
            isInconclusive: isInconclusive,
            ingredientsTexts: ingredientsTexts,
            productName: resolvedName,
            labelConfidence: classification?.score
        )
    }

    // MARK: - Matching

    /// Longest-phrase-first matching with span consumption.
    private static func match(_ words: [String],
                              status: AllergenStatus) -> [Allergen: (AllergenStatus, [String])] {
        guard !words.isEmpty else { return [:] }

        var consumed = [Bool](repeating: false, count: words.count)
        var results: [Allergen: (AllergenStatus, [String])] = [:]

        for term in AllergenDictionary.terms {
            let phrase = term.phrase.split(separator: " ").map(String.init)
            guard !phrase.isEmpty, phrase.count <= words.count else { continue }

            for start in 0...(words.count - phrase.count) {
                let end = start + phrase.count
                if consumed[start..<end].contains(true) { continue }
                guard Array(words[start..<end]) == phrase else { continue }

                // Consume the span whether or not it flags anything, so that a
                // neutral phrase such as "coconut milk" shields the words
                // inside it, and a negated match cannot be re-matched.
                for i in start..<end { consumed[i] = true }

                guard !term.allergens.isEmpty else { continue }
                if isNegated(words, start: start, end: end) { continue }

                for allergen in term.allergens {
                    if var existing = results[allergen] {
                        existing.1.append(term.phrase)
                        results[allergen] = (max(existing.0, status), existing.1)
                    } else {
                        results[allergen] = (status, [term.phrase])
                    }
                }
            }
        }

        return results
    }

    /// True when the match sits inside a "free from" claim.
    private static func isNegated(_ words: [String], start: Int, end: Int) -> Bool {
        if end < words.count, trailingNegators.contains(words[end]) {
            return true
        }
        for negator in leadingNegators {
            let from = start - negator.count
            guard from >= 0 else { continue }
            if Array(words[from..<start]) == negator { return true }
        }
        return false
    }

    // MARK: - Segmentation

    /// Break raw label text into segments at sentence and line boundaries, so
    /// a "may contain" at the end cannot leak backwards over the ingredients.
    private static func segments(of raw: String) -> [String] {
        raw.split(whereSeparator: { $0 == "." || $0 == "\n" || $0 == ";" || $0 == "!" })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Returns (declared ingredients, precautionary tail).
    private static func splitAtPrecautionaryMarker(_ words: [String]) -> ([String], [String]) {
        for index in words.indices {
            for marker in precautionaryMarkers {
                let end = index + marker.count
                guard end <= words.count else { continue }
                if Array(words[index..<end]) == marker {
                    return (Array(words[0..<index]), Array(words[end...]))
                }
            }
        }
        return (words, [])
    }

    // MARK: - Helpers

    private func merge(_ new: [Allergen: (AllergenStatus, [String])],
                       into results: inout [Allergen: (AllergenStatus, [String])]) {
        for (allergen, value) in new {
            if let existing = results[allergen] {
                results[allergen] = (max(existing.0, value.0),
                                     Self.dedupe(existing.1 + value.1))
            } else {
                results[allergen] = (value.0, Self.dedupe(value.1))
            }
        }
    }

    private static func dedupe(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0).inserted }
    }
}

import Foundation

/// Puts label text into a single canonical form so the dictionary only ever
/// has to store one spelling of each phrase.
///
/// Deliberately conservative: it lowercases, strips accents, and turns
/// punctuation into spaces. It does **not** try to auto-correct OCR mistakes.
/// Guessing at misread characters risks inventing an ingredient that isn't
/// there, or worse, "correcting" one that is.
enum TextNormalizer {

    static func normalize(_ raw: String) -> String {
        // Ligatures survive diacritic folding, so expand them first:
        // "œuf" must reach the dictionary as "oeuf", "Eiweiß" as "eiweiss".
        let expanded = raw
            .replacingOccurrences(of: "œ", with: "oe")
            .replacingOccurrences(of: "Œ", with: "oe")
            .replacingOccurrences(of: "æ", with: "ae")
            .replacingOccurrences(of: "Æ", with: "ae")
            .replacingOccurrences(of: "ß", with: "ss")

        let folded = expanded.folding(
            options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US")
        )

        // Punctuation becomes whitespace so that "milk-free", "milk,free" and
        // "milk (free)" all reduce to the same token sequence. Digits are kept
        // because E-numbers (E220) are real allergen evidence.
        let cleaned = String(folded.map { ch -> Character in
            if ch.isLetter || ch.isNumber { return ch }
            return " "
        })

        return cleaned
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }
}

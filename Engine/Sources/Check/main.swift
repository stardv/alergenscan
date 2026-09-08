import Foundation
import AllergenEngine

// A command-line front end to the same engine the app uses. Lets you try real
// products and real ingredient text without Xcode, an iPhone, or a build.
//
//   swift run --package-path Engine Check 3017620422003
//   swift run --package-path Engine Check "sugar, whey powder, hazelnuts"
//   swift run --package-path Engine Check --all 3017620422003

let arguments = Array(CommandLine.arguments.dropFirst())

guard !arguments.isEmpty else {
    print("""
    Check an ingredient list or a barcode against an allergen profile.

      swift run --package-path Engine Check <barcode>
      swift run --package-path Engine Check "<ingredients text>"

    Options:
      --all             watch all 14 allergens, not just the defaults
      --only a,b,c      watch only these (milk, gluten, eggs, peanuts,
                        treeNuts, soybeans, fish, crustaceans, molluscs,
                        celery, mustard, sesame, sulphites, lupin)

    Default profile: \(Allergen.defaultProfile.map(\.displayName).sorted().joined(separator: ", "))
    """)
    exit(0)
}

// ── Profile ──────────────────────────────────────────────────────────────
var profile = Allergen.defaultProfile
var positional: [String] = []
var index = 0

while index < arguments.count {
    switch arguments[index] {
    case "--all":
        profile = Set(Allergen.allCases)
    case "--only":
        index += 1
        guard index < arguments.count else {
            FileHandle.standardError.write(Data("--only needs a list\n".utf8))
            exit(2)
        }
        let names = arguments[index].split(separator: ",").map {
            $0.trimmingCharacters(in: .whitespaces)
        }
        let parsed = names.compactMap { Allergen(rawValue: $0) }
        if parsed.count != names.count {
            let unknown = names.filter { Allergen(rawValue: $0) == nil }
            FileHandle.standardError.write(Data("unknown allergen: \(unknown.joined(separator: ", "))\n".utf8))
            exit(2)
        }
        profile = Set(parsed)
    default:
        positional.append(arguments[index])
    }
    index += 1
}

let input = positional.joined(separator: " ").trimmingCharacters(in: .whitespaces)
guard !input.isEmpty else {
    FileHandle.standardError.write(Data("nothing to check\n".utf8))
    exit(2)
}

// ── Run ──────────────────────────────────────────────────────────────────
let engine = AllergenEngine()
let looksLikeBarcode = input.allSatisfy(\.isNumber) && (8...14).contains(input.count)

var readings: [SourceReading] = []
var product: OFFProduct?

if looksLikeBarcode {
    do {
        let fetched = try await OpenFoodFactsClient().fetch(barcode: input)
        product = fetched
        readings.append(SourceReading(source: .database,
                                      findings: engine.analyze(product: fetched)))
    } catch {
        print("Open Food Facts: \((error as? OFFError)?.errorDescription ?? "\(error)")")
        readings.append(SourceReading(source: .database, findings: nil))
    }
} else {
    readings.append(SourceReading(source: .label,
                                  findings: engine.analyze(labelText: input)))
}

let result = engine.combine(readings: readings, profile: profile)

// ── Report ───────────────────────────────────────────────────────────────
let red    = "\u{001B}[31m", amber = "\u{001B}[33m"
let green  = "\u{001B}[32m", grey  = "\u{001B}[90m"
let bold   = "\u{001B}[1m",  reset = "\u{001B}[0m"

if let product {
    print("\n\(bold)\(product.displayName.isEmpty ? "Unnamed product" : product.displayName)\(reset)")
    print("\(grey)barcode \(product.barcode)\(reset)")
    if let text = product.ingredientsText {
        print("\(grey)\(text)\(reset)")
    }
    if product.isStale() {
        print("\(amber)! database entry is over a year old — the recipe may have changed\(reset)")
    }
}

print("")
switch result.headline {
case .contains:
    let names = result.findings.filter { $0.status == .contains }.map(\.allergen.displayName)
    print("\(red)\(bold)CONTAINS \(names.joined(separator: ", ").uppercased())\(reset)")
case .mayContain:
    let names = result.findings.filter { $0.status == .mayContain }.map(\.allergen.displayName)
    print("\(amber)\(bold)MAY CONTAIN \(names.joined(separator: ", ").uppercased())\(reset)")
case .noneDetected:
    print("\(green)\(bold)None of your allergens found\(reset)")
    print("\(grey)Not the same as safe — this only reflects what was read.\(reset)")
case .couldNotCheck:
    print("\(grey)\(bold)Couldn't check this\(reset)")
}

for finding in result.flagged {
    let colour = finding.status == .contains ? red : amber
    let label = finding.status == .contains ? "in ingredients" : "trace warning"
    print("  \(colour)•\(reset) \(finding.allergen.displayName) (\(label)) "
          + "\(grey)because of: \(finding.evidence.joined(separator: ", "))\(reset)")
}

let clear = result.findings.filter { $0.status == .notDetected }
if !clear.isEmpty {
    print("\(grey)  not found: \(clear.map(\.allergen.displayName).joined(separator: ", "))\(reset)")
}
print("")

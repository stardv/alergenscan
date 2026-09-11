import SwiftUI
import AllergenEngine

/// The verdict. Deliberately blunt: one headline, one colour, and the exact
/// words that produced it.
///
/// It never says "safe". The strongest thing it will claim is that none of
/// your allergens were *found*, which is a statement about what was read —
/// not a promise about the food.
struct ResultView: View {
    let result: ScanResult
    let product: OFFProduct?
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    banner
                    if let product { productSummary(product) }
                    else if let name = result.productName { labelProductName(name) }
                    if !result.flagged.isEmpty { flaggedList }
                    clearList
                    ingredientsTextSection
                    provenance
                    disclaimer
                }
                .padding()
            }
            .navigationTitle("Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDismiss)
                }
            }
        }
    }

    // MARK: - Headline

    private var banner: some View {
        VStack(spacing: 8) {
            Image(systemName: headline.icon)
                .font(.system(size: 48, weight: .semibold))
            Text(headline.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(headline.detail)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(headline.color, in: RoundedRectangle(cornerRadius: 18))
    }

    private var headline: Headline {
        switch result.headline {
        case .contains:
            let names = result.findings
                .filter { $0.status == .contains }
                .map(\.allergen.displayName)
            return Headline(
                icon: "xmark.octagon.fill",
                title: "Contains \(names.formattedList)",
                detail: "Do not eat.",
                color: .red
            )
        case .mayContain:
            let names = result.findings
                .filter { $0.status == .mayContain }
                .map(\.allergen.displayName)
            return Headline(
                icon: "exclamationmark.triangle.fill",
                title: "May contain \(names.formattedList)",
                detail: "The packet carries a trace warning for this.",
                color: .orange
            )
        case .noneDetected:
            return Headline(
                icon: "checkmark.circle.fill",
                title: "None of your allergens found",
                detail: "This is not the same as safe. Check the packet.",
                color: .green
            )
        case .couldNotCheck:
            return Headline(
                icon: "questionmark.circle.fill",
                title: "Couldn't check this",
                detail: "No label text was read and the barcode wasn't found. "
                      + "Read the packet yourself.",
                color: .gray
            )
        }
    }

    private struct Headline {
        let icon: String
        let title: String
        let detail: String
        let color: Color
    }

    // MARK: - Detail

    private func productSummary(_ product: OFFProduct) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if !product.displayName.isEmpty {
                Text(product.displayName).font(.headline)
            }
            Text("Barcode \(product.barcode)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if product.isStale() {
                Label("This database entry hasn't been updated in over a year. "
                      + "The recipe may have changed.",
                      systemImage: "clock.badge.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var flaggedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Found").font(.headline)
            ForEach(result.flagged) { finding in
                row(finding)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var clearList: some View {
        let clear = result.findings.filter { $0.status == .notDetected }
        return Group {
            if !clear.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Not found").font(.headline)
                    Text(clear.map(\.allergen.displayName).formattedList)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func row(_ finding: AllergenFinding) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(finding.status == .contains ? Color.red : Color.orange)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(finding.allergen.displayName).font(.body.weight(.semibold))
                Text(finding.status == .contains ? "In the ingredients" : "Trace warning")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !finding.evidence.isEmpty {
                    // Always show the words that caused the flag, so the
                    // verdict can be checked against the packet by eye.
                    Text("Because of: \(finding.evidence.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func labelProductName(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name).font(.headline)
            Text("Guessed from label text")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var ingredientsTextSection: some View {
        let texts = result.ingredientsTexts
        return Group {
            if !texts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ingredients text").font(.headline)
                    ForEach(Array(texts.enumerated()), id: \.offset) { _, item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.source == .label ? "From the label" : "From Open Food Facts")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.text)
                                .font(.caption)
                                .foregroundStyle(.primary)
                        }
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var provenance: some View {
        let sources = result.sourcesConsulted.map { source -> String in
            switch source {
            case .label:    return "the label"
            case .database: return "Open Food Facts"
            }
        }
        return Group {
            if !sources.isEmpty {
                Text("Checked against \(sources.formattedList).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var disclaimer: some View {
        Text("This app reads text and looks up a public database. Both can be "
             + "wrong or out of date, and recipes change. Always read the packet "
             + "before eating.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

private extension Array where Element == String {
    /// "milk", "milk and gluten", "milk, gluten and egg"
    var formattedList: String {
        switch count {
        case 0:  return ""
        case 1:  return self[0].lowercased()
        case 2:  return "\(self[0].lowercased()) and \(self[1].lowercased())"
        default: return dropLast().map { $0.lowercased() }.joined(separator: ", ")
                 + " and \(self[count - 1].lowercased())"
        }
    }
}

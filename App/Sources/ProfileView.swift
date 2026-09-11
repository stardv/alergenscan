import SwiftUI
import AllergenEngine

/// Pick the allergens to watch for. Everything else is ignored, which is what
/// keeps the result screen down to a single unambiguous answer.
struct ProfileView: View {
    @EnvironmentObject private var profile: AllergenProfile

    var body: some View {
        NavigationStack {
            List {
                if profile.isEmpty {
                    Section {
                        Label("Nothing is being watched for. Scanning is disabled "
                              + "until you pick at least one.",
                              systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    ForEach(Allergen.allCases) { allergen in
                        Button {
                            profile.toggle(allergen)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(allergen.displayName)
                                        .foregroundStyle(.primary)
                                    Text(allergen.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if profile.selected.contains(allergen) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Watch for")
                } footer: {
                    Text("These are the 14 allergens that must be declared by law "
                         + "in the EU and UK. They cover all nine required in the US.")
                }

                Section {
                    Button("Reset to nuts and egg") { profile.resetToDefaults() }
                        .disabled(profile.isDefault)
                    Button("Select all 14") { profile.selectAll() }
                    Button("Clear all", role: .destructive) { profile.clear() }
                        .disabled(profile.isEmpty)
                } footer: {
                    Text("Peanuts and tree nuts are listed separately because they "
                         + "are different allergens — peanuts are legumes. The "
                         + "default watches both.")
                }

                Section {
                    LabeledContent("Version", value: AppVersion.display)
                } footer: {
                    Text("Quote this when something reads wrong, so the packet "
                         + "can be checked against the build that read it.")
                }
            }
            .navigationTitle("Allergens")
        }
    }
}

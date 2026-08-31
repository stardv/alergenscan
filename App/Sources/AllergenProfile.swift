import Foundation
import AllergenEngine

/// The allergens this phone is watching for.
///
/// Stored in UserDefaults — there is no account and nothing leaves the device.
///
/// A fresh install starts on `Allergen.defaultProfile` (peanuts, tree nuts and
/// egg). After that the user's choice always wins: an empty selection is a
/// deliberate act and stays empty, rather than springing back to the defaults
/// on the next launch. That distinction is why this checks for the *presence*
/// of the key rather than reading it as an array and testing for empty.
@MainActor
final class AllergenProfile: ObservableObject {

    private static let storageKey = "alergenscan.profile.v1"

    @Published var selected: Set<Allergen> {
        didSet { save() }
    }

    var isEmpty: Bool { selected.isEmpty }

    /// True when the selection still matches a fresh install.
    var isDefault: Bool { selected == Allergen.defaultProfile }

    init(defaults: UserDefaults = .standard) {
        self.storage = defaults

        if let stored = defaults.array(forKey: Self.storageKey) as? [String] {
            self.selected = Set(stored.compactMap(Allergen.init(rawValue:)))
        } else {
            self.selected = Allergen.defaultProfile
            // Write straight away so the first launch is recorded, and a user
            // who immediately clears everything isn't handed the defaults back.
            defaults.set(Allergen.defaultProfile.map(\.rawValue).sorted(),
                         forKey: Self.storageKey)
        }
    }

    private let storage: UserDefaults

    func toggle(_ allergen: Allergen) {
        if selected.contains(allergen) {
            selected.remove(allergen)
        } else {
            selected.insert(allergen)
        }
    }

    func resetToDefaults() {
        selected = Allergen.defaultProfile
    }

    func selectAll() {
        selected = Set(Allergen.allCases)
    }

    func clear() {
        selected = []
    }

    private func save() {
        storage.set(selected.map(\.rawValue).sorted(), forKey: Self.storageKey)
    }
}

import Foundation

/// The 14 allergens whose declaration is mandatory under EU Regulation 1169/2011
/// Annex II. This set is a superset of the US "Big 9" (FALCPA + FASTER Act):
/// every US-mandated allergen maps onto one of these cases.
public enum Allergen: String, CaseIterable, Codable, Sendable, Identifiable {
    case gluten
    case crustaceans
    case eggs
    case fish
    case peanuts
    case soybeans
    case milk
    case treeNuts
    case celery
    case mustard
    case sesame
    case sulphites
    case lupin
    case molluscs

    public var id: String { rawValue }

    /// What a fresh install watches for until the user says otherwise.
    ///
    /// Change this one line to change the defaults. It only applies on first
    /// launch — once the profile has been edited, the user's choice wins, and
    /// clearing every allergen stays cleared rather than springing back.
    ///
    /// Both nut cases are included together on purpose. Peanuts are legumes
    /// and tree nuts are not, so they are separate allergens in law and in
    /// this model, but "a nut allergy" in ordinary use usually means both, and
    /// guessing narrow here would be the unsafe guess.
    public static let defaultProfile: Set<Allergen> = [.peanuts, .treeNuts, .eggs]

    /// Label shown in the UI.
    public var displayName: String {
        switch self {
        case .gluten:      return "Gluten"
        case .crustaceans: return "Crustaceans"
        case .eggs:        return "Egg"
        case .fish:        return "Fish"
        case .peanuts:     return "Peanut"
        case .soybeans:    return "Soy"
        case .milk:        return "Milk"
        case .treeNuts:    return "Tree nuts"
        case .celery:      return "Celery"
        case .mustard:     return "Mustard"
        case .sesame:      return "Sesame"
        case .sulphites:   return "Sulphites"
        case .lupin:       return "Lupin"
        case .molluscs:    return "Molluscs"
        }
    }

    /// Short clarifier shown under the name on the profile screen.
    public var subtitle: String {
        switch self {
        case .gluten:      return "Wheat, barley, rye, oats, spelt"
        case .crustaceans: return "Prawn, crab, lobster"
        case .eggs:        return "Including albumen, mayonnaise"
        case .fish:        return "Including anchovy, fish sauce"
        case .peanuts:     return "Groundnut, arachis"
        case .soybeans:    return "Soya, tofu, edamame"
        case .milk:        return "Dairy, casein, whey, lactose"
        case .treeNuts:    return "Almond, hazelnut, cashew, walnut"
        case .celery:      return "Including celeriac"
        case .mustard:     return "Including dijon"
        case .sesame:      return "Including tahini"
        case .sulphites:   return "SO2, E220–E228"
        case .lupin:       return "Lupin flour and seeds"
        case .molluscs:    return "Mussel, oyster, squid"
        }
    }

    /// Open Food Facts uses tags of the form `en:milk` in `allergens_tags`
    /// and `traces_tags`. Several OFF tags collapse onto one of our cases.
    static func from(openFoodFactsTag tag: String) -> Allergen? {
        let key = tag
            .lowercased()
            .replacingOccurrences(of: "en:", with: "")
            .trimmingCharacters(in: .whitespaces)

        switch key {
        case "gluten", "wheat", "barley", "rye", "oats", "spelt", "kamut":
            return .gluten
        case "crustaceans", "shellfish":
            return .crustaceans
        case "eggs", "egg":
            return .eggs
        case "fish":
            return .fish
        case "peanuts", "peanut":
            return .peanuts
        case "soybeans", "soy", "soya":
            return .soybeans
        case "milk", "dairy", "lactose":
            return .milk
        case "nuts", "tree-nuts", "tree nuts", "almonds", "hazelnuts",
             "walnuts", "cashew-nuts", "pecan-nuts", "pistachio-nuts",
             "macadamia-nuts", "brazil-nuts":
            return .treeNuts
        case "celery":
            return .celery
        case "mustard":
            return .mustard
        case "sesame-seeds", "sesame":
            return .sesame
        case "sulphur-dioxide-and-sulphites", "sulphites", "sulfites":
            return .sulphites
        case "lupin":
            return .lupin
        case "molluscs", "mollusks":
            return .molluscs
        default:
            return nil
        }
    }
}

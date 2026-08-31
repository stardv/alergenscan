import Foundation

/// The subset of an Open Food Facts record this app needs.
public struct OFFProduct: Sendable, Equatable {
    public let barcode: String
    public let name: String?
    public let brand: String?
    public let ingredientsText: String?
    public let allergenTags: [String]
    public let traceTags: [String]
    /// When the record was last edited. Surfaced in the UI because a stale
    /// record is the main way the database lies to you: manufacturers
    /// reformulate and the crowdsourced entry lags behind the shelf.
    public let lastModified: Date?

    public init(barcode: String,
                name: String? = nil,
                brand: String? = nil,
                ingredientsText: String? = nil,
                allergenTags: [String] = [],
                traceTags: [String] = [],
                lastModified: Date? = nil) {
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.ingredientsText = ingredientsText
        self.allergenTags = allergenTags
        self.traceTags = traceTags
        self.lastModified = lastModified
    }

    public var displayName: String {
        [brand, name].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
    }

    /// True when the record is old enough that the recipe may have changed.
    public func isStale(asOf now: Date = Date(), months: Int = 12) -> Bool {
        guard let lastModified else { return true }
        guard let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: now) else {
            return false
        }
        return lastModified < cutoff
    }
}

public enum OFFError: Error, LocalizedError, Equatable {
    case notFound
    case network(Error)
    case badResponse

    public static func == (a: OFFError, b: OFFError) -> Bool {
        switch (a, b) {
        case (.notFound, .notFound), (.badResponse, .badResponse), (.network, .network):
            return true
        default:
            return false
        }
    }

    public var errorDescription: String? {
        switch self {
        case .notFound:    return "This barcode isn't in the Open Food Facts database."
        case .network:     return "Couldn't reach Open Food Facts. Check your connection."
        case .badResponse: return "Open Food Facts returned something unexpected."
        }
    }
}

/// Minimal Open Food Facts client.
///
/// OFF is free, open data under ODbL and needs no API key. It asks that
/// clients identify themselves with a descriptive User-Agent.
public struct OpenFoodFactsClient {

    private let session: URLSession
    private let userAgent: String

    public init(session: URLSession = .shared,
                userAgent: String = "AlergenScan/1.0 (personal allergen checker)") {
        self.session = session
        self.userAgent = userAgent
    }

    public func fetch(barcode: String) async throws -> OFFProduct {
        let fields = "code,product_name,brands,ingredients_text,allergens_tags,traces_tags,last_modified_t"
        guard let url = URL(string:
            "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=\(fields)"
        ) else { throw OFFError.badResponse }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12

        let data: Data
        do {
            let (body, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 404 {
                throw OFFError.notFound
            }
            data = body
        } catch let error as OFFError {
            throw error
        } catch {
            throw OFFError.network(error)
        }

        return try Self.decode(data, barcode: barcode)
    }

    public static func decode(_ data: Data, barcode: String) throws -> OFFProduct {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw OFFError.badResponse
        }

        // OFF signals a miss with status 0 and/or a missing product object.
        if let status = root["status"] as? Int, status == 0 { throw OFFError.notFound }
        guard let product = root["product"] as? [String: Any] else { throw OFFError.notFound }

        let timestamp = (product["last_modified_t"] as? Double)
            ?? (product["last_modified_t"] as? NSNumber)?.doubleValue
            ?? Double(product["last_modified_t"] as? String ?? "")

        return OFFProduct(
            barcode: product["code"] as? String ?? barcode,
            name: (product["product_name"] as? String)?.nonEmpty,
            brand: (product["brands"] as? String)?.nonEmpty,
            ingredientsText: (product["ingredients_text"] as? String)?.nonEmpty,
            allergenTags: product["allergens_tags"] as? [String] ?? [],
            traceTags: product["traces_tags"] as? [String] ?? [],
            lastModified: timestamp.map { Date(timeIntervalSince1970: $0) }
        )
    }
}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

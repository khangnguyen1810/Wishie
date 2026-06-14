import Foundation

protocol ProductMetadataServiceProtocol {
    func fetchMetadata(from urlString: String) async throws -> ProductMetadata
}

class ProductMetadataService: ProductMetadataServiceProtocol {

    func fetchMetadata(from urlString: String) async throws -> ProductMetadata {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        return extractMetadata(from: html, originalUrl: urlString)
    }

    private func nonEmpty(_ string: String?) -> String? {
        guard let s = string?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }

    private func extractMetadata(from html: String, originalUrl: String) -> ProductMetadata {
        let title = nonEmpty(extractMetaContent(from: html, property: "og:title"))
            ?? extractTitleTag(from: html)
            ?? "Unknown Product"

        let productDescription = nonEmpty(extractMetaContent(from: html, property: "og:description"))
            ?? nonEmpty(extractMetaName(from: html, name: "description"))
            ?? ""

        let imageUrl = nonEmpty(extractMetaContent(from: html, property: "og:image"))

        let productUrl = nonEmpty(extractMetaContent(from: html, property: "og:url")) ?? originalUrl

        let price: String? = extractJsonLdPrice(from: html)
            ?? extractMetaPrice(from: html)

        return ProductMetadata(
            title: title,
            productDescription: productDescription,
            imageUrl: imageUrl,
            productUrl: productUrl,
            price: price
        )
    }

    private func extractMetaContent(from html: String, property: String) -> String? {
        let patterns = [
            "<meta[^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"'][^>]+content=[\"']([^\"']*)[\"'][^>]*>",
            "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+property=[\"']\(NSRegularExpression.escapedPattern(for: property))[\"'][^>]*>"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               let captureRange = Range(match.range(at: 1), in: html) {
                return String(html[captureRange])
            }
        }

        return nil
    }

    private func extractMetaName(from html: String, name: String) -> String? {
        let patterns = [
            "<meta[^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"'][^>]+content=[\"']([^\"']*)[\"'][^>]*>",
            "<meta[^>]+content=[\"']([^\"']*)[\"'][^>]+name=[\"']\(NSRegularExpression.escapedPattern(for: name))[\"'][^>]*>"
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { continue }
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               let captureRange = Range(match.range(at: 1), in: html) {
                return String(html[captureRange])
            }
        }

        return nil
    }

    private func extractTitleTag(from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "<title[^>]*>([^<]*)</title>", options: [.caseInsensitive]) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           let captureRange = Range(match.range(at: 1), in: html) {
            return String(html[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private func extractJsonLdPrice(from html: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: "<script[^>]+type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard let captureRange = Range(match.range(at: 1), in: html) else { continue }
            let jsonString = String(html[captureRange])
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else { continue }

            if let price = extractPriceFromJsonLdObject(json) {
                return price
            }
        }
        return nil
    }

    private func extractPriceFromJsonLdObject(_ object: Any) -> String? {
        if let array = object as? [[String: Any]] {
            for item in array {
                if let price = extractPriceFromJsonLdObject(item) { return price }
            }
            return nil
        }

        guard let dict = object as? [String: Any] else { return nil }

        if let offerRaw = dict["offers"] {
            if let offer = offerRaw as? [String: Any],
               let price = offer["price"],
               let currency = offer["priceCurrency"] as? String {
                return "\(currency) \(price)"
            }
            if let offers = offerRaw as? [[String: Any]],
               let first = offers.first,
               let price = first["price"],
               let currency = first["priceCurrency"] as? String {
                return "\(currency) \(price)"
            }
        }

        if let graph = dict["@graph"] as? [[String: Any]] {
            for node in graph {
                if let price = extractPriceFromJsonLdObject(node) { return price }
            }
        }

        return nil
    }

    private func extractMetaPrice(from html: String) -> String? {
        let amount = nonEmpty(extractMetaContent(from: html, property: "product:price:amount"))
            ?? nonEmpty(extractMetaContent(from: html, property: "og:price:amount"))
            ?? nonEmpty(extractMetaContent(from: html, property: "og:price"))
        guard let amount else { return nil }

        let currency = nonEmpty(extractMetaContent(from: html, property: "product:price:currency"))
            ?? nonEmpty(extractMetaContent(from: html, property: "og:price:currency"))

        if let currency {
            return "\(currency) \(amount)"
        }
        return amount
    }
}

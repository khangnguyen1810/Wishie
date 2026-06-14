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

    private func extractMetadata(from html: String, originalUrl: String) -> ProductMetadata {
        let title = extractMetaContent(from: html, property: "og:title")
            ?? extractTitleTag(from: html)
            ?? "Unknown Product"

        let productDescription = extractMetaContent(from: html, property: "og:description")
            ?? extractMetaName(from: html, name: "description")
            ?? ""

        let imageUrl = extractMetaContent(from: html, property: "og:image")

        let productUrl = extractMetaContent(from: html, property: "og:url") ?? originalUrl

        let price: String? = {
            let amount = extractMetaContent(from: html, property: "product:price:amount")
                ?? extractMetaContent(from: html, property: "og:price:amount")
            guard let amount else { return nil }

            let currency = extractMetaContent(from: html, property: "product:price:currency")
                ?? extractMetaContent(from: html, property: "og:price:currency")

            if let currency {
                return "\(currency) \(amount)"
            }
            return amount
        }()

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
}

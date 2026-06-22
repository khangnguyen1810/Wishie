import Foundation
import WebKit

@MainActor
final class WebViewMetadataExtractor: NSObject, WKNavigationDelegate {

    private var webView: WKWebView?
    private var continuation: CheckedContinuation<ProductMetadata, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var isTimedOut = false

    func extract(from url: URL) async throws -> ProductMetadata {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let webView = WKWebView(frame: CGRect(x: -1, y: -1, width: 1, height: 1), configuration: WKWebViewConfiguration())
            webView.navigationDelegate = self
            webView.isHidden = true
            self.webView = webView

            let keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            keyWindow?.addSubview(webView)

            webView.load(URLRequest(url: url))

            timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                guard let self, !Task.isCancelled else { return }
                self.isTimedOut = true
                self.finishExtraction()
            }
        }
    }

    private func finishExtraction() {
        timeoutTask?.cancel()
        timeoutTask = nil

        guard let webView = self.webView, let continuation = self.continuation else { return }
        self.continuation = nil
        self.webView = nil
        webView.navigationDelegate = nil

        let timedOut = isTimedOut
        let originalUrl = webView.url?.absoluteString ?? ""

        webView.evaluateJavaScript(extractionScript) { [webView] result, error in
            webView.removeFromSuperview()
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                let metadata = Self.parseMetadata(from: result, originalUrl: originalUrl)
                if timedOut && metadata.title == "Unknown Product" {
                    continuation.resume(throwing: URLError(.timedOut))
                } else {
                    continuation.resume(returning: metadata)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self else { return }
            self.finishExtraction()
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        timeoutTask?.cancel()
        timeoutTask = nil
        webView.removeFromSuperview()
        continuation?.resume(throwing: error)
        continuation = nil
        webView.navigationDelegate = nil
        self.webView = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        timeoutTask?.cancel()
        timeoutTask = nil
        webView.removeFromSuperview()
        continuation?.resume(throwing: error)
        continuation = nil
        webView.navigationDelegate = nil
        self.webView = nil
    }

    private var extractionScript: String {
        """
        (function() {
            var title = document.querySelector('meta[property="og:title"]')?.content || document.title || '';
            var image = document.querySelector('meta[property="og:image"]')?.content || '';
            var description = document.querySelector('meta[property="og:description"]')?.content || '';
            var url = document.querySelector('meta[property="og:url"]')?.content || window.location.href || '';
            var priceAmount = document.querySelector('meta[property="product:price:amount"]')?.content || '';
            var priceCurrency = document.querySelector('meta[property="product:price:currency"]')?.content || '';
            var price = (priceAmount && priceCurrency) ? (priceCurrency + ' ' + priceAmount) : '';
            return { title: title, description: description, image: image, url: url, price: price };
        })();
        """
    }

    private static func parseMetadata(from result: Any?, originalUrl: String) -> ProductMetadata {
        guard let dict = result as? [String: Any] else {
            return ProductMetadata(
                title: "Unknown Product",
                productDescription: "",
                imageUrl: nil,
                productUrl: originalUrl,
                price: nil
            )
        }

        let rawTitle = (dict["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = rawTitle.isEmpty ? "Unknown Product" : rawTitle

        let productDescription = (dict["description"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let rawImage = (dict["image"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let imageUrl: String? = rawImage.isEmpty ? nil : rawImage

        let rawUrl = (dict["url"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let productUrl = rawUrl.isEmpty ? originalUrl : rawUrl

        let rawPrice = (dict["price"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let price: String? = rawPrice.isEmpty ? nil : rawPrice

        return ProductMetadata(
            title: title,
            productDescription: productDescription,
            imageUrl: imageUrl,
            productUrl: productUrl,
            price: price
        )
    }
}

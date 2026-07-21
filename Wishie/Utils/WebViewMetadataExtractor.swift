import Foundation
import WebKit

@MainActor
final class WebViewMetadataExtractor: NSObject, MetadataExtracting, WKNavigationDelegate {

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

        webView.callAsyncJavaScript(extractionScript, arguments: [:], in: nil, in: .page) { [webView] result in
            webView.removeFromSuperview()
            switch result {
            case .success(let value):
                let metadata = Self.parseMetadata(from: value, originalUrl: originalUrl)
                if timedOut && metadata.title == "Unknown Product" {
                    continuation.resume(throwing: URLError(.timedOut))
                } else {
                    continuation.resume(returning: metadata)
                }
            case .failure(let error):
                continuation.resume(throwing: error)
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
        var title = document.querySelector('meta[property="og:title"]')?.content || document.title || '';
        var image = document.querySelector('meta[property="og:image"]')?.content || '';
        var description = document.querySelector('meta[property="og:description"]')?.content || '';
        var url = document.querySelector('meta[property="og:url"]')?.content || window.location.href || '';
        var price = '';

        var pa = document.querySelector('meta[property="product:price:amount"]')?.content || '';
        var pc = document.querySelector('meta[property="product:price:currency"]')?.content || '';
        if (pa && pc) { price = pc + ' ' + pa; }

        if (!price) {
            var ldScripts = document.querySelectorAll('script[type="application/ld+json"]');
            for (var i = 0; i < ldScripts.length && !price; i++) {
                try {
                    var ld = JSON.parse(ldScripts[i].textContent);
                    var ldItems = ld['@graph'] ? ld['@graph'] : [ld];
                    for (var j = 0; j < ldItems.length && !price; j++) {
                        var ldItem = ldItems[j];
                        if (ldItem['@type'] === 'Product' && ldItem.offers) {
                            var offer = Array.isArray(ldItem.offers) ? ldItem.offers[0] : ldItem.offers;
                            if (offer && offer.price !== undefined) {
                                price = offer.priceCurrency ? offer.priceCurrency + ' ' + offer.price : String(offer.price);
                            }
                        }
                    }
                } catch(e) {}
            }
        }

        if (!price) {
            try {
                var nextEl = document.getElementById('__NEXT_DATA__');
                if (nextEl) {
                    var nd = JSON.parse(nextEl.textContent);
                    var pp = nd && nd.props;
                    var ndItem = null;
                    if (pp) {
                        ndItem = (pp.pageProps && pp.pageProps.initialData && pp.pageProps.initialData.data && pp.pageProps.initialData.data.item) ||
                                 (pp.initialState && pp.initialState.pdpData && pp.initialState.pdpData.data);
                    }
                    if (ndItem && (ndItem.price !== undefined || ndItem.price_min !== undefined)) {
                        var pMin = ndItem.price_min !== undefined ? ndItem.price_min : ndItem.price;
                        var pMax = ndItem.price_max !== undefined ? ndItem.price_max : pMin;
                        var curMap = { 'VND': '₫', 'USD': '$', 'SGD': 'S$', 'MYR': 'RM', 'PHP': '₱', 'THB': '฿', 'IDR': 'Rp' };
                        var cur = curMap[ndItem.currency] || (ndItem.currency ? ndItem.currency + ' ' : '₫');
                        var ndFmt = function(v) { return Math.round(v / 100000).toString().replace(/\\B(?=(\\d{3})+(?!\\d))/g, '.'); };
                        price = (pMax !== pMin) ? (cur + ndFmt(pMin) + ' - ' + cur + ndFmt(pMax)) : (cur + ndFmt(pMin));
                    }
                }
            } catch(e) {}
        }

        function tryDomPrice() {
            var cssSelectors = [
                '[class*="pdp-price"][class*="color_orange"]',
                '[class*="pdp-price"][class*="size_xl"]',
                '[class*="pdp-price"]',
                '[class*="product-price"][class*="current"]',
                '[class*="selling-price"]',
                '[class*="sale-price"]',
                '[class*="current-price"]',
                '[class*="discounted-price"]',
                '[data-price]',
                '.price-box .price'
            ];
            for (var k = 0; k < cssSelectors.length; k++) {
                var sEl = document.querySelector(cssSelectors[k]);
                if (sEl) {
                    var sText = (sEl.innerText || sEl.textContent || '').trim();
                    if (sText && /[\\d]/.test(sText)) return sText;
                }
            }
            var priceRe = /₫[\\d.,]+(?:[.,]\\d{3})*(?:\\s*[-–]\\s*₫[\\d.,]+(?:[.,]\\d{3})*)*/;
            var bestP = '', bestFs = 0;
            var domEls = document.querySelectorAll('div, span, b, strong');
            for (var m = 0; m < domEls.length; m++) {
                var domEl = domEls[m];
                var tc = (domEl.textContent || '').trim();
                if (!tc || tc.length > 60 || domEl.children.length > 3) continue;
                var rm = tc.match(priceRe);
                if (!rm) continue;
                var cs = window.getComputedStyle(domEl);
                if (cs.display === 'none' || cs.visibility === 'hidden') continue;
                var fs = parseFloat(cs.fontSize) || 0;
                if (fs > bestFs) { bestP = rm[0]; bestFs = fs; }
            }
            return bestP;
        }

        if (!price) { price = tryDomPrice(); }

        if (!price) {
            for (var retry = 0; retry < 5 && !price; retry++) {
                await new Promise(function(r) { setTimeout(r, 600); });
                price = tryDomPrice();
            }
        }

        return { title: title, description: description, image: image, url: url, price: price };
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

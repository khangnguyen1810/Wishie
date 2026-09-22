//
//  WishieLinks.swift
//  Wishie
//

import Foundation

/// The single definition of the shareable join link, used by both ends of the QR flow:
/// `WishlistQRCodeViewModel` builds one into a QR image, `ScanQRScreenViewModel` validates and
/// parses one back out. They used to hardcode the host separately, which meant a DEBUG build
/// generated a production link its own scanner then rejected.
enum WishieLinks {
#if DEBUG
    static let joinHost = "wishie-web-qa.vercel.app"
#else
    static let joinHost = "wishie-web.vercel.app"
#endif

    static let scheme = "https"

    /// `code` is the invite code from `GET /wishlists/:id/share` — never a wishlist UUID, which
    /// `GET|POST /wishlists/join/:code` does not accept.
    static func joinURL(code: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = joinHost
        components.path = "/join/\(code)"
        return components.url
    }

    /// Pulls the invite code back out of a scanned link, or `nil` if it isn't a Wishie join link.
    static func joinCode(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == joinHost else { return nil }
        let components = url.pathComponents
        guard let joinIndex = components.firstIndex(of: "join"),
              components.count > joinIndex + 1 else {
            return nil
        }
        let code = components[joinIndex + 1].trimmingCharacters(in: .whitespacesAndNewlines)
        return code.isEmpty ? nil : code
    }
}

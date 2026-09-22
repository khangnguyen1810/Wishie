//
//  WishlistJoinPreview.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 22/9/26.
//

import Foundation

/// What `GET /wishlists/join/:code` can actually tell us about a wishlist before the caller joins
/// it. Deliberately *not* a `WishlistModel`: the preview endpoint returns no items, members or
/// picked state, so folding it into `WishlistModel` would hand the info screen empty collections
/// that render as `0 items / 0 members`.
///
/// `code` is the scanned invite code, carried through so the info screen can `POST` to the same
/// `/wishlists/join/:code` route — the wishlist's `id` is a UUID and is not accepted there.
struct WishlistJoinPreview: Hashable {
    let code: String
    let id: String
    let name: String
    let description: String
    let dueDate: Date
    let themeColor: String?
    let itemCount: Int
    /// Optional because `API.md` doesn't list an owner on the join-preview response; the info
    /// screen hides the "Created by" section rather than showing a blank name.
    let ownerName: String?

    var theme: GradientTheme {
        GradientTheme(rawValue: themeColor ?? "sunset") ?? .sunset
    }
}

extension WishlistJoinPreview {
    init(code: String, response: WishlistInfoResponse) {
        self.code = code
        self.id = response.id
        self.name = response.name
        self.description = response.description
        self.dueDate = WishieDateFormatting.parseServerDate(response.dueDate) ?? Date()
        self.themeColor = response.colorTheme
        self.itemCount = response.itemCount
        self.ownerName = response.ownerName
    }
}

//
//  Route.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 30/12/25.
//

import Foundation

enum Route: Hashable {
    case createNew
    case scanQRCode
    case createSuccess(wishListId: String)
    case qrCodeScreen(wishlistId: String)
    case wishListInfoScreen(wishlistId: String)
    case wishListDetailScreen(wishlistId: String, isFromInfo: Bool)
}

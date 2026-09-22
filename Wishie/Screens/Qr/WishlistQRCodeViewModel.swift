//
//  WishlistQRCodeViewModel.swift
//  Wishie
//

import Foundation
import UIKit

@MainActor
final class WishlistQRCodeViewModel: ObservableObject {
    @Published var qrImage: UIImage?
    @Published var isLoading: Bool = false
    @Published var loadFailed: Bool = false
    @Published var errorMessage: String = ""

    private let wishlistService: WishlistServiceProtocol

    init(wishlistService: WishlistServiceProtocol = WishlistService()) {
        self.wishlistService = wishlistService
    }

    /// The link has to carry the wishlist's *invite code*, not its id: `GET|POST
    /// /wishlists/join/:code` matches only against the code and 404s on a UUID. The screen used
    /// to build the link straight from `wishlistId`, so every QR the app produced was unjoinable.
    func loadQRCode(wishlistId: String) async {
        guard !isLoading, qrImage == nil else { return }
        isLoading = true
        defer { isLoading = false }

        switch await wishlistService.getInviteCode(wishlistId: wishlistId) {
        case .success(let inviteCode):
            guard let url = WishieLinks.joinURL(code: inviteCode),
                  let image = QRCodeGenerator.generate(from: url.absoluteString) else {
                showError("Couldn't build the QR code. Please try again.")
                return
            }
            qrImage = image
        case .failure(let error):
            if case .server(403, _, _)? = error as? APIError {
                showError("Only the wishlist owner can share an invite code.")
            } else {
                showError("Couldn't load the invite code. Please try again.")
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        loadFailed = true
    }
}

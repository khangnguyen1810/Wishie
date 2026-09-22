//
//  WishListInformationViewModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 28/1/26.
//

import Foundation

@MainActor
class WishListInformationViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var joinFailed: Bool = false
    @Published var joinErrorMessage: String = ""
    /// Set to the joined wishlist's id once `POST /wishlists/join/:code` succeeds; the view
    /// observes it to navigate straight into the detail screen as a member. `join()` clears it
    /// first, so returning to this screen and tapping Join again still fires `onChange` even
    /// when the resulting id is unchanged.
    @Published var joinedWishlistId: String?

    private var service: WishlistServiceProtocol
    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    /// `wishlistId` is the preview's own id, used only for the "already a member" case below.
    func join(code: String, wishlistId: String) async {
        guard !isLoading else { return }
        isLoading = true
        joinedWishlistId = nil
        defer { isLoading = false }

        switch await service.joinWishlist(code: code) {
        case .success(let joinedId):
            joinedWishlistId = joinedId
        case .failure(let error):
            handleJoinFailure(error, wishlistId: wishlistId)
        }
    }

    private func handleJoinFailure(_ error: Error, wishlistId: String) {
        guard let apiError = error as? APIError else {
            showJoinError("Something went wrong. Please try again.")
            return
        }
        switch apiError {
        // 409 means the caller already joined. That's not a failure from the user's point of
        // view — re-scanning a code should just open the wishlist rather than dead-end on an
        // error dialog.
        case .server(409, _, _):
            joinedWishlistId = wishlistId
        // 404 means the invite code is invalid, revoked, or unknown. Retrying will never work,
        // so don't tell the user to try again.
        case .server(404, _, _):
            showJoinError("This invite link is no longer valid. Ask for a new one.")
        case .transport:
            showJoinError("Can't reach Wishie right now. Check your connection and try again.")
        default:
            showJoinError("You currently can't join this wishlist. Please try again.")
        }
    }

    private func showJoinError(_ message: String) {
        joinErrorMessage = message
        joinFailed = true
    }
}

//
//  HomeViewModel.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 9/2/26.
//

import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var myWishlists: [(WishlistModel, UserModel)] = []
    @Published var myFriendWishlists: [(WishlistModel, UserModel)] = []
    @Published var isGettingList: Bool = false
    @Published var errorMessage: String = "" {
        didSet { isShowError = !errorMessage.isEmpty }
    }
    @Published var isShowError: Bool = false
    private var service: WishlistServiceProtocol

    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    /// Pass `showLoading: false` from pull-to-refresh: Home shows its own inline refresh indicator,
    /// and toggling the full-screen overlay re-renders Home mid-refresh, which makes SwiftUI cancel the
    /// `.refreshable` task (and Alamofire then cancels the request -> "Request explicitly cancelled").
    func getListWishlist(showLoading: Bool = true) async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
        if showLoading { isGettingList = true }
        defer { if showLoading { isGettingList = false } }
        do {
            let wishlists = try await service.getUserWishlists().filter { !$0.isArchived }
            let owned = wishlists.filter { $0.members[userId] == .owner }
            let joined = wishlists.filter { $0.members[userId] == .member }
            async let ownedPairs = service.pairWithOwnerProfiles(owned)
            async let joinedPairs = service.pairWithOwnerProfiles(joined)
            (myWishlists, myFriendWishlists) = await (ownedPairs, joinedPairs)
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = (error as? WishieError)?.errorDescription ?? error.localizedDescription
        }
    }

    func deleteWishlist(wishlistId: String) async {
        do {
            let result = try await service.deleteWishlist(wishlistId: wishlistId)
            switch result {
            case .success:
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func leaveWishlist(wishlistId: String) async {
        do {
            let result = try await service.leaveWishlist(wishListId: wishlistId)
            switch result {
            case .success:
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func archiveWishlist(wishlistId: String) async {
        do {
            let result = try await service.setArchived(wishlistId: wishlistId, isArchived: true)
            switch result {
            case .success:
                await getListWishlist()
            case .failure(let failure):
                self.errorMessage = failure.localizedDescription
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

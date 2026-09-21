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
    @Published var errorMessage: String = ""
    private var service: WishlistServiceProtocol

    init(service: WishlistServiceProtocol = WishlistService()) {
        self.service = service
    }

    func getListWishlist() async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return }
        isGettingList = true
        defer { isGettingList = false }
        do {
            let wishlists = try await service.getUserWishlists().filter { !$0.isArchived }
            let owned = wishlists.filter { $0.members[userId] == .owner }
            let joined = wishlists.filter { $0.members[userId] == .member }
            async let ownedPairs = service.pairWithOwnerProfiles(owned)
            async let joinedPairs = service.pairWithOwnerProfiles(joined)
            (myWishlists, myFriendWishlists) = await (ownedPairs, joinedPairs)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
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

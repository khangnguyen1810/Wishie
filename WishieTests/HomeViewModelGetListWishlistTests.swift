// WishieTests/HomeViewModelGetListWishlistTests.swift
import Testing
import Foundation
@testable import Wishie

@MainActor
struct HomeViewModelGetListWishlistTests {
    @Test func splitsOwnedAndJoinedWishlistsByRole() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .success([
            WishlistModel(id: "owned", name: "Mine", userCreateId: "me", members: ["me": .owner]),
            WishlistModel(id: "joined", name: "Theirs", userCreateId: "friend", members: ["me": .member, "friend": .owner])
        ])
        mock.profilesById = ["me": UserModel(dictionary: ["firstName": "Me"]), "friend": UserModel(dictionary: ["firstName": "Friend"])]
        let viewModel = HomeViewModel(service: mock)

        await viewModel.getListWishlist()

        #expect(viewModel.myWishlists.map(\.0.id) == ["owned"])
        #expect(viewModel.myFriendWishlists.map(\.0.id) == ["joined"])
        #expect(viewModel.myFriendWishlists.first?.1.firstName == "Friend")
        #expect(viewModel.isGettingList == false)
    }

    @Test func excludesArchivedWishlistsFromBothLists() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .success([
            WishlistModel(id: "archived", name: "Old", userCreateId: "me", members: ["me": .owner], isArchived: true)
        ])
        mock.profilesById = ["me": UserModel()]
        let viewModel = HomeViewModel(service: mock)

        await viewModel.getListWishlist()

        #expect(viewModel.myWishlists.isEmpty)
        #expect(viewModel.myFriendWishlists.isEmpty)
    }

    @Test func surfacesAPIErrorMessageOnFailure() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .failure(APIError.server(statusCode: 500, message: "Server exploded", code: nil))
        let viewModel = HomeViewModel(service: mock)

        await viewModel.getListWishlist()

        #expect(viewModel.errorMessage == "Server exploded")
        #expect(viewModel.isGettingList == false)
    }
}

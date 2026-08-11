// WishieTests/ArchivedWishlistsViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

extension UserDefaultsSharingTests {
    @MainActor
    @Suite
    struct ArchivedWishlistsViewModelTests {
    @Test func showsOnlySelfOwnedArchivedWishlists() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .success([
            WishlistModel(id: "archived-owned", name: "Old", userCreateId: "me", members: ["me": .owner], isArchived: true),
            WishlistModel(id: "active-owned", name: "Active", userCreateId: "me", members: ["me": .owner], isArchived: false),
            WishlistModel(id: "archived-joined", name: "Friend's", userCreateId: "friend", members: ["me": .member, "friend": .owner], isArchived: true)
        ])
        mock.profilesById = ["me": UserModel(dictionary: ["firstName": "Me"])]
        let viewModel = ArchivedWishlistsViewModel(service: mock)

        await viewModel.loadArchivedWishlists()

        #expect(viewModel.archivedWishlists.map(\.0.id) == ["archived-owned"])
        #expect(viewModel.isLoading == false)
    }

    @Test func surfacesAPIErrorMessageOnFailure() async throws {
        UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
        defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
        let mock = MockWishlistService()
        mock.wishlistsResult = .failure(APIError.server(statusCode: 500, message: "Server exploded", code: nil))
        let viewModel = ArchivedWishlistsViewModel(service: mock)

        await viewModel.loadArchivedWishlists()

        #expect(viewModel.errorMessage == "Server exploded")
    }
    }
}

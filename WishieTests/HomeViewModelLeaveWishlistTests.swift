// WishieTests/HomeViewModelLeaveWishlistTests.swift
import Testing
import Foundation
@testable import Wishie

extension UserDefaultsSharingTests {
    @MainActor
    @Suite
    struct HomeViewModelLeaveWishlistTests {
        @Test func leavingRefreshesTheListSoTheLeftWishlistDisappears() async throws {
            UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
            defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
            let mock = MockWishlistService()
            mock.wishlistsResult = .success([
                WishlistModel(id: "joined", name: "Theirs", userCreateId: "friend", members: ["me": .member, "friend": .owner])
            ])
            mock.profilesById = ["friend": UserModel(dictionary: ["firstName": "Friend"])]
            let viewModel = HomeViewModel(service: mock)
            await viewModel.getListWishlist()
            #expect(viewModel.myFriendWishlists.map(\.0.id) == ["joined"])

            // After leaving, the backend no longer returns the wishlist for this user.
            mock.wishlistsResult = .success([])
            await viewModel.leaveWishlist(wishlistId: "joined")

            #expect(mock.leftWishlistIds == ["joined"])
            #expect(viewModel.myFriendWishlists.isEmpty)
            #expect(viewModel.isShowError == false)
        }

        @Test func surfacesTheErrorMessageWhenLeavingFails() async throws {
            UserDefaults.standard.set("me", forKey: WishieConstants.userIdKey)
            defer { UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey) }
            let mock = MockWishlistService()
            mock.leaveWishlistResult = .failure(.server(statusCode: 404, message: "Not a member of this wishlist", error: "Not Found"))
            let viewModel = HomeViewModel(service: mock)

            await viewModel.leaveWishlist(wishlistId: "joined")

            #expect(viewModel.errorMessage == "Not a member of this wishlist")
            #expect(viewModel.isShowError)
        }
    }
}

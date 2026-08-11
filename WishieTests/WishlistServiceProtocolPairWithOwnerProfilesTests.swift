// WishieTests/WishlistServiceProtocolPairWithOwnerProfilesTests.swift
import Testing
import Foundation
@testable import Wishie

struct WishlistServiceProtocolPairWithOwnerProfilesTests {
    private func wishlist(id: String, ownerId: String) -> WishlistModel {
        WishlistModel(id: id, name: "List \(id)", userCreateId: ownerId, members: [ownerId: .owner])
    }

    @Test func pairsEachWishlistWithItsOwnersProfile() async throws {
        let mock = MockWishlistService()
        mock.profilesById = ["u1": UserModel(dictionary: ["firstName": "Ada"])]

        let pairs = await mock.pairWithOwnerProfiles([wishlist(id: "w1", ownerId: "u1")])

        #expect(pairs.count == 1)
        #expect(pairs.first?.0.id == "w1")
        #expect(pairs.first?.1.firstName == "Ada")
    }

    @Test func fetchesEachDistinctOwnerOnlyOnce() async throws {
        let mock = MockWishlistService()
        mock.profilesById = ["u1": UserModel(dictionary: ["firstName": "Ada"])]
        let wishlists = [wishlist(id: "w1", ownerId: "u1"), wishlist(id: "w2", ownerId: "u1"), wishlist(id: "w3", ownerId: "u1")]

        let pairs = await mock.pairWithOwnerProfiles(wishlists)

        #expect(pairs.count == 3)
        #expect(mock.requestedProfileIds == ["u1"])
    }

    @Test func returnsEmptyForAnEmptyList() async throws {
        let mock = MockWishlistService()

        let pairs = await mock.pairWithOwnerProfiles([])

        #expect(pairs.isEmpty)
        #expect(mock.requestedProfileIds.isEmpty)
    }

    @Test func omitsOnlyTheWishlistWhoseOwnerProfileFetchFailed() async throws {
        let mock = MockWishlistService()
        mock.profilesById = [
            "u1": UserModel(dictionary: ["firstName": "Ada"]),
            "u3": UserModel(dictionary: ["firstName": "Grace"])
        ]
        mock.getProfileErrorsById = ["u2": NSError(domain: "WishlistServiceTests", code: 404)]
        let wishlists = [
            wishlist(id: "w1", ownerId: "u1"),
            wishlist(id: "w2", ownerId: "u2"),
            wishlist(id: "w3", ownerId: "u3")
        ]

        let pairs = await mock.pairWithOwnerProfiles(wishlists)

        #expect(pairs.map(\.0.id).sorted() == ["w1", "w3"])
        #expect(pairs.first(where: { $0.0.id == "w1" })?.1.firstName == "Ada")
        #expect(pairs.first(where: { $0.0.id == "w3" })?.1.firstName == "Grace")
        #expect(pairs.contains { $0.0.id == "w2" } == false)
    }
}

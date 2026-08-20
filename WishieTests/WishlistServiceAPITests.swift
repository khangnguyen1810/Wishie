// WishieTests/WishlistServiceAPITests.swift
import Testing
import Foundation
import UIKit
@testable import Wishie

struct WishlistServiceAPITests {
    private func sampleWishlistResponse(id: String = "w1", ownerId: String = "u1") -> WishlistResponse {
        WishlistResponse(
            id: id, name: "Birthday", description: "Party", ownerId: ownerId,
            dueDate: "2026-09-01T00:00:00.000Z", colorTheme: nil, isArchived: false,
            createdAt: "2026-01-01T00:00:00.000Z", members: [], items: []
        )
    }

    private func sampleProfileResponse(id: String = "u1", firstName: String = "Ada") -> ProfileResponse {
        ProfileResponse(id: id, firstName: firstName, lastName: "Lovelace", email: "ada@example.com", phone: "123", dateOfBirth: nil, avatarUrl: nil, interests: [], hasCompletedInterestsSetup: false, createdAt: "2026-01-01T00:00:00.000Z")
    }

    @Test func getUserWishlistsMapsEachResponseEntry() async throws {
        let stub = StubAPIService()
        stub.sendResults = [[sampleWishlistResponse(id: "w1"), sampleWishlistResponse(id: "w2")]]
        let service = WishlistService(apiService: stub)

        let result = try await service.getUserWishlists()

        #expect(result.map(\.id) == ["w1", "w2"])
        #expect(stub.sentRoutes.count == 1)
        guard case .getWishlists = stub.sentRoutes[0] else {
            Issue.record("expected .getWishlists route")
            return
        }
    }

    @Test func getProfileMapsTheResponseAndRequestsTheGivenId() async throws {
        let stub = StubAPIService()
        stub.sendResults = [sampleProfileResponse(id: "u2", firstName: "Grace")]
        let service = WishlistService(apiService: stub)

        let profile = try await service.getProfile(id: "u2")

        #expect(profile.firstName == "Grace")
        guard case .getProfile(let id) = stub.sentRoutes[0] else {
            Issue.record("expected .getProfile route")
            return
        }
        #expect(id == "u2")
    }

    private func testImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }

    @Test func createWishlistSendsTheWishlistAndMapsTheResponse() async throws {
        let stub = StubAPIService()
        stub.sendResults = [sampleWishlistResponse(id: "w1")]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), userCreateId: "u1")

        let created = try await service.createWishlist(wishList: wishlist)

        #expect(created.id == "w1")
        #expect(stub.sentRoutes.count == 1)
        guard case .createWishlist(let body) = stub.sentRoutes[0] else {
            Issue.record("expected .createWishlist route")
            return
        }
        #expect(body.name == "Birthday")
    }

    @Test func createWishlistUploadsImagesForItemsThatHaveALocalImage() async throws {
        let stub = StubAPIService()
        let item = WishlistItem(id: "i1", name: "Lego", localImage: testImage())
        stub.sendResults = [
            sampleWishlistResponse(id: "w1"),
            WishlistItemResponse(id: "i1", wishlistId: "w1", name: "Lego", description: "", imageUrl: "https://x/y.jpg", isPicked: false, pickedBy: nil, itemLink: "", price: nil, isMostDesired: false)
        ]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), items: [item], userCreateId: "u1")

        let created = try await service.createWishlist(wishList: wishlist)

        #expect(created.id == "w1")
        #expect(stub.sentRoutes.count == 2)
        guard case .uploadItemImage(let wishlistId, let itemId, _) = stub.sentRoutes[1] else {
            Issue.record("expected .uploadItemImage route")
            return
        }
        #expect(wishlistId == "w1")
        #expect(itemId == "i1")
    }

    @Test func createWishlistSwallowsAFailedItemImageUpload() async throws {
        let stub = StubAPIService()
        let item = WishlistItem(id: "i1", name: "Lego", localImage: testImage())
        stub.sendResults = [
            sampleWishlistResponse(id: "w1"),
            APIError.transport("network down")
        ]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), items: [item], userCreateId: "u1")

        let created = try await service.createWishlist(wishList: wishlist)

        #expect(created.id == "w1")
    }

    @Test func createWishlistPropagatesAFailureFromTheInitialCreateCall() async throws {
        let stub = StubAPIService()
        stub.sendResults = [APIError.server(statusCode: 400, message: "Invalid item", code: nil)]
        let service = WishlistService(apiService: stub)
        let wishlist = WishlistModel(name: "Birthday", dueDate: Date(), userCreateId: "u1")

        do {
            _ = try await service.createWishlist(wishList: wishlist)
            Issue.record("expected an error to be thrown")
        } catch let error as APIError {
            #expect(error == .server(statusCode: 400, message: "Invalid item", code: nil))
        }
    }
}

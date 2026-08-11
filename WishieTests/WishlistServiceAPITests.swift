// WishieTests/WishlistServiceAPITests.swift
import Testing
import Foundation
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
}

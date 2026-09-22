// WishieTests/WishListInformationViewModelTests.swift
import Testing
import Foundation
import Combine
@testable import Wishie

@MainActor
@Suite
struct WishListInformationViewModelTests {
    @Test func joinPostsScannedCodeAndExposesJoinedWishlistId() async throws {
        let mockService = MockWishlistService()
        mockService.joinWishlistResult = .success("w1")
        let viewModel = WishListInformationViewModel(service: mockService)

        await viewModel.join(code: "abc123", wishlistId: "w1")

        #expect(mockService.joinedCodes == ["abc123"])
        #expect(viewModel.joinedWishlistId == "w1")
        #expect(viewModel.joinFailed == false)
        #expect(viewModel.isLoading == false)
    }

    @Test func joinFailureSurfacesErrorAndDoesNotNavigate() async throws {
        let mockService = MockWishlistService()
        mockService.joinWishlistResult = .failure(APIError.transport("no network"))
        let viewModel = WishListInformationViewModel(service: mockService)

        await viewModel.join(code: "abc123", wishlistId: "w1")

        #expect(viewModel.joinedWishlistId == nil)
        #expect(viewModel.joinFailed == true)
        #expect(viewModel.joinErrorMessage.isEmpty == false)
        #expect(viewModel.isLoading == false)
    }

    @Test func joinReportsARevokedInviteAsUnrecoverable() async throws {
        let mockService = MockWishlistService()
        mockService.joinWishlistResult = .failure(
            APIError.server(statusCode: 404, message: "Not found", code: nil)
        )
        let viewModel = WishListInformationViewModel(service: mockService)

        await viewModel.join(code: "abc123", wishlistId: "w1")

        // Retrying a revoked code can never succeed, so the copy must not invite a retry.
        #expect(viewModel.joinFailed == true)
        #expect(viewModel.joinErrorMessage.contains("no longer valid"))
    }

    /// A `200 { "success": false }` must not be reported as a join, or the user is navigated into
    /// a wishlist they aren't a member of and the detail fetch then 403s.
    @Test func joinTreatsAnUnsuccessfulBodyAsFailure() async throws {
        let mockService = MockWishlistService()
        mockService.joinWishlistResult = .failure(APIError.invalidResponse)
        let viewModel = WishListInformationViewModel(service: mockService)

        await viewModel.join(code: "abc123", wishlistId: "w1")

        #expect(viewModel.joinedWishlistId == nil)
        #expect(viewModel.joinFailed == true)
    }

    /// `joinedWishlistId` drives navigation via `onChange`. If a second join resolves to the same
    /// id without the value first going back to `nil`, no change is published and the Join button
    /// becomes permanently inert.
    @Test func joinClearsPreviousNavigationStateSoARepeatJoinStillFires() async throws {
        let mockService = MockWishlistService()
        mockService.joinWishlistResult = .success("w1")
        let viewModel = WishListInformationViewModel(service: mockService)

        await viewModel.join(code: "abc123", wishlistId: "w1")
        #expect(viewModel.joinedWishlistId == "w1")

        var observedTransitionThroughNil = false
        mockService.joinWishlistResult = .success("w1")
        let cancellable = viewModel.$joinedWishlistId.sink { value in
            if value == nil { observedTransitionThroughNil = true }
        }
        await viewModel.join(code: "abc123", wishlistId: "w1")
        cancellable.cancel()

        #expect(observedTransitionThroughNil)
        #expect(viewModel.joinedWishlistId == "w1")
    }

    @Test func joinTreatsAlreadyAMemberAsSuccess() async throws {
        let mockService = MockWishlistService()
        mockService.joinWishlistResult = .failure(
            APIError.server(statusCode: 409, message: "Already a member", code: nil)
        )
        let viewModel = WishListInformationViewModel(service: mockService)

        await viewModel.join(code: "abc123", wishlistId: "w1")

        #expect(viewModel.joinedWishlistId == "w1")
        #expect(viewModel.joinFailed == false)
    }
}

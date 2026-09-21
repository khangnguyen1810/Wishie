// WishieTests/ScanQRScreenViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

@MainActor
@Suite
struct ScanQRScreenViewModelTests {
    @Test func handleResultExtractsWishlistIdOnValidJoinURL() async throws {
        let mockService = MockWishlistService()
        mockService.getWishlistInfoByCodeResult = .success(
            WishlistInfoResponse(id: "w1", name: "Birthday", description: "", dueDate: "", colorTheme: nil, itemCount: 0)
        )
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult("https://wishie-web.vercel.app/join/abc123")

        #expect(viewModel.result == "w1")
        #expect(viewModel.showError == false)
        #expect(viewModel.shouldRestartScanning == false)
    }

    @Test func handleResultRejectsWrongScheme() async throws {
        let mockService = MockWishlistService()
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult("wishie://wishlist?data=abc")

        #expect(viewModel.showError == true)
        #expect(viewModel.errorTitle == "Invalid URL")
        #expect(viewModel.shouldRestartScanning == true)
    }

    @Test func handleResultRejectsWrongHost() async throws {
        let mockService = MockWishlistService()
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult("https://evil.example.com/join/abc123")

        #expect(viewModel.showError == true)
        #expect(viewModel.shouldRestartScanning == true)
    }

    @Test func handleResultRejectsMissingCode() async throws {
        let mockService = MockWishlistService()
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult("https://wishie-web.vercel.app/join/")

        #expect(viewModel.showError == true)
        #expect(viewModel.shouldRestartScanning == true)
    }

    @Test func handleResultSurfacesServiceFailureAndAllowsRescan() async throws {
        let mockService = MockWishlistService()
        mockService.getWishlistInfoByCodeResult = .failure(APIError.transport("no network"))
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult("https://wishie-web.vercel.app/join/abc123")

        #expect(viewModel.result == "")
        #expect(viewModel.showError == true)
        #expect(viewModel.errorTitle == "Can't get wishlist info")
        #expect(viewModel.shouldRestartScanning == true)
        #expect(viewModel.isScanning == false)
    }
}

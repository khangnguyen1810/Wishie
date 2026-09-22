// WishieTests/ScanQRScreenViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

@MainActor
@Suite
struct ScanQRScreenViewModelTests {
    private func joinURL(code: String) -> String {
        "https://\(WishieLinks.joinHost)/join/\(code)"
    }

    @Test func handleResultBuildsPreviewOnValidJoinURL() async throws {
        let mockService = MockWishlistService()
        mockService.getWishlistInfoByCodeResult = .success(
            WishlistInfoResponse(
                id: "w1",
                name: "Birthday",
                description: "",
                dueDate: "",
                colorTheme: nil,
                itemCount: 7,
                ownerName: "Ann"
            )
        )
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult(joinURL(code: "abc123"))

        #expect(viewModel.preview?.id == "w1")
        // The scanned invite code, not the wishlist id, is what `POST /wishlists/join/:code` needs.
        #expect(viewModel.preview?.code == "abc123")
        // ...and it must be the code that actually reaches the preview request.
        #expect(mockService.previewedCodes == ["abc123"])
        #expect(viewModel.preview?.itemCount == 7)
        #expect(viewModel.preview?.ownerName == "Ann")
        #expect(viewModel.showError == false)
        #expect(viewModel.shouldRestartScanning == false)
    }

    @Test func handleResultRejectsWrongScheme() async throws {
        let viewModel = ScanQRScreenViewModel(wishlistService: MockWishlistService())

        await viewModel.handleResult("wishie://wishlist?data=abc")

        #expect(viewModel.showError == true)
        #expect(viewModel.errorTitle == "Invalid URL")
    }

    @Test func handleResultRejectsWrongHost() async throws {
        let viewModel = ScanQRScreenViewModel(wishlistService: MockWishlistService())

        await viewModel.handleResult("https://evil.example.com/join/abc123")

        #expect(viewModel.showError == true)
    }

    @Test func handleResultRejectsMissingCode() async throws {
        let viewModel = ScanQRScreenViewModel(wishlistService: MockWishlistService())

        await viewModel.handleResult(joinURL(code: ""))

        #expect(viewModel.showError == true)
    }

    @Test func handleResultSurfacesServiceFailure() async throws {
        let mockService = MockWishlistService()
        mockService.getWishlistInfoByCodeResult = .failure(APIError.transport("no network"))
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult(joinURL(code: "abc123"))

        #expect(viewModel.preview == nil)
        #expect(viewModel.showError == true)
        #expect(viewModel.errorTitle == "Can't get wishlist info")
        #expect(viewModel.isScanning == false)
    }

    @Test func handleResultCallsOutRevokedInviteSeparately() async throws {
        let mockService = MockWishlistService()
        mockService.getWishlistInfoByCodeResult = .failure(
            APIError.server(statusCode: 404, message: "Not found", code: nil)
        )
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult(joinURL(code: "abc123"))

        // A revoked code will never start working, so the copy must not say "try again".
        #expect(viewModel.errorTitle == "Invite no longer valid")
    }

    /// The scanner stops on every decoded frame. Restarting it while the dialog is still up fed
    /// the same bad QR straight back in, so the restart must wait for the dismissal.
    @Test func restartIsRequestedOnlyAfterTheErrorDialogIsDismissed() async throws {
        let viewModel = ScanQRScreenViewModel(wishlistService: MockWishlistService())

        await viewModel.handleResult("https://evil.example.com/join/abc123")
        #expect(viewModel.shouldRestartScanning == false)

        viewModel.didDismissError()
        #expect(viewModel.shouldRestartScanning == true)
    }

    /// Without clearing `preview`, re-scanning the same code produces an identical value, the
    /// view's `onChange` never fires, and the screen silently does nothing.
    @Test func rescanningTheSameCodeProducesAFreshPreview() async throws {
        let mockService = MockWishlistService()
        let viewModel = ScanQRScreenViewModel(wishlistService: mockService)

        await viewModel.handleResult(joinURL(code: "abc123"))
        #expect(viewModel.preview != nil)

        viewModel.didNavigateToPreview()
        #expect(viewModel.preview == nil)

        await viewModel.handleResult(joinURL(code: "abc123"))
        #expect(viewModel.preview != nil)
        #expect(mockService.previewedCodes == ["abc123", "abc123"])
    }
}

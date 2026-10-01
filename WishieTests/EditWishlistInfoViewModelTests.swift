// WishieTests/EditWishlistInfoViewModelTests.swift
import Testing
import Foundation
@testable import Wishie

@MainActor
struct EditWishlistInfoViewModelTests {
    @Test func saveMarksDidSaveOnSuccess() async {
        let mock = MockWishlistService()
        let viewModel = EditWishlistInfoViewModel(service: mock)

        await viewModel.save(wishlistId: "w1")

        #expect(mock.updatedWishlistIds == ["w1"])
        #expect(viewModel.didSave)
        #expect(viewModel.isShowError == false)
        #expect(viewModel.isLoading == false)
    }

    @Test func saveShowsTheServerMessageOnAValidationFailure() async {
        let mock = MockWishlistService()
        mock.updateWishlistInfoResult = .failure(.server(statusCode: 400, message: "name must not be empty", error: "Bad Request"))
        let viewModel = EditWishlistInfoViewModel(service: mock)

        await viewModel.save(wishlistId: "w1")

        #expect(viewModel.didSave == false)
        #expect(viewModel.isShowError)
        #expect(viewModel.errorMsg == "name must not be empty")
    }

    @Test func saveShowsAWishlistNotFoundMessageOn404() async {
        let mock = MockWishlistService()
        mock.updateWishlistInfoResult = .failure(.server(statusCode: 404, message: "Wishlist w1 not found", error: "Not Found"))
        let viewModel = EditWishlistInfoViewModel(service: mock)

        await viewModel.save(wishlistId: "w1")

        #expect(viewModel.isShowError)
        #expect(viewModel.errorMsg == EditWishlistInfoViewModel.notFoundMessage)
    }

    /// Errors without a status code (offline, expired session, ...) previously left the dialog
    /// body empty.
    @Test func saveShowsAMessageForAnErrorWithoutAStatusCode() async {
        let mock = MockWishlistService()
        mock.updateWishlistInfoResult = .failure(.transport("The Internet connection appears to be offline."))
        let viewModel = EditWishlistInfoViewModel(service: mock)

        await viewModel.save(wishlistId: "w1")

        #expect(viewModel.isShowError)
        #expect(viewModel.errorMsg == "The Internet connection appears to be offline.")
    }

    @Test func aLaterFailureReplacesTheEarlierErrorMessage() async {
        let mock = MockWishlistService()
        mock.updateWishlistInfoResult = .failure(.server(statusCode: 400, message: "name must not be empty"))
        let viewModel = EditWishlistInfoViewModel(service: mock)
        await viewModel.save(wishlistId: "w1")

        mock.updateWishlistInfoResult = .failure(.sessionExpired)
        await viewModel.save(wishlistId: "w1")

        #expect(viewModel.errorMsg == WishieError.sessionExpired.message)
    }
}

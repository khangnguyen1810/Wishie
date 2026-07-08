//
//  AuthViewModelGoogleLoginTests.swift
//  WishieTests
//

import Testing
import UIKit
import Combine
@testable import Wishie

struct AuthViewModelGoogleLoginTests {
    private struct SampleError: LocalizedError {
        var errorDescription: String? { "network unreachable" }
    }

    @Test func failureShowsErrorDialogWithMessage() async throws {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = Fail(error: SampleError()).eraseToAnyPublisher()
        let viewModel = AuthViewModel(authService: mockService)

        viewModel.loginWithGoogle(presentingViewController: UIViewController())
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isShowError == true)
        #expect(viewModel.errorTitle == "Google Login Failed")
        #expect(viewModel.errorMessage == "network unreachable")
        #expect(viewModel.isShowProgress == false)
    }

    @Test func cancelDoesNotShowErrorDialog() async throws {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = Fail(
            error: NSError(domain: "com.google.GIDSignIn", code: -5)
        ).eraseToAnyPublisher()
        let viewModel = AuthViewModel(authService: mockService)

        viewModel.loginWithGoogle(presentingViewController: UIViewController())
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isShowError == false)
        #expect(viewModel.isShowProgress == false)
    }

    @Test func settingLoginInProgressShowsProgressImmediately() {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = Empty().eraseToAnyPublisher()
        let viewModel = AuthViewModel(authService: mockService)

        viewModel.loginWithGoogle(presentingViewController: UIViewController())

        #expect(viewModel.isShowProgress == true)
    }
}

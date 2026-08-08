//
//  AuthViewModelGoogleLoginTests.swift
//  WishieTests
//

import Testing
import UIKit
@testable import Wishie

struct AuthViewModelGoogleLoginTests {
    private struct SampleError: LocalizedError {
        var errorDescription: String? { "network unreachable" }
    }

    @Test func failureShowsErrorDialogWithMessage() async throws {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = .failure(SampleError())
        let viewModel = AuthViewModel(authService: mockService, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        viewModel.loginWithGoogle(presentingViewController: UIViewController())
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isShowError == true)
        #expect(viewModel.errorTitle == "Google Login Failed")
        #expect(viewModel.errorMessage == "network unreachable")
        #expect(viewModel.isShowProgress == false)
    }

    @Test func cancelDoesNotShowErrorDialog() async throws {
        let mockService = MockAuthenticateService()
        mockService.loginWithGoogleResult = .failure(NSError(domain: "com.google.GIDSignIn", code: -5))
        let viewModel = AuthViewModel(authService: mockService, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        viewModel.loginWithGoogle(presentingViewController: UIViewController())
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isShowError == false)
        #expect(viewModel.isShowProgress == false)
    }

    @Test func settingLoginInProgressShowsProgressImmediately() {
        let mockService = MockAuthenticateService()
        let viewModel = AuthViewModel(authService: mockService, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        viewModel.loginWithGoogle(presentingViewController: UIViewController())

        #expect(viewModel.isShowProgress == true)
    }
}

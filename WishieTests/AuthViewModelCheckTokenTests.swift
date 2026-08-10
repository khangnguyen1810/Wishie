//
//  AuthViewModelCheckTokenTests.swift
//  WishieTests
//

import Testing
import Foundation
@testable import Wishie

struct AuthViewModelCheckTokenTests {
    private func sampleSession(userId: String = "u1", email: String = "user@example.com") -> AuthSession {
        AuthSession(accessToken: "a", refreshToken: "r", userId: userId, email: email)
    }

    /// A transient error (offline, decode failure, unexpected 5xx) must not wipe a valid stored
    /// session — only a confirmed-invalid session (APIError.sessionExpired) should trigger a clear.
    @Test func transportErrorDuringCheckTokenLeavesStoredSessionIntact() async throws {
        let mockService = MockAuthenticateService()
        mockService.getUserInfoError = APIError.transport("offline")
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        let session = sampleSession()
        await sessionStore.save(session)

        let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore)
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isLoggedIn == false)
        let stored = await sessionStore.current()
        #expect(stored == session)
    }

    /// A confirmed-expired session should still be cleared and the user logged out.
    @Test func sessionExpiredErrorDuringCheckTokenClearsStoredSession() async throws {
        let mockService = MockAuthenticateService()
        mockService.getUserInfoError = APIError.sessionExpired
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        await sessionStore.save(sampleSession())

        let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore)
        try await Task.sleep(for: .milliseconds(200))

        #expect(viewModel.isLoggedIn == false)
        let stored = await sessionStore.current()
        #expect(stored == nil)
    }
}

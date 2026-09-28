//
//  AuthViewModelCheckTokenTests.swift
//  WishieTests
//

import Testing
import Foundation
@testable import Wishie

extension UserDefaultsSharingTests {
    /// The logged-in paths write the device userId into `UserDefaults.standard`, which other suites
    /// (e.g. `WishlistModel.isOwner()`) read — so this suite runs serialized with them and cleans up.
    final class AuthViewModelCheckTokenTests {
        deinit {
            UserDefaults.standard.removeObject(forKey: WishieConstants.userIdKey)
        }

        private func sampleSession(userId: String = "u1", email: String = "user@example.com") -> AuthSession {
            AuthSession(accessToken: "a", refreshToken: "r", userId: userId, email: email)
        }

        private func sampleProfile(firstName: String = "Cached") -> UserModel {
            var user = UserModel()
            user.firstName = firstName
            user.email = "user@example.com"
            return user
        }

        /// Each test gets its own UserDefaults suite so a profile cached by the host app (or another
        /// test) never leaks into the launch-state assertions.
        private func makeProfileCache() -> UserProfileCache {
            UserProfileCache(defaults: UserDefaults(suiteName: "AuthViewModelCheckTokenTests.\(UUID().uuidString)")!)
        }

        /// Polls instead of a fixed sleep: under parallel simulator clones checkToken()'s background
        /// Task can take well over 200ms to land.
        private func waitUntil(timeout: Duration = .seconds(5), _ condition: () -> Bool) async throws {
            let deadline = ContinuousClock.now + timeout
            while !condition(), ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(20))
            }
        }

        /// A transient error (offline, decode failure, unexpected 5xx) must not wipe a valid stored
        /// session — only a confirmed-invalid session (APIError.sessionExpired) should trigger a clear.
        @Test func transportErrorDuringCheckTokenLeavesStoredSessionIntact() async throws {
            let mockService = MockAuthenticateService()
            mockService.getUserInfoError = APIError.transport("offline")
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            let session = sampleSession()
            await sessionStore.save(session)

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: makeProfileCache())
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

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: makeProfileCache())
            try await Task.sleep(for: .milliseconds(200))

            #expect(viewModel.isLoggedIn == false)
            let stored = await sessionStore.current()
            #expect(stored == nil)
        }

        /// Stored tokens + cached profile → logged in synchronously in init, before any API call,
        /// so the root coordinator opens Home immediately.
        @Test func storedSessionAndCachedProfileLogsInImmediately() async throws {
            let mockService = MockAuthenticateService()
            mockService.getUserInfoError = APIError.transport("offline")
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)

            #expect(viewModel.isLoggedIn == true)
            #expect(viewModel.userInfo.firstName == "Cached")
        }

        /// Offline at launch with a cached profile keeps the user logged in on the cached data.
        @Test func transportErrorWithCachedProfileStaysLoggedIn() async throws {
            let mockService = MockAuthenticateService()
            mockService.getUserInfoError = APIError.transport("offline")
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            try await Task.sleep(for: .milliseconds(200))

            #expect(viewModel.isLoggedIn == true)
            #expect(cache.load()?.firstName == "Cached")
        }

        /// The background refresh replaces the cached profile with the server's copy.
        @Test func successfulCheckTokenRefreshesCachedProfile() async throws {
            let mockService = MockAuthenticateService()
            mockService.userToReturn = sampleProfile(firstName: "Fresh")
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            try await waitUntil { viewModel.userInfo.firstName == "Fresh" }

            #expect(viewModel.isLoggedIn == true)
            #expect(viewModel.userInfo.firstName == "Fresh")
            #expect(cache.load()?.firstName == "Fresh")
        }

        /// A confirmed-expired session sends a cached user back to login and drops the cached profile.
        @Test func sessionExpiredWithCachedProfileLogsOutAndClearsCache() async throws {
            let mockService = MockAuthenticateService()
            mockService.getUserInfoError = APIError.sessionExpired
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            try await waitUntil { !viewModel.isLoggedIn }

            #expect(viewModel.isLoggedIn == false)
            #expect(cache.load() == nil)
            let stored = await sessionStore.current()
            #expect(stored == nil)
        }

        /// A cached profile without tokens is not a login — show the login/sign-up screen.
        @Test func cachedProfileWithoutSessionIsNotLoggedIn() async throws {
            let mockService = MockAuthenticateService()
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            try await Task.sleep(for: .milliseconds(200))

            #expect(viewModel.isLoggedIn == false)
        }

        /// Upgrade path (Option A): tokens but no cached profile → wait for /profiles/me, then log in
        /// and cache the profile so the next launch is instant.
        @Test func storedSessionWithoutCachedProfileLogsInAfterFetchAndCaches() async throws {
            let mockService = MockAuthenticateService()
            mockService.userToReturn = sampleProfile(firstName: "Fetched")
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            #expect(viewModel.isLoggedIn == false)
            try await waitUntil { viewModel.isLoggedIn }

            #expect(viewModel.isLoggedIn == true)
            #expect(cache.load()?.firstName == "Fetched")
        }

        @Test func logOutClearsCachedProfile() async throws {
            let mockService = MockAuthenticateService()
            mockService.userToReturn = sampleProfile(firstName: "Fresh")
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            // Let the launch refresh land first so it can't race the logout below.
            try await waitUntil { viewModel.userInfo.firstName == "Fresh" }
            viewModel.logOut()
            try await waitUntil { !viewModel.isLoggedIn }

            #expect(viewModel.isLoggedIn == false)
            #expect(cache.load() == nil)
        }

        /// A launch refresh that lands after the user logged out must not log them back in or
        /// re-cache their profile.
        @Test func lateCheckTokenResponseAfterLogOutDoesNotResurrectLogin() async throws {
            let mockService = MockAuthenticateService()
            mockService.userToReturn = sampleProfile(firstName: "Fresh")
            mockService.getUserInfoDelay = .milliseconds(300)
            let sessionStore = SessionStore(keychain: InMemoryKeychain())
            await sessionStore.save(sampleSession())
            let cache = makeProfileCache()
            cache.save(sampleProfile())

            let viewModel = AuthViewModel(authService: mockService, sessionStore: sessionStore, profileCache: cache)
            viewModel.logOut()
            try await waitUntil { !viewModel.isLoggedIn }
            // Outlast the delayed /profiles/me response.
            try await Task.sleep(for: .milliseconds(800))

            #expect(viewModel.isLoggedIn == false)
            #expect(viewModel.userInfo.firstName != "Fresh")
            #expect(cache.load() == nil)
        }
    }
}

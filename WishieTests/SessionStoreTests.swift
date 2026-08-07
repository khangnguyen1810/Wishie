import Testing
import Foundation
@testable import Wishie

struct SessionStoreTests {
    private func sampleSession(accessToken: String = "a", refreshToken: String = "r") -> AuthSession {
        AuthSession(accessToken: accessToken, refreshToken: refreshToken, userId: "u1", email: "user@example.com")
    }

    @Test func savedSessionIsReturnedByCurrent() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        let session = sampleSession()

        await store.save(session)
        let loaded = await store.current()

        #expect(loaded == session)
    }

    @Test func currentReturnsNilWhenNothingSaved() async {
        let store = SessionStore(keychain: InMemoryKeychain())

        let loaded = await store.current()

        #expect(loaded == nil)
    }

    @Test func clearRemovesTheSession() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())

        await store.clear()
        let loaded = await store.current()

        #expect(loaded == nil)
    }

    @Test func refreshedSessionPersistsTheNewSession() async throws {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())
        let newSession = sampleSession(accessToken: "new", refreshToken: "new-refresh")

        let result = try await store.refreshedSession { _ in newSession }

        #expect(result == newSession)
        let stored = await store.current()
        #expect(stored == newSession)
    }

    @Test func concurrentRefreshCallsShareOneInFlightAttempt() async throws {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())

        actor CallCounter {
            private(set) var count = 0
            func increment() { count += 1 }
        }
        let counter = CallCounter()
        let newSession = sampleSession(accessToken: "new", refreshToken: "new-refresh")

        async let first = store.refreshedSession { _ in
            await counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return newSession
        }
        async let second = store.refreshedSession { _ in
            await counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return newSession
        }
        _ = try await (first, second)

        let callCount = await counter.count
        #expect(callCount == 1)
    }

    @Test func concurrentRefreshFailureIsUniformlySessionExpiredForAllCallers() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())
        struct SampleError: Error {}

        actor CallCounter {
            private(set) var count = 0
            func increment() { count += 1 }
        }
        let counter = CallCounter()

        async let first: Void = {
            do {
                _ = try await store.refreshedSession { _ in
                    await counter.increment()
                    try await Task.sleep(for: .milliseconds(50))
                    throw SampleError()
                }
                Issue.record("expected refreshedSession to throw")
            } catch let error as APIError {
                #expect(error == .sessionExpired)
            } catch {
                Issue.record("unexpected error type from first caller: \(error)")
            }
        }()
        async let second: Void = {
            do {
                _ = try await store.refreshedSession { _ in
                    await counter.increment()
                    try await Task.sleep(for: .milliseconds(50))
                    throw SampleError()
                }
                Issue.record("expected refreshedSession to throw")
            } catch let error as APIError {
                #expect(error == .sessionExpired)
            } catch {
                Issue.record("unexpected error type from second caller: \(error)")
            }
        }()
        _ = await (first, second)

        let callCount = await counter.count
        #expect(callCount == 1)

        let loaded = await store.current()
        #expect(loaded == nil)
    }

    @Test func refreshFailureClearsTheStoredSession() async {
        let store = SessionStore(keychain: InMemoryKeychain())
        await store.save(sampleSession())
        struct SampleError: Error {}

        do {
            _ = try await store.refreshedSession { _ in throw SampleError() }
            Issue.record("expected refreshedSession to throw")
        } catch {
            // expected
        }

        let loaded = await store.current()
        #expect(loaded == nil)
    }

    @Test func refreshWithNoStoredSessionThrowsSessionExpired() async {
        let store = SessionStore(keychain: InMemoryKeychain())

        do {
            _ = try await store.refreshedSession { _ in
                Issue.record("refresher should not be called with no stored session")
                throw APIError.sessionExpired
            }
            Issue.record("expected sessionExpired to be thrown")
        } catch let error as APIError {
            #expect(error == .sessionExpired)
        } catch {
            Issue.record("unexpected error type: \(error)")
        }
    }
}

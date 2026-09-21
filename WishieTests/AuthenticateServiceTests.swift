import Testing
import Foundation
import UIKit
@testable import Wishie

/// Records the arguments `AuthenticateService` passes to the injected `AuthUserDocumentBridging`,
/// so tests can verify the signup/Google-login flows call it with the right data without touching
/// a real Firestore instance (see `Fix 1` in the PR review: `WishlistService.getWishlist(by:)` reads
/// `users/{id}` and needs this bridging document to exist for newly created accounts).
final class SpyAuthUserDocumentBridge: AuthUserDocumentBridging, @unchecked Sendable {
    struct Call: Equatable {
        let userId: String
        let firstName: String
        let lastName: String
        let email: String
        let phone: String
    }
    private(set) var calls: [Call] = []

    func writeIfNeeded(userId: String, firstName: String, lastName: String, email: String, phone: String, dateOfBirth: Date) async {
        calls.append(Call(userId: userId, firstName: firstName, lastName: lastName, email: email, phone: phone))
    }
}

struct AuthenticateServiceTests {
    private func sampleSession(userId: String = "u1", email: String = "user@example.com") -> AuthSession {
        AuthSession(accessToken: "a", refreshToken: "r", userId: userId, email: email)
    }

    private func sampleProfile(id: String = "u1", firstName: String = "Ada", lastName: String = "Lovelace", email: String = "ada@example.com", interests: [String] = [], hasCompletedInterestsSetup: Bool = false, dateOfBirth: String? = "1990-01-01") -> ProfileResponse {
        ProfileResponse(id: id, firstName: firstName, lastName: lastName, email: email, phone: "123", dateOfBirth: dateOfBirth, avatarUrl: nil, interests: interests, hasCompletedInterestsSetup: hasCompletedInterestsSetup, createdAt: "2026-01-01T00:00:00.000Z")
    }

    @Test func signUpSendsRequestAndPersistsSession() async throws {
        let stubClient = StubAPIClient()
        let session = sampleSession(email: "new@example.com")
        stubClient.sendResults = [session]
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        // Inject a no-op bridge: the real FirestoreAuthUserDocumentBridge would make a live network
        // call here (this test target runs inside the app host process, which configures a real
        // FirebaseApp — see TEST_HOST in the Xcode project), which would make this test slow and
        // network-dependent for behavior this test isn't about.
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore, userDocumentBridge: NoOpAuthUserDocumentBridge())
        let request = SignUpRequest(firstName: "A", lastName: "B", email: "new@example.com", phone: "123", password: "password1", dateOfBirth: Date())

        let result = try await service.signUp(request)

        #expect(result == session)
        #expect(stubClient.sentEndpoints.first?.path == "/auth/signup")
        let stored = await sessionStore.current()
        #expect(stored == session)
    }

    @Test func signUpWritesTheBridgingFirestoreUserDocument() async throws {
        let stubClient = StubAPIClient()
        let session = sampleSession(userId: "new-user-uuid", email: "new@example.com")
        stubClient.sendResults = [session]
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        let spyBridge = SpyAuthUserDocumentBridge()
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore, userDocumentBridge: spyBridge)
        let request = SignUpRequest(firstName: "A", lastName: "B", email: "new@example.com", phone: "123", password: "password1", dateOfBirth: Date())

        _ = try await service.signUp(request)

        #expect(spyBridge.calls == [SpyAuthUserDocumentBridge.Call(userId: "new-user-uuid", firstName: "A", lastName: "B", email: "new@example.com", phone: "123")])
    }

    @Test func loginSendsCredentialsAndPersistsSession() async throws {
        let stubClient = StubAPIClient()
        let session = sampleSession()
        stubClient.sendResults = [session]
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore)

        let result = try await service.login("user@example.com", "password1")

        #expect(result == session)
        #expect(stubClient.sentEndpoints.first?.path == "/auth/login")
        let stored = await sessionStore.current()
        #expect(stored == session)
    }

    @Test func resetPasswordReturnsTheServerSuccessFlag() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [ResetPasswordResponse(success: true)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result = try await service.resetPassword("user@example.com")

        #expect(result == true)
        #expect(stubClient.sentEndpoints.first?.path == "/auth/reset-password")
    }

    @Test func logoutClearsSessionEvenWhenTheNetworkCallFails() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendNoContentError = APIError.transport("offline")
        let sessionStore = SessionStore(keychain: InMemoryKeychain())
        await sessionStore.save(sampleSession())
        let service = AuthenticateService(apiClient: stubClient, sessionStore: sessionStore)

        try await service.logout()

        let stored = await sessionStore.current()
        #expect(stored == nil)
    }

    @Test func logoutDoesNothingWhenThereIsNoStoredSession() async throws {
        let stubClient = StubAPIClient()
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await service.logout()

        #expect(stubClient.sentEndpoints.isEmpty)
    }

    @Test func getUserInfoMapsProfileResponseToUserModel() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile(interests: ["gaming"], hasCompletedInterestsSetup: true)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result = try await service.getUserInfo()

        #expect(result?.firstName == "Ada")
        #expect(result?.interests == ["gaming"])
        #expect(result?.hasCompletedInterestsSetup == true)
        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me")
    }

    @Test func getUserInfoByIdRequestsTheSpecificProfile() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile(id: "u2", firstName: "Grace", lastName: "Hopper", email: "grace@example.com", dateOfBirth: nil)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        let result = try await service.getUserInfo(by: "u2")

        #expect(result?.firstName == "Grace")
        #expect(stubClient.sentEndpoints.first?.path == "/profiles/u2")
    }

    @Test func updateUserInfoSendsAPatchToProfilesMe() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile()]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await service.updateUserInfo(userId: "u1", firstName: "Ada", lastName: "Lovelace", phone: "999", dateOfBirth: Date())

        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me")
        #expect(stubClient.sentEndpoints.first?.method == "PATCH")
    }

    @Test func updateUserInterestsSendsAPatchToProfilesMeInterests() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [sampleProfile(interests: ["books"], hasCompletedInterestsSetup: true)]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))

        try await service.updateUserInterests(userId: "u1", interests: ["books"])

        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me/interests")
        #expect(stubClient.sentEndpoints.first?.method == "PATCH")
    }

    @Test func uploadAvatarSendsMultipartRequestAndReturnsTheURL() async throws {
        let stubClient = StubAPIClient()
        stubClient.sendResults = [AvatarUploadResponse(avatarUrl: "https://cdn.example.com/avatar/u1.jpg?t=1")]
        let service = AuthenticateService(apiClient: stubClient, sessionStore: SessionStore(keychain: InMemoryKeychain()))
        let image = UIImage(systemName: "person.fill")!

        let url = try await service.uploadAvatar(image: image, userId: "u1")

        #expect(url == "https://cdn.example.com/avatar/u1.jpg?t=1")
        #expect(stubClient.sentEndpoints.first?.path == "/profiles/me/avatar")
    }
}

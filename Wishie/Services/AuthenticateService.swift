//
//  AuthenticateService.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 13/10/25.
//

import Foundation
import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore

struct ResetPasswordResponse: Decodable {
    let success: Bool
}

struct AvatarUploadResponse: Decodable {
    let avatarUrl: String
}

/// Bridges account creation on the new REST backend to the legacy Firestore `users/{id}` document
/// that `WishlistService.getWishlist(by:)` still reads (see `UserModel.init(dictionary:)`).
/// This is a deliberate, minimal shim until `WishlistService` itself migrates off Firestore — not
/// a redesign. Injectable so unit tests (which run inside the app host process with a real
/// `FirebaseApp` configured — see `TEST_HOST` in the Xcode project) can substitute a no-op and
/// avoid making live Firestore network calls as a side effect of testing REST-facing behavior.
protocol AuthUserDocumentBridging {
    func writeIfNeeded(userId: String, firstName: String, lastName: String, email: String, phone: String, dateOfBirth: Date) async
}

struct FirestoreAuthUserDocumentBridge: AuthUserDocumentBridging {
    /// Only writes when no document already exists, so it never clobbers existing data (mirrors the
    /// pre-migration Google-login flow's `guard !snapshot.exists` pattern).
    /// A failure here is logged but never surfaces to the caller: the REST signup/login has already
    /// succeeded and the user's account is valid, so a Firestore hiccup must not block auth.
    func writeIfNeeded(userId: String, firstName: String, lastName: String, email: String, phone: String, dateOfBirth: Date) async {
        // Firestore.firestore() traps if no default FirebaseApp has been configured. Guard so this
        // bridge is a no-op in that case instead of crashing.
        guard FirebaseApp.app() != nil else {
            print("AuthenticateService: skipping bridging Firestore user document for \(userId) — no FirebaseApp configured.")
            return
        }
        do {
            let userRef = Firestore.firestore().collection(WishieConstants.firebaseUserPath).document(userId)
            let snapshot = try await userRef.getDocument()
            guard !snapshot.exists else { return }
            let userData: [String: Any] = [
                "uid": userId,
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "phone": phone,
                "dateOfBirth": Timestamp(date: dateOfBirth),
                "avatarUrl": NSNull(),
                "interests": [],
                "hasCompletedInterestsSetup": false,
            ]
            try await userRef.setData(userData)
        } catch {
            print("AuthenticateService: failed to write bridging Firestore user document for \(userId): \(error.localizedDescription)")
        }
    }
}

/// Test-only no-op bridge lives here (not in the test target) so it stays alongside the protocol it
/// implements; `AuthenticateService`'s default argument keeps production behavior unchanged.
struct NoOpAuthUserDocumentBridge: AuthUserDocumentBridging {
    func writeIfNeeded(userId: String, firstName: String, lastName: String, email: String, phone: String, dateOfBirth: Date) async {}
}

protocol AuthenticateServiceProtocol {
    func signUp(_ request: SignUpRequest) async throws -> AuthSession
    func login(_ email: String, _ password: String) async throws -> AuthSession
    func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession
    func resetPassword(_ email: String) async throws -> Bool
    func logout() async throws
    func getUserInfo() async throws -> UserModel?
    func getUserInfo(by userId: String) async throws -> UserModel?
    func uploadAvatar(image: UIImage, userId: String) async throws -> String
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date) async throws
    func updateUserInterests(userId: String, interests: [String]) async throws
}

final class AuthenticateService: AuthenticateServiceProtocol {
    private let apiClient: APIClientProtocol
    private let sessionStore: SessionStore
    private let userDocumentBridge: AuthUserDocumentBridging

    init(apiClient: APIClientProtocol = APIClient(), sessionStore: SessionStore = .shared, userDocumentBridge: AuthUserDocumentBridging = FirestoreAuthUserDocumentBridge()) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.userDocumentBridge = userDocumentBridge
    }

    func signUp(_ request: SignUpRequest) async throws -> AuthSession {
        struct RequestBody: Encodable {
            let email: String
            let password: String
            let firstName: String
            let lastName: String
            let phone: String
            let dateOfBirth: String
        }
        let body = RequestBody(
            email: request.email,
            password: request.password,
            firstName: request.firstName,
            lastName: request.lastName,
            phone: request.phone,
            dateOfBirth: WishieDateFormatting.dateOnly.string(from: request.dateOfBirth)
        )
        let json = try JSONEncoder().encode(body)
        let session: AuthSession = try await apiClient.send(.post("/auth/signup", json: json))
        await sessionStore.save(session)
        await userDocumentBridge.writeIfNeeded(
            userId: session.userId,
            firstName: request.firstName,
            lastName: request.lastName,
            email: request.email,
            phone: request.phone,
            dateOfBirth: request.dateOfBirth
        )
        return session
    }

    func login(_ email: String, _ password: String) async throws -> AuthSession {
        struct RequestBody: Encodable { let email: String; let password: String }
        let json = try JSONEncoder().encode(RequestBody(email: email, password: password))
        let session: AuthSession = try await apiClient.send(.post("/auth/login", json: json))
        await sessionStore.save(session)
        return session
    }

    func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession {
        let signInResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result else {
                    continuation.resume(throwing: NSError(domain: "GoogleSignInError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sign-in result is nil."]))
                    return
                }
                continuation.resume(returning: result)
            }
        }
        guard let serverAuthCode = signInResult.serverAuthCode else {
            throw NSError(domain: "GoogleSignInError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Missing Google server auth code."])
        }
        struct RequestBody: Encodable {
            let code: String
            let platform: String
            let firstName: String?
            let lastName: String?
        }
        let profile = signInResult.user.profile
        let body = RequestBody(code: serverAuthCode, platform: "mobile", firstName: profile?.givenName, lastName: profile?.familyName)
        let json = try JSONEncoder().encode(body)
        let session: AuthSession = try await apiClient.send(.post("/auth/google", json: json))
        await sessionStore.save(session)
        await userDocumentBridge.writeIfNeeded(
            userId: session.userId,
            firstName: profile?.givenName ?? "",
            lastName: profile?.familyName ?? "",
            email: session.email,
            phone: "",
            dateOfBirth: Date()
        )
        return session
    }

    func resetPassword(_ email: String) async throws -> Bool {
        struct RequestBody: Encodable { let email: String }
        let json = try JSONEncoder().encode(RequestBody(email: email))
        let response: ResetPasswordResponse = try await apiClient.send(.post("/auth/reset-password", json: json))
        return response.success
    }

    func logout() async throws {
        if let accessToken = await sessionStore.current()?.accessToken {
            struct RequestBody: Encodable { let accessToken: String }
            if let json = try? JSONEncoder().encode(RequestBody(accessToken: accessToken)) {
                _ = try? await apiClient.sendNoContent(.post("/auth/logout", json: json, requiresAuth: false))
            }
        }
        await sessionStore.clear()
    }

    func getUserInfo() async throws -> UserModel? {
        let profile: ProfileResponse = try await apiClient.send(.get("/profiles/me"))
        return UserModel(profile: profile)
    }

    func getUserInfo(by userId: String) async throws -> UserModel? {
        let profile: ProfileResponse = try await apiClient.send(.get("/profiles/\(userId)"))
        return UserModel(profile: profile)
    }

    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "avatar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])
        }
        let endpoint = Endpoint.postMultipart("/profiles/me/avatar", fieldName: "file", fileName: "\(userId).jpg", mimeType: "image/jpeg", fileData: data)
        let response: AvatarUploadResponse = try await apiClient.send(endpoint)
        return response.avatarUrl
    }

    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date) async throws {
        struct RequestBody: Encodable {
            let firstName: String
            let lastName: String
            let phone: String
            let dateOfBirth: String
        }
        let json = try JSONEncoder().encode(RequestBody(firstName: firstName, lastName: lastName, phone: phone, dateOfBirth: WishieDateFormatting.dateOnly.string(from: dateOfBirth)))
        let _: ProfileResponse = try await apiClient.send(.patch("/profiles/me", json: json))
    }

    func updateUserInterests(userId: String, interests: [String]) async throws {
        struct RequestBody: Encodable { let interests: [String] }
        let json = try JSONEncoder().encode(RequestBody(interests: interests))
        let _: ProfileResponse = try await apiClient.send(.patch("/profiles/me/interests", json: json))
    }
}

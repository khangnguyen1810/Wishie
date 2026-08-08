//
//  AuthenticateService.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 13/10/25.
//

import Foundation
import UIKit
import GoogleSignIn

struct ResetPasswordResponse: Decodable {
    let success: Bool
}

struct AvatarUploadResponse: Decodable {
    let avatarUrl: String
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
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws
    func updateUserInterests(userId: String, interests: [String]) async throws
}

final class AuthenticateService: AuthenticateServiceProtocol {
    private let apiClient: APIClientProtocol
    private let sessionStore: SessionStore

    init(apiClient: APIClientProtocol = APIClient(), sessionStore: SessionStore = .shared) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
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

    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
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

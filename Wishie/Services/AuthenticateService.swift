//
//  AuthenticateService.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 13/10/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import Supabase
import Combine
protocol AuthenticateServiceProtocol {
    func login(_ email: String, _ password: String) -> AnyPublisher<AuthDataResult?, Error>
    func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<FirebaseAuth.AuthDataResult?, Error>
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) -> AnyPublisher<AuthDataResult?, Error>
    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error>
    func getUserInfo() async throws -> UserModel?
    func getUserInfo(by userId: String) async throws -> UserModel?
    func uploadAvatar(image: UIImage, userId: String) async throws -> String
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws
    func updateUserInterests(userId: String, interests: [String]) async throws
}
class AuthenticateService: AuthenticateServiceProtocol {
    private let db = Firestore.firestore()
    private var auth = Auth.auth()
    func login(_ email: String, _ password: String) -> AnyPublisher<AuthDataResult?, Error> {
        return Future<AuthDataResult?, Error> { [weak self] promise in
            guard let self else { return }
            self.auth.signIn(withEmail: email, password: password) { result, error in
                if let error = error {
                    promise(.failure(error))
                    return
                } else {
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    func signUp(_ signupRequest: SignUpRequest) -> AnyPublisher<FirebaseAuth.AuthDataResult?, any Error> {
        return Future<AuthDataResult?, Error> { [weak self] promise in
            guard let self else { return }
            self.auth.createUser(withEmail: signupRequest.email, password: signupRequest.password) { result, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let user = result?.user else {
                    promise(.failure(NSError(domain: "SignUpError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User object is nil."])))
                    return
                }
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "firstName": signupRequest.firstName,
                    "lastName": signupRequest.lastName,
                    "email": signupRequest.email,
                    "phone": signupRequest.phone,
                    "dateOfBirth": Timestamp(date: signupRequest.dateOfBirth),
                    "createAt": FieldValue.serverTimestamp()
                ]
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error {
                        promise(.failure(error))
                        return
                    } else {
                        promise(.success(result))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) -> AnyPublisher<AuthDataResult?, Error> {
        return Future<AuthDataResult?, Error> { [weak self] promise in
            guard let self else { return }
            let credential = OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: rawNonce, fullName: fullName)
            self.auth.signIn(with: credential) { result, error in
                if let error {
                    promise(.failure(error))
                    return
                }
                guard let result else {
                    promise(.failure(NSError(domain: "SignInWithAppleError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication result is nil."])))
                    return
                }
                guard result.additionalUserInfo?.isNewUser == true else {
                    promise(.success(result))
                    return
                }
                let user = result.user
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "firstName": fullName?.givenName ?? "",
                    "lastName": fullName?.familyName ?? "",
                    "email": user.email ?? "",
                    "phone": "",
                    "dateOfBirth": Timestamp(date: Date()),
                    "createAt": FieldValue.serverTimestamp()
                ]
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error {
                        promise(.failure(error))
                        return
                    }
                    promise(.success(result))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self else { return }
            self.auth.sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(true))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    func getUserInfo() async throws -> UserModel? {
        guard let userId = UserDefaults.standard.string(forKey: "userid") else {
            return nil
        }
        
        let userDoc = try? await db
            .collection("users")
            .document(userId)
            .getDocument()
        
        guard let data = userDoc?.data() else {
            return nil
        }
        return UserModel(dictionary: data)
    }
    
    func getUserInfo(by userId: String) async throws -> UserModel? {
        let userDoc = try? await db
            .collection("users")
            .document(userId)
            .getDocument()
        
        guard let data = userDoc?.data() else {
            return nil
        }
        return UserModel(dictionary: data)
    }

    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "avatar", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])
        }
        let path = "avatar/\(userId).jpg"
        try await SupabaseManager.shared.client.storage
            .from("Wishie")
            .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
        let publicURL = try SupabaseManager.shared.client.storage
            .from("Wishie")
            .getPublicURL(path: path)
            .absoluteString
        return "\(publicURL)?t=\(Int(Date().timeIntervalSince1970))"
    }

    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
        var updateDict: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "phone": phone,
            "dateOfBirth": Timestamp(date: dateOfBirth)
        ]
        if let avatarUrl {
            updateDict["avatarUrl"] = avatarUrl
        }
        try await db.collection("users").document(userId).updateData(updateDict)
    }

    func updateUserInterests(userId: String, interests: [String]) async throws {
        try await db.collection(WishieConstants.firebaseUserPath).document(userId).updateData([
            "interests": interests,
            "hasCompletedInterestsSetup": true
        ])
    }
}

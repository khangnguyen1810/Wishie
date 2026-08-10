//
//  MockAuthenticateService.swift
//  WishieTests
//

import Foundation
import UIKit
@testable import Wishie

final class MockAuthenticateService: AuthenticateServiceProtocol {
    var signUpResult: Result<AuthSession, Error> = .failure(NSError(domain: "MockAuthenticateService", code: -1))
    var loginResult: Result<AuthSession, Error> = .failure(NSError(domain: "MockAuthenticateService", code: -1))
    var loginWithGoogleResult: Result<AuthSession, Error> = .failure(NSError(domain: "MockAuthenticateService", code: -1))
    var resetPasswordResult: Result<Bool, Error> = .success(true)
    var userToReturn: UserModel? = nil
    var getUserInfoError: Error? = nil

    func signUp(_ request: SignUpRequest) async throws -> AuthSession {
        try signUpResult.get()
    }
    func login(_ email: String, _ password: String) async throws -> AuthSession {
        try loginResult.get()
    }
    func loginWithGoogle(presentingViewController: UIViewController) async throws -> AuthSession {
        try loginWithGoogleResult.get()
    }
    func resetPassword(_ email: String) async throws -> Bool {
        try resetPasswordResult.get()
    }
    func logout() async throws {
    }
    func getUserInfo() async throws -> UserModel? {
        if let getUserInfoError { throw getUserInfoError }
        return userToReturn
    }
    func getUserInfo(by userId: String) async throws -> UserModel? {
        nil
    }
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        ""
    }
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date) async throws {
    }
    func updateUserInterests(userId: String, interests: [String]) async throws {
    }
}

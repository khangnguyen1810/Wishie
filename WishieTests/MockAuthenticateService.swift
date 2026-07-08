//
//  MockAuthenticateService.swift
//  WishieTests
//

import Foundation
import UIKit
import Combine
import FirebaseAuth
@testable import Wishie

final class MockAuthenticateService: AuthenticateServiceProtocol {
    var loginWithGoogleResult: AnyPublisher<AuthDataResult?, Error> = Empty().eraseToAnyPublisher()

    func login(_ email: String, _ password: String) -> AnyPublisher<AuthDataResult?, Error> {
        Empty().eraseToAnyPublisher()
    }
    func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<FirebaseAuth.AuthDataResult?, Error> {
        Empty().eraseToAnyPublisher()
    }
    func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<AuthDataResult?, Error> {
        loginWithGoogleResult
    }
    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error> {
        Empty().eraseToAnyPublisher()
    }
    func getUserInfo() async throws -> UserModel? {
        nil
    }
    func getUserInfo(by userId: String) async throws -> UserModel? {
        nil
    }
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        ""
    }
    func updateUserInfo(userId: String, firstName: String, lastName: String, phone: String, dateOfBirth: Date, avatarUrl: String?) async throws {
    }
    func updateUserInterests(userId: String, interests: [String]) async throws {
    }
}

//
//  AuthenticateService.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 13/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
protocol AuthenticateServiceProtocol {
    func login(_ email: String, _ password: String) -> AnyPublisher<AuthDataResult?, Error>
    func signUp(_ signUpRequest: SignUpRequest) -> AnyPublisher<FirebaseAuth.AuthDataResult?, Error>
    func resetPassword(_ email: String) -> AnyPublisher<Bool, Error>
    func getUserInfo() async throws -> UserModel?
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
}

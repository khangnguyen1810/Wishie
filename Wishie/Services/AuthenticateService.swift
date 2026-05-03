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
}
class AuthenticateService: AuthenticateServiceProtocol {
    private let db = Firestore.firestore()
    private var auth = Auth.auth()
    public static var shared = AuthenticateService()
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
}

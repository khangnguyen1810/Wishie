//
//  AppleSignInManager.swift
//  Wishie
//

import AuthenticationServices
import CryptoKit
import UIKit

final class AppleSignInManager: NSObject {
    private var currentNonce: String?
    private var continuation: CheckedContinuation<(idToken: String, rawNonce: String, fullName: PersonNameComponents?), Error>?

    func startSignInWithAppleFlow() async throws -> (idToken: String, rawNonce: String, fullName: PersonNameComponents?) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignInManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID credential."]
            ))
            continuation = nil
            return
        }
        guard let nonce = currentNonce else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignInManager",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid state: no login request was sent."]
            ))
            continuation = nil
            return
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignInManager",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token."]
            ))
            continuation = nil
            return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(
                domain: "AppleSignInManager",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data."]
            ))
            continuation = nil
            return
        }
        continuation?.resume(returning: (idToken: idTokenString, rawNonce: nonce, fullName: appleIDCredential.fullName))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }
        return keyWindow ?? ASPresentationAnchor()
    }
}

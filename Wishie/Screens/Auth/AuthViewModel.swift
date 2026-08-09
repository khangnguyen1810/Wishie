//
//  AuthViewModel.swift
//  Wishie
//

import Foundation
import UIKit

final class AuthViewModel: ObservableObject {
    private let authService: AuthenticateServiceProtocol
    private let sessionStore: SessionStore
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    private let userid = "userid"
    private let googleSignInErrorDomain = "com.google.GIDSignIn"
    private let googleSignInCanceledCode = -5 // GIDSignInError.Code.canceled's raw value
    @Published var isShowError: Bool = false
    @Published var errorTitle: String = ""
    @Published var errorMessage: String = ""
    @Published var isShowProgress: Bool = false
    @Published var request = SignUpRequest()
    @Published var userInfo = UserModel(dictionary: [:])
    @Published var isSentEmail: Bool = false
    @Published var forgotenEmail: String = ""
    @Published var userInfoError: String = ""

    init(authService: AuthenticateServiceProtocol = AuthenticateService(), sessionStore: SessionStore = .shared) {
        self.authService = authService
        self.sessionStore = sessionStore
        checkToken()
    }

    func checkToken() {
        Task {
            guard let session = await sessionStore.current() else { return }
            do {
                guard let result = try await authService.getUserInfo() else {
                    await clearSessionAndLogOut()
                    return
                }
                await MainActor.run {
                    self.userInfo = result
                    UserDefaults.standard.set(result.hasCompletedInterestsSetup, forKey: "hasCompletedInterestsSetup")
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                }
            } catch {
                await clearSessionAndLogOut()
            }
        }
    }

    /// Clears the persisted session and flips the view model back to a logged-out state.
    /// Shared by `checkToken()` (startup token validation) and `getUserInfo()` (mid-session
    /// `sessionExpired` detection) so both paths respond to an invalid/expired session the same way.
    private func clearSessionAndLogOut() async {
        await sessionStore.clear()
        await MainActor.run {
            self.isLoggedIn = false
            UserDefaults.standard.removeObject(forKey: self.userid)
        }
    }

    func login(email: String, password: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty, StringUtils.isValidEmail(trimmedEmail) else {
            self.isShowError = true
            self.errorTitle = "Invalid Input"
            self.errorMessage = "Please enter a valid email address and password."
            return
        }
        self.isShowProgress = true
        Task {
            do {
                let session = try await authService.login(trimmedEmail, trimmedPassword)
                await MainActor.run {
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                    self.isShowProgress = false
                }
                await self.getUserInfo()
            } catch {
                await MainActor.run {
                    self.isShowProgress = false
                    self.isShowError = true
                    self.errorTitle = "Login Failed"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func signup(request: SignUpRequest) {
        self.isShowProgress = true
        Task {
            do {
                let session = try await authService.signUp(request)
                await MainActor.run {
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                    self.isShowProgress = false
                }
                await self.getUserInfo()
            } catch {
                await MainActor.run {
                    self.isShowProgress = false
                    self.isShowError = true
                    self.errorTitle = "Signup Failed"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func loginWithGoogle(presentingViewController: UIViewController) {
        self.isShowProgress = true
        Task {
            do {
                let session = try await authService.loginWithGoogle(presentingViewController: presentingViewController)
                await MainActor.run {
                    UserDefaults.standard.setValue(session.userId, forKey: self.userid)
                    self.isLoggedIn = true
                    self.isShowProgress = false
                }
                await self.getUserInfo()
            } catch {
                await MainActor.run {
                    self.isShowProgress = false
                    let nsError = error as NSError
                    if nsError.domain == self.googleSignInErrorDomain, nsError.code == self.googleSignInCanceledCode {
                        return
                    }
                    self.isShowError = true
                    self.errorTitle = "Google Login Failed"
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func logOut() {
        self.isShowProgress = true
        Task {
            try? await authService.logout()
            await MainActor.run {
                UserDefaults.standard.removeObject(forKey: self.userid)
                self.isLoggedIn = false
                self.userInfo = UserModel()
                self.userInfoError = ""
                self.isShowProgress = false
            }
        }
    }

    @MainActor
    func getUserInfo() async {
        do {
            guard let result = try await authService.getUserInfo() else { return }
            self.userInfo = result
        } catch {
            if let apiError = error as? APIError, apiError == .sessionExpired {
                await clearSessionAndLogOut()
            } else {
                self.userInfoError = error.localizedDescription
            }
        }
    }

    func forgotPassword() {
        Task {
            do {
                let success = try await authService.resetPassword(forgotenEmail)
                await MainActor.run { self.isSentEmail = success }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

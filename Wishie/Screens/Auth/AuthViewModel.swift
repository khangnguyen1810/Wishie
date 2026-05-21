//
//  AuthViewModel.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 12/10/25.
//

import Foundation
import Combine
import FirebaseAuth
final class AuthViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let authService: AuthenticateServiceProtocol
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    private let userid = "userid"
    @Published var isShowError: Bool = false
    @Published var errorTitle: String = ""
    @Published var errorMessage: String = ""
    @Published var isShowProgress: Bool = false
    @Published var request = SignUpRequest()
    @Published var userInfo = UserModel(dictionary: [:])
    @Published var isSentEmail: Bool = false
    @Published var forgotenEmail: String = ""
    init(authService: AuthenticateServiceProtocol = AuthenticateService()) {
        self.authService = authService
        checkToken()
    }
    func checkToken() {
        guard let firebaseUser = Auth.auth().currentUser,
              let storedId = UserDefaults.standard.string(forKey: userid),
              !storedId.isEmpty,
              firebaseUser.uid == storedId else {
            UserDefaults.standard.removeObject(forKey: userid)
            return
        }
        Task {
            do {
                _ = try await firebaseUser.getIDToken(forcingRefresh: true)
                await MainActor.run { self.isLoggedIn = true }
            } catch {
                await MainActor.run { UserDefaults.standard.removeObject(forKey: self.userid) }
            }
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
        authService.login(trimmedEmail, trimmedPassword)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isShowProgress = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.isShowError = true
                    self.errorTitle = "Login Failed"
                    self.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] credential in
                guard let self,
                      let user = credential?.user
                else { return }
                UserDefaults.standard.setValue(user.uid, forKey: userid)
                isLoggedIn = true
            }
            .store(in: &cancellables)
    }
    
    func signup(request: SignUpRequest) {
        self.isShowProgress = true
        authService.signUp(request)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isShowProgress = false
                switch completion {
                case .failure(let error):
                    self.isShowError = true
                    self.errorTitle = "Signup Failed"
                    self.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { [weak self] result in
                guard let self,
                      let user = result?.user
                else { return }
                UserDefaults.standard.setValue(user.uid, forKey: userid)
                isLoggedIn = true
            }
            .store(in: &cancellables)
        
    }
    func logOut() {
        self.isShowProgress = true
        UserDefaults.standard.removeObject(forKey: userid)
        isLoggedIn = false
        self.isShowProgress = false
    }
    
    @MainActor
    func getUserInfo() async {
        do {
            guard let result = try await authService.getUserInfo() else { return }
            self.userInfo = result
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func forgotPassword() {
        authService.resetPassword(forgotenEmail)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self]success in
                self?.isSentEmail = success
            }
            .store(in: &cancellables)
    }
}

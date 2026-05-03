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
        if let token = UserDefaults.standard.string(forKey: userid), !token.isEmpty {
            isLoggedIn = true
        }
    }
    func login(email: String, password: String) {
        self.isShowProgress = true
        authService.login(email, password)
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

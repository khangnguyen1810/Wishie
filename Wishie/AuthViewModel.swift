final class AuthViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    func login(email: String, password: String) {
        AuthService.shared.login(email: email, password: password)
            .sink { completion in
                switch completion {
                case .finished:
                    print("✅ Login success sink finished")
                case .failure(let error):
                    print("❌ Login failed with error: \(error)")
                }
            } receiveValue: { response in
                print("🎯 Token: \(response.token)")
            }
            .store(in: &cancellables)
    }
    
    func signup(email: String, password: String, name: String) {
        AuthService.shared.signup(email: email, password: password, name: name)
            .sink { completion in
                switch completion {
                case .finished:
                    print("✅ Signup success sink finished")
                case .failure(let error):
                    print("❌ Signup failed with error: \(error)")
                }
            } receiveValue: { response in
                print("🎯 Signup message: \(response.message)")
            }
            .store(in: &cancellables)
    }
}
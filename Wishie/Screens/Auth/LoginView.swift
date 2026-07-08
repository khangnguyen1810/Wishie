//
//  LoginView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 9/10/25.
//

import SwiftUI
enum InputFieldType {
    case firstName
    case lastName
    case email
    case password
    case phone
}
struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isValidEmail: Bool = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: InputFieldType?
    
    
    var body: some View {
        VStack {
            Button {
                dismiss()
            } label: {
                Circle().frame(width: 50, height: 50)
                    .foregroundStyle(.lightYellow)
                    .overlay {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(.black)
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Hello old friend, are you good ?")
                .font(.wishies(.bold, 37))
                .frame(maxWidth: .infinity,minHeight: 100 , alignment: .leading)
                .padding(.vertical, 30)
            
            Text("Email")
                .font(.wishies(.bold, 17))
                .padding(.bottom, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Email", text: $email)
                .font(.wishies(.regular, 17))
                .padding(.horizontal,15)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .email)
                .onSubmit {
                    focusedField = .password
                }
                .onChange(of: focusedField) {_,newFocusedField in
                    if newFocusedField == .email {
                        isValidEmail = true
                    } else if newFocusedField == .password {
                        validateEmail()
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                        .frame(height: 56)
                }
            if (!isValidEmail) {
                Text("Invalid email format")
                    .foregroundColor(.red)
                    .font(.wishies(.regular, 14))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Text("Password")
                .font(.wishies(.bold, 17))
                .padding(.bottom, 15)
                .padding(.top, isValidEmail ? 40 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
            PasswordField(password: $password, showPassword: $showPassword)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    focusedField = nil
                }
                .padding(.bottom, 15)
            NavigationLink(
                destination: ForgotPasswordView().navigationBarBackButtonHidden(),
                label: {
                Text("Forgot my password...")
                    .font(.wishies(.light, 14))
                    .foregroundStyle(.black)
            })
            .frame(maxWidth: .infinity, alignment: .trailing)
            Button(action: {
                viewModel.login(email: email, password: password)
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(validateGoinButton() ? .black.opacity(0.4): .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .shadow(color: .black.opacity(0.2), radius: 4, x:0, y: 5)
                    Text("Go in")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.lightYellow)
                }
            })
            .padding(.vertical, 20)
            HStack {
                Rectangle()
                    .frame(width: UIScreen.main.bounds.width/3,height: 2)
                Text("or")
                    .font(.wishies(.regular, 15).italic())
                Rectangle()
                    .frame(width: UIScreen.main.bounds.width/3,height: 2)
            }
            Button(action: {
                guard let presentingViewController = UIApplication.topViewController() else { return }
                viewModel.loginWithGoogle(presentingViewController: presentingViewController)
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .shadow(color: .black.opacity(0.2), radius: 4, x:0, y: 5)
                    HStack {
                        Image("google_icon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20)
                            .padding(.leading, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Login with Google")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            })
            
            .padding(.vertical, 10)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background {
            Color.lightYellow1.ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard, edges: .top)
        .showDialogIfNeeded($viewModel.isShowError, title: viewModel.errorTitle, message: viewModel.errorMessage)
        .showFullScreenDialog($viewModel.isShowProgress)
        .onTapGesture {
            validateEmail()
            hideKeyboard()
        }
    }
    private func validateGoinButton() -> Bool {
        return  password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !StringUtils.isValidEmail(email)
    }
    private func validateEmail() {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        if StringUtils.isValidEmail(email) {
            isValidEmail = true
        } else {
            isValidEmail = false
        }
    }
}

//
//  LoginView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 9/10/25.
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
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: InputFieldType?

    private var emailError: String? {
        AuthValidation.showsEmailError(email: email, isFocused: focusedField == .email)
            ? AuthValidation.emailErrorMessage
            : nil
    }

    var body: some View {
        AuthScaffold(
            screenID: "login",
            title: "Welcome back.",
            subtitle: "Log in to see your lists.",
            cardTheme: .coral
        ) {
            AuthField("Email", text: $email, kind: .email, error: emailError)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
            AuthField("Password", text: $password, kind: .password(isNew: false))
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
            NavigationLink {
                ForgotPasswordView()
                    .navigationBarBackButtonHidden()
            } label: {
                Text("Forgot password?")
                    .font(.wishies(.bold, 14))
                    .underline()
                    .foregroundStyle(Color("obInk"))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("auth.forgotPasswordLink")
            WishieButton(
                title: "Log in",
                enabled: AuthValidation.canLogIn(email: email, password: password),
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                viewModel.login(email: email, password: password)
            }
            .accessibilityIdentifier("auth.primaryButton")
            AuthSocialSection {
                guard let presentingViewController = UIApplication.topViewController() else { return }
                viewModel.loginWithGoogle(presentingViewController: presentingViewController)
            }
        }
        .showDialogIfNeeded($viewModel.isShowError, title: viewModel.errorTitle, message: viewModel.errorMessage)
        .showFullScreenDialog($viewModel.isShowProgress)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}

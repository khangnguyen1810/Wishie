//
//  SignUpView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 19/10/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var lastName: String = ""
    @State private var firstName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var goToPassword = false
    @State private var dob: Date = Date()

    @FocusState private var focusedField: InputFieldType?

    private var emailError: String? {
        AuthValidation.showsEmailError(email: email, isFocused: focusedField == .email)
            ? AuthValidation.emailErrorMessage
            : nil
    }

    /// Side by side normally; stacked at accessibility text sizes, where two columns are too narrow.
    private var nameLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
    }

    var body: some View {
        AuthScaffold(
            screenID: "signup",
            title: "Create your\naccount.",
            subtitle: "It takes a minute.",
            cardTheme: .mint
        ) {
            nameLayout {
                AuthField("First name", text: $firstName, kind: .firstName)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .lastName
                    }
                AuthField("Last name", text: $lastName, kind: .lastName)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .email
                    }
            }
            AuthField("Email", text: $email, kind: .email, error: emailError)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .phone
                }
            AuthField("Phone", text: $phone, kind: .phone)
                .focused($focusedField, equals: .phone)
            AuthBirthdayField(date: $dob)
            WishieButton(
                title: "Continue",
                enabled: AuthValidation.canContinueSignUp(email: email, phone: phone),
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                focusedField = nil
                authVM.request = SignUpRequest(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phone: phone,
                    dateOfBirth: dob
                )
                goToPassword = true
            }
            .accessibilityIdentifier("auth.primaryButton")
            AuthSocialSection {
                guard let presentingViewController = UIApplication.topViewController() else { return }
                authVM.loginWithGoogle(presentingViewController: presentingViewController)
            }
        }
        .showDialogIfNeeded(
            $authVM.isShowError,
            title: authVM.errorTitle,
            message: authVM.errorMessage
        )
        .showFullScreenDialog($authVM.isShowProgress)
        .navigationDestination(isPresented: $goToPassword) {
            PasswordSignUpView()
                .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}

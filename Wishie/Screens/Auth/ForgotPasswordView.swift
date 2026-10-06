//
//  ForgotPasswordView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/3/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool

    private var emailError: String? {
        AuthValidation.showsEmailError(email: viewModel.forgotenEmail, isFocused: isEmailFocused)
            ? AuthValidation.emailErrorMessage
            : nil
    }

    var body: some View {
        AuthScaffold(
            screenID: "forgot",
            title: "Reset your password.",
            subtitle: "We will email you a link.",
            cardTheme: .gold
        ) {
            AuthField("Email", text: $viewModel.forgotenEmail, kind: .email, error: emailError)
                .focused($isEmailFocused)
                .submitLabel(.done)
                .onSubmit {
                    isEmailFocused = false
                }
        } footer: {
            WishieButton(
                title: "Send reset link",
                enabled: AuthValidation.canSendReset(email: viewModel.forgotenEmail),
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                viewModel.forgotPassword()
            }
            .accessibilityIdentifier("auth.primaryButton")
        }
        .onDisappear {
            viewModel.forgotenEmail = ""
        }
        .showDialogIfNeeded(
            $viewModel.isSentEmail,
            title: "Email has been sent",
            message: "Please follow the link in the email to reset your password, thank you <3",
            onOk: {
                dismiss()
            })
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}

//
//  PasswordSignUpView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 26/10/25.
//

import SwiftUI

struct PasswordSignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @FocusState private var isPasswordFocused: Bool
    @State private var password: String = ""

    private var isLongEnough: Bool {
        AuthValidation.isPasswordLongEnough(password)
    }

    var body: some View {
        AuthScaffold(
            screenID: "password",
            title: "Pick a\npassword.",
            subtitle: AuthValidation.passwordSubtitle(firstName: authVM.request.firstName),
            cardTheme: .grape
        ) {
            AuthField("Password", "••••••", text: $password, kind: .password(isNew: true))
                .focused($isPasswordFocused)
                .submitLabel(.done)
                .onSubmit {
                    isPasswordFocused = false
                }
            ruleRow
        } footer: {
            WishieButton(
                title: "Create account",
                enabled: isLongEnough,
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                isPasswordFocused = false
                authVM.request.password = password
                authVM.signup(request: authVM.request)
            }
            .accessibilityIdentifier("auth.primaryButton")
        }
        .showDialogIfNeeded(
            $authVM.isShowError,
            title: authVM.errorTitle,
            message: authVM.errorMessage
        )
        .showFullScreenDialog($authVM.isShowProgress)
    }

    /// The one password rule the backend enforces, ticked off as soon as it is met.
    private var ruleRow: some View {
        let text = "At least \(AuthValidation.minimumPasswordLength) characters"
        return HStack(spacing: 8) {
            ZStack {
                if isLongEnough {
                    Circle()
                        .fill(Color("obInk"))
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.lightYellow)
                } else {
                    Circle()
                        .strokeBorder(Color("obInk"), lineWidth: 1.5)
                }
            }
            .frame(width: 16, height: 16)
            Text(text)
                .font(.wishies(.medium, 14))
                .foregroundStyle(Color("obInk"))
        }
        .opacity(isLongEnough ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text), \(isLongEnough ? "met" : "not met")")
        .accessibilityIdentifier("auth.passwordRule")
    }
}

#Preview {
    PasswordSignUpView()
        .environmentObject(AuthViewModel())
}

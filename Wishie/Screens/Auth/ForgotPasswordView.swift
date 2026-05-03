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
    @State private var isValidEmail: Bool = true
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
            
            Text("Just provide us your email to reset password <3")
                .font(.wishies(.bold, 37))
                .frame(maxWidth: .infinity,minHeight: 80 , alignment: .leading)
                .padding(.vertical, 30)
            Text("Email")
                .font(.wishies(.bold, 17))
                .padding(.bottom, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Email", text: $viewModel.forgotenEmail)
                .font(.wishies(.regular, 17))
                .padding(.horizontal,15)
                .textInputAutocapitalization(.never)
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
            Spacer()
            Button(action: {
                viewModel.forgotPassword()
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            !StringUtils.isValidEmail(viewModel.forgotenEmail) || viewModel.forgotenEmail.isEmpty ? .black.opacity(0.4) : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    Text("Go in")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.lightYellow)
                }
            })
            .disabled(!StringUtils.isValidEmail(viewModel.forgotenEmail) || viewModel.forgotenEmail.isEmpty)
            .padding(.vertical, 20)
        }
        .padding([.horizontal,.bottom], 20)
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background {
            Color.lightYellow1.ignoresSafeArea()
        }
        .onTapGesture {
            hideKeyboard()
            validateEmail(email: viewModel.forgotenEmail)
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
    private func validateEmail(email: String) {
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

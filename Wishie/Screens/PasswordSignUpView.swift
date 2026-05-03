//
//  PasswordSignUpView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 26/10/25.
//

import SwiftUI

struct PasswordSignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: InputFieldType?
    @State private var password: String = ""
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
            
            Text("Hi new friend, please create password to continue")
                .font(.wishies(.bold, 37))
                .frame(maxWidth: .infinity,minHeight: 80 , alignment: .leading)
                .padding(.vertical, 30)
            Text("Password")
                .font(.wishies(.bold, 17))
                .padding(.bottom, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            PasswordField(password: $password, showPassword: $showPassword)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    focusedField = nil
                }
                .padding(.bottom, 15)
            Spacer()
            Button(action: {
                focusedField = nil
                authVM.request.password = password
                authVM.signup(request: authVM.request)
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(password.isEmpty ? .black.opacity(0.4) : .black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    Text("Go in")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.lightYellow)
                }
            })
            .disabled(password.isEmpty)
            .padding(.vertical, 20)
        }
        .padding([.horizontal,.bottom], 20)
        .frame(maxWidth: .infinity,maxHeight: .infinity)
        .background {
            Color.lightYellow1.ignoresSafeArea()
        }
        .showDialogIfNeeded(
            $authVM.isShowError,
            title: authVM.errorTitle,
            message: authVM.errorMessage
        )
        .showFullScreenDialog($authVM.isShowProgress)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil 
                }
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}


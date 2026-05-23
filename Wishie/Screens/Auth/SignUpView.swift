//
//  SignUpView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 19/10/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var lastName: String = ""
    @State private var firstName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var phone: String = ""
    @State private var date: String = ""
    @State private var month: String = ""
    @State private var year: String = ""
    @State private var showPassword: Bool = false
    @State private var goToPassword = false
    @State private var dob: Date = Date()
    
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
            
            Text("Welcome new friend, are you good ?")
                .font(.wishies(.bold, 37))
                .frame(maxWidth: .infinity,minHeight: 80 , alignment: .leading)
                .padding(.vertical, 30)
            HStack(spacing: 10) {
                VStack {
                    Text("First name")
                        .font(.wishies(.bold, 17))
                        .padding(.bottom, 15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("First name", text: $firstName)
                        .font(.wishies(.regular, 17))
                        .padding(.horizontal,15)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .firstName)
                        .onSubmit {
                            focusedField = .lastName
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                                .frame(height: 56)
                                
                        }
                }
                VStack {
                    Text("Last name")
                        .font(.wishies(.bold, 17))
                        .padding(.bottom, 15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("Last name", text: $lastName)
                        .font(.wishies(.regular, 17))
                        .padding(.horizontal,15)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .lastName)
                        .onSubmit {
                            focusedField = .email
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                                .frame(height: 56)
                                
                        }
                }
            }
            .padding(.bottom,30)
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
                    focusedField = .phone
                }
                .background {
                    RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                        .frame(height: 56)
                }
                .padding(.bottom,30)
            Text("Phone")
                .font(.wishies(.bold, 17))
                .padding(.bottom, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Phone", text: $phone)
                .font(.wishies(.regular, 17))
                .padding(.horizontal,15)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .phone)
                .onSubmit {
                    focusedField = nil
                }
                .background {
                    RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                        .frame(height: 56)
                }
            DateInputView(isCreating: .constant(true ), date: $dob)
                .padding(.vertical, 30)
            Button(action: {
                focusedField = nil
                authVM.request = SignUpRequest(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phone:phone,
                    dateOfBirth: dob
                )
                goToPassword = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(email.isEmpty ? .black.opacity(0.4) : .black)
                        .frame(height: 50)
                    Text("Continue")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.yellow)
                }
            }
            .disabled(email.isEmpty)
            
            HStack {
                Rectangle()
                    .frame(width: UIScreen.main.bounds.width/3,height: 2)
                Text("or")
                    .font(.wishies(.italic, 15))
                Rectangle()
                    .frame(width: UIScreen.main.bounds.width/3,height: 2)
            }
            Button(action: {
                authVM.isShowError = true
                authVM.errorTitle = "Apple login is not supported"
                authVM.errorMessage = "This feature is currently not supported on app"
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .shadow(color: .black.opacity(0.2), radius: 4, x:0, y: 5)
                    HStack {
                        Image(systemName: "apple.logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.white)
                            .frame(width: 20)
                            .padding(.leading, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Login with Apple")
                        .font(.wishies(.bold, 20))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            })
            .padding(.vertical, 10)
            Spacer()
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
        .navigationDestination(isPresented: $goToPassword) {
            PasswordSignUpView()
                .navigationBarBackButtonHidden()
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    fileprivate func dateOfBirthField(placeHolder: String, text: Binding<String>) -> some View {
        return TextField(placeHolder, text: text)
            .keyboardType(.numberPad)
            .font(.wishies(.regular, 17))
            .padding(.horizontal,15)
            .textInputAutocapitalization(.never)
            .background {
                RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                    .frame(height: 56)
            }
    }
    private func validateGoinButton() -> Bool {
        return email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
extension Binding where Value == String {
    func max(_ limit: Int) -> Self {
        if self.wrappedValue.count > limit {
            DispatchQueue.main.async {
                self.wrappedValue = String(self.wrappedValue.prefix(limit))
            }
        }
        return self
    }
}

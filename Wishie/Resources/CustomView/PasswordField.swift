//
//  PasswordField.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 21/10/25.
//

import SwiftUI

struct PasswordField: View {
    @Binding var password: String
    @Binding var showPassword: Bool
    var body: some View {
        ZStack {
            if showPassword {
                TextField("Password", text: $password)
                    .font(.wishies(.regular, 17))
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal,15)
            } else {
                SecureField("Password", text: $password)
                    .font(.wishies(.regular, 17))
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal,15)
            }
            HStack {
                Spacer()
                Image(showPassword ? "eye-slash-solid-full" : "eye-solid-full")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25)
                    .onTapGesture {
                        showPassword.toggle()
                    }
                    .padding(.trailing,15)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
                .frame(height: 56)
        }
    }
}

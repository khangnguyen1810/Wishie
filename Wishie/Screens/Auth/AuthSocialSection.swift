//
//  AuthSocialSection.swift
//  Wishie
//

import SwiftUI

/// The "or" divider and the Google button under the primary button on Login and Sign up.
struct AuthSocialSection: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                line
                Text("or")
                    .font(.wishies(.italic, 15))
                    .foregroundStyle(Color("obInk").opacity(0.6))
                line
            }
            .accessibilityHidden(true)
            Button(action: action) {
                HStack(spacing: 10) {
                    Image("google_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text("Continue with Google")
                        .font(.wishies(.bold, 17))
                        .foregroundStyle(Color("obInk"))
                }
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color("obInk").opacity(0.14), lineWidth: 1.5)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("auth.googleButton")
        }
    }

    private var line: some View {
        Rectangle()
            .fill(Color("obInk").opacity(0.25))
            .frame(height: 1)
    }
}

#Preview {
    AuthSocialSection {}
        .padding(30)
        .background(Color("obScreenBg"))
}

//
//  AuthValidation.swift
//  Wishie
//

import Foundation

/// Rules for when the auth forms enable their primary button and show an inline error.
/// Kept free of view state so the rules can be unit tested.
enum AuthValidation {
    /// Matches the minimum `POST /auth/signup` enforces.
    static let minimumPasswordLength = 8
    static let emailErrorMessage = "Enter a valid email address."

    /// The error waits until focus leaves the field, so it never appears mid-typing.
    static func showsEmailError(email: String, isFocused: Bool) -> Bool {
        guard !isFocused else { return false }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !StringUtils.isValidEmail(trimmed)
    }

    static func canLogIn(email: String, password: String) -> Bool {
        StringUtils.isValidEmail(email) && !isBlank(password)
    }

    static func canContinueSignUp(email: String, phone: String) -> Bool {
        StringUtils.isValidEmail(email) && !isBlank(phone)
    }

    /// Counts the password as typed: the backend receives it untrimmed.
    static func isPasswordLongEnough(_ password: String) -> Bool {
        password.count >= minimumPasswordLength
    }

    static func canSendReset(email: String) -> Bool {
        StringUtils.isValidEmail(email)
    }

    static func passwordSubtitle(firstName: String) -> String {
        let name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Last step." : "Last step, \(name)."
    }

    private static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

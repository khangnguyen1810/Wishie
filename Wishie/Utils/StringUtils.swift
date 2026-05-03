//
//  StringUtils.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 1/12/25.
//

import Foundation

/// A namespace for common string helpers used across the app.
/// Use static methods directly, e.g. `StringUtils.isValidEmail(email)`.
enum StringUtils {
    /// Returns true if the provided email string matches a basic RFC 5322–compatible pattern.
    static func isValidEmail(_ email: String) -> Bool {
        // Quick reject for obviously invalid inputs
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard email.isEmpty == false else { return false }

        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    /// Returns the input string trimmed of whitespace and newlines.
    static func trimmed(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns true if the input is empty or only whitespace/newlines.
    static func isBlank(_ string: String) -> Bool {
        trimmed(string).isEmpty
    }
}


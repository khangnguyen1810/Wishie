//
//  AuthValidationTests.swift
//  WishieTests
//

import Testing
@testable import Wishie

struct AuthValidationTests {
    // MARK: showsEmailError

    @Test func emailErrorShowsForAnInvalidEmailOnceFocusLeaves() {
        #expect(AuthValidation.showsEmailError(email: "linh@example", isFocused: false))
    }

    @Test func emailErrorIsHiddenWhileTheFieldIsFocused() {
        #expect(!AuthValidation.showsEmailError(email: "linh@example", isFocused: true))
    }

    @Test func emailErrorIsHiddenForAnEmptyOrBlankField() {
        #expect(!AuthValidation.showsEmailError(email: "", isFocused: false))
        #expect(!AuthValidation.showsEmailError(email: "   ", isFocused: false))
    }

    @Test func emailErrorIsHiddenForAValidEmail() {
        #expect(!AuthValidation.showsEmailError(email: "linh@example.com", isFocused: false))
    }

    @Test func emailErrorIsHiddenForAValidEmailWithSurroundingSpaces() {
        #expect(!AuthValidation.showsEmailError(email: " linh@example.com ", isFocused: false))
    }

    // MARK: canLogIn

    @Test func canLogInWithAValidEmailAndAPassword() {
        #expect(AuthValidation.canLogIn(email: "linh@example.com", password: "x"))
    }

    @Test func canLogInWithSpacesAroundTheEmail() {
        #expect(AuthValidation.canLogIn(email: " linh@example.com ", password: "secret"))
    }

    @Test func cannotLogInWithAnInvalidEmail() {
        #expect(!AuthValidation.canLogIn(email: "linh@example", password: "secret"))
    }

    @Test func cannotLogInWithAnEmptyOrBlankPassword() {
        #expect(!AuthValidation.canLogIn(email: "linh@example.com", password: ""))
        #expect(!AuthValidation.canLogIn(email: "linh@example.com", password: "   "))
    }

    // MARK: canContinueSignUp

    @Test func canContinueSignUpWithAValidEmailAndAPhone() {
        #expect(AuthValidation.canContinueSignUp(email: "linh@example.com", phone: "0901234567"))
    }

    @Test func cannotContinueSignUpWithoutAPhone() {
        #expect(!AuthValidation.canContinueSignUp(email: "linh@example.com", phone: ""))
        #expect(!AuthValidation.canContinueSignUp(email: "linh@example.com", phone: "  "))
    }

    @Test func cannotContinueSignUpWithAnInvalidEmail() {
        #expect(!AuthValidation.canContinueSignUp(email: "linh", phone: "0901234567"))
        #expect(!AuthValidation.canContinueSignUp(email: "", phone: "0901234567"))
    }

    // MARK: isPasswordLongEnough

    @Test func minimumPasswordLengthIsEight() {
        #expect(AuthValidation.minimumPasswordLength == 8)
    }

    @Test func sevenCharactersIsTooShort() {
        #expect(!AuthValidation.isPasswordLongEnough("1234567"))
        #expect(!AuthValidation.isPasswordLongEnough(""))
    }

    @Test func eightCharactersIsLongEnough() {
        #expect(AuthValidation.isPasswordLongEnough("12345678"))
    }

    @Test func passwordIsNotTrimmedBeforeCounting() {
        #expect(AuthValidation.isPasswordLongEnough("        "))
    }

    @Test func accentedCharactersCountOnceEach() {
        #expect(AuthValidation.isPasswordLongEnough("mậtkhẩu1"))
        #expect(!AuthValidation.isPasswordLongEnough("mậtkhẩu"))
    }

    // MARK: canSendReset

    @Test func canSendResetOnlyForAValidEmail() {
        #expect(AuthValidation.canSendReset(email: "linh@example.com"))
        #expect(!AuthValidation.canSendReset(email: "linh@example"))
        #expect(!AuthValidation.canSendReset(email: ""))
    }

    // MARK: passwordSubtitle

    @Test func passwordSubtitleUsesTheTrimmedFirstName() {
        #expect(AuthValidation.passwordSubtitle(firstName: " Linh ") == "Last step, Linh.")
    }

    @Test func passwordSubtitleOmitsAnEmptyOrBlankName() {
        #expect(AuthValidation.passwordSubtitle(firstName: "") == "Last step.")
        #expect(AuthValidation.passwordSubtitle(firstName: "   ") == "Last step.")
    }

    // MARK: copy

    @Test func emailErrorMessageCopy() {
        #expect(AuthValidation.emailErrorMessage == "Enter a valid email address.")
    }
}

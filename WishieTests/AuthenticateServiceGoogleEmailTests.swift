//
//  AuthenticateServiceGoogleEmailTests.swift
//  WishieTests
//

import Testing
@testable import Wishie

struct AuthenticateServiceGoogleEmailTests {
    @Test func prefersFirebaseEmailWhenPresent() {
        let email = AuthenticateService.resolvedGoogleEmail(firebaseEmail: "user@gmail.com", profileEmail: "profile@gmail.com")
        #expect(email == "user@gmail.com")
    }

    @Test func fallsBackToProfileEmailWhenFirebaseEmailIsNil() {
        let email = AuthenticateService.resolvedGoogleEmail(firebaseEmail: nil, profileEmail: "profile@gmail.com")
        #expect(email == "profile@gmail.com")
    }

    @Test func fallsBackToProfileEmailWhenFirebaseEmailIsEmpty() {
        let email = AuthenticateService.resolvedGoogleEmail(firebaseEmail: "", profileEmail: "profile@gmail.com")
        #expect(email == "profile@gmail.com")
    }

    @Test func returnsEmptyStringWhenBothMissing() {
        let email = AuthenticateService.resolvedGoogleEmail(firebaseEmail: nil, profileEmail: nil)
        #expect(email == "")
    }
}

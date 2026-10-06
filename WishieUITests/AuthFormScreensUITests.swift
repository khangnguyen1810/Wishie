//
//  AuthFormScreensUITests.swift
//  WishieUITests
//

import XCTest

final class AuthFormScreensUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: Helpers

    /// Launches straight into the unauthenticated state, whatever is stored on the simulator.
    @MainActor
    private func launchUnauthenticated(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-userid", ""]
        app.launchArguments += extraArguments
        app.launch()
        return app
    }

    @MainActor
    private func openLogin(_ app: XCUIApplication) {
        let login = app.buttons["auth.loginButton"]
        XCTAssertTrue(login.waitForExistence(timeout: 10))
        login.tap()
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func openSignUp(_ app: XCUIApplication) {
        let signUp = app.buttons["auth.signUpLink"]
        XCTAssertTrue(signUp.waitForExistence(timeout: 10))
        signUp.tap()
        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))
    }

    /// Fills the required Sign up fields and continues to Create password.
    @MainActor
    private func openCreatePassword(_ app: XCUIApplication) {
        openSignUp(app)
        type("Linh", into: app.textFields["auth.field.firstName"])
        type("linh@example.com", into: app.textFields["auth.field.email"])
        type("0901234567", into: app.textFields["auth.field.phone"])
        app.buttons["auth.primaryButton"].tap()
        XCTAssertTrue(app.staticTexts["auth.password.title"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func type(_ text: String, into element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        element.tap()
        element.typeText(text)
    }

    // MARK: Login

    @MainActor
    func testLoginShowsEmailErrorOnlyAfterLeavingTheField() throws {
        let app = launchUnauthenticated()
        openLogin(app)

        type("linh@example", into: app.textFields["auth.field.email"])
        XCTAssertFalse(app.staticTexts["auth.emailError"].exists, "The error must wait until focus leaves the field")

        type("secret", into: app.secureTextFields["auth.field.password"])

        let error = app.staticTexts["auth.emailError"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "Enter a valid email address.")
        XCTAssertFalse(app.buttons["auth.primaryButton"].isEnabled)
    }

    @MainActor
    func testLoginButtonEnablesForAValidEmailAndAPassword() throws {
        let app = launchUnauthenticated()
        openLogin(app)

        let primary = app.buttons["auth.primaryButton"]
        XCTAssertEqual(primary.label, "Log in")
        XCTAssertFalse(primary.isEnabled)

        type("linh@example.com", into: app.textFields["auth.field.email"])
        XCTAssertFalse(primary.isEnabled)

        type("secret", into: app.secureTextFields["auth.field.password"])
        XCTAssertTrue(primary.isEnabled)
        XCTAssertFalse(app.staticTexts["auth.emailError"].exists)
    }

    @MainActor
    func testLoginBackButtonReturnsToLanding() throws {
        let app = launchUnauthenticated()
        openLogin(app)

        app.buttons["auth.backButton"].tap()

        XCTAssertTrue(app.buttons["auth.loginButton"].waitForExistence(timeout: 5))
    }

    // MARK: Forgot password

    @MainActor
    func testForgotPasswordButtonEnablesOnlyForAValidEmail() throws {
        let app = launchUnauthenticated()
        openLogin(app)

        app.buttons["auth.forgotPasswordLink"].tap()
        XCTAssertTrue(app.staticTexts["auth.forgot.title"].waitForExistence(timeout: 5))

        let primary = app.buttons["auth.primaryButton"]
        XCTAssertEqual(primary.label, "Send reset link")
        XCTAssertFalse(primary.isEnabled)

        let email = app.textFields["auth.field.email"]
        type("linh@example", into: email)
        XCTAssertFalse(primary.isEnabled)

        email.typeText(".com")
        XCTAssertTrue(primary.isEnabled)
    }

    // MARK: Sign up

    @MainActor
    func testSignUpContinueNeedsAValidEmailAndAPhone() throws {
        let app = launchUnauthenticated()
        openSignUp(app)

        let primary = app.buttons["auth.primaryButton"]
        XCTAssertEqual(primary.label, "Continue")
        XCTAssertFalse(primary.isEnabled)

        type("linh@example.com", into: app.textFields["auth.field.email"])
        XCTAssertFalse(primary.isEnabled, "Phone is required")

        type("0901234567", into: app.textFields["auth.field.phone"])
        XCTAssertTrue(primary.isEnabled)
    }

    @MainActor
    func testSignUpShowsEmailErrorAfterLeavingTheField() throws {
        let app = launchUnauthenticated()
        openSignUp(app)

        type("linh@example", into: app.textFields["auth.field.email"])
        XCTAssertFalse(app.staticTexts["auth.emailError"].exists)

        type("0901234567", into: app.textFields["auth.field.phone"])

        XCTAssertTrue(app.staticTexts["auth.emailError"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["auth.primaryButton"].isEnabled)
    }

    @MainActor
    func testSignUpKeepsValuesAfterReturningFromPassword() throws {
        let app = launchUnauthenticated()
        openCreatePassword(app)

        app.buttons["auth.backButton"].tap()

        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["auth.field.firstName"].value as? String, "Linh")
        XCTAssertEqual(app.textFields["auth.field.email"].value as? String, "linh@example.com")
        XCTAssertEqual(app.textFields["auth.field.phone"].value as? String, "0901234567")
    }

    // MARK: Create password

    @MainActor
    func testCreatePasswordGreetsByFirstName() throws {
        let app = launchUnauthenticated()
        openCreatePassword(app)

        XCTAssertTrue(app.staticTexts["Last step, Linh."].exists)
        XCTAssertEqual(app.buttons["auth.primaryButton"].label, "Create account")
    }

    @MainActor
    func testCreatePasswordButtonEnablesAtEightCharacters() throws {
        let app = launchUnauthenticated()
        openCreatePassword(app)

        let primary = app.buttons["auth.primaryButton"]
        let rule = app.descendants(matching: .any)["auth.passwordRule"]
        XCTAssertFalse(primary.isEnabled)
        XCTAssertEqual(rule.label, "At least 8 characters, not met")

        // Reveal first: the plain text field is not covered by the strong-password suggestion.
        app.buttons["Show password"].tap()
        let password = app.textFields["auth.field.password"]
        type("1234567", into: password)
        XCTAssertFalse(primary.isEnabled)

        password.typeText("8")
        XCTAssertTrue(primary.isEnabled)
        XCTAssertEqual(rule.label, "At least 8 characters, met")
    }

    // MARK: Largest text size

    @MainActor
    func testBackButtonStaysHittableAtLargestTextSize() throws {
        let app = launchUnauthenticated(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])
        let back = app.buttons["auth.backButton"]

        // Login, then Forgot password.
        openLogin(app)
        XCTAssertTrue(back.isHittable)
        let forgot = app.buttons["auth.forgotPasswordLink"]
        if !forgot.isHittable {
            app.swipeUp()
        }
        forgot.tap()
        XCTAssertTrue(app.staticTexts["auth.forgot.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable)
        XCTAssertTrue(app.buttons["auth.primaryButton"].isHittable, "The pinned footer button must stay on screen")
        back.tap()
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))
        back.tap()

        // Sign up, then Create password.
        openCreatePassword(app)
        XCTAssertTrue(back.isHittable)
        XCTAssertTrue(app.buttons["auth.primaryButton"].isHittable, "The pinned footer button must stay on screen")
        back.tap()
        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable)
    }
}

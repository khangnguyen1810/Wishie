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

        // The pushed screen sits on top of Login, whose elements stay in the accessibility
        // tree beneath it. The pushed screen's elements come first, so take the first match.
        let primary = app.buttons.matching(identifier: "auth.primaryButton").element(boundBy: 0)
        XCTAssertEqual(primary.label, "Send reset link")
        XCTAssertFalse(primary.isEnabled)

        let email = app.textFields.matching(identifier: "auth.field.email").element(boundBy: 0)
        type("linh@example", into: email)
        XCTAssertFalse(primary.isEnabled)

        email.typeText(".com")
        XCTAssertTrue(primary.isEnabled)
    }
}

//
//  LoginOrSignUpScreenUITests.swift
//  WishieUITests
//

import XCTest

final class LoginOrSignUpScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

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
    func testLoginButtonOpensLoginView() throws {
        let app = launchUnauthenticated()

        let login = app.buttons["auth.loginButton"]
        XCTAssertTrue(login.waitForExistence(timeout: 10))
        login.tap()

        XCTAssertTrue(app.staticTexts["Hello old friend, are you good ?"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSignUpLinkOpensSignUpView() throws {
        let app = launchUnauthenticated()

        let signUp = app.buttons["auth.signUpLink"]
        XCTAssertTrue(signUp.waitForExistence(timeout: 10))
        signUp.tap()

        XCTAssertTrue(app.staticTexts["Welcome new friend, are you good ?"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLoginButtonStaysHittableAtLargestTextSize() throws {
        let app = launchUnauthenticated(extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ])

        let login = app.buttons["auth.loginButton"]
        XCTAssertTrue(login.waitForExistence(timeout: 10))
        XCTAssertTrue(login.isHittable)
        XCTAssertTrue(app.buttons["auth.signUpLink"].isHittable)
    }
}

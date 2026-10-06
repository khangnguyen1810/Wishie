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

        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSignUpLinkOpensSignUpView() throws {
        let app = launchUnauthenticated()

        let signUp = app.buttons["auth.signUpLink"]
        XCTAssertTrue(signUp.waitForExistence(timeout: 10))
        signUp.tap()

        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))
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

    // MARK: Sway

    /// The part of the screen holding the fan, below the status bar so the clock cannot change it.
    @MainActor
    private func fanSnapshot(of app: XCUIApplication) throws -> Data {
        let image = try XCTUnwrap(app.screenshot().image.cgImage)
        let band = CGRect(x: 0, y: image.height / 8, width: image.width, height: image.height / 3)
        let cropped = try XCTUnwrap(image.cropping(to: band))
        return try XCTUnwrap(UIImage(cgImage: cropped).pngData())
    }

    /// True when the fan changes between snapshots taken over about two seconds.
    @MainActor
    private func fanIsMoving(in app: XCUIApplication) throws -> Bool {
        let first = try fanSnapshot(of: app)
        for _ in 0..<2 {
            Thread.sleep(forTimeInterval: 1)
            if try fanSnapshot(of: app) != first { return true }
        }
        return false
    }

    @MainActor
    func testFanSwaysOnFirstAppearance() throws {
        let app = launchUnauthenticated()
        XCTAssertTrue(app.buttons["auth.loginButton"].waitForExistence(timeout: 10))

        XCTAssertTrue(try fanIsMoving(in: app))
    }

    @MainActor
    func testFanKeepsSwayingAfterReturningFromLogin() throws {
        let app = launchUnauthenticated()
        let login = app.buttons["auth.loginButton"]
        XCTAssertTrue(login.waitForExistence(timeout: 10))
        login.tap()
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))

        app.buttons["auth.backButton"].tap()
        XCTAssertTrue(login.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)

        XCTAssertTrue(try fanIsMoving(in: app))
    }

    @MainActor
    func testFanKeepsSwayingAfterReturningFromSignUp() throws {
        let app = launchUnauthenticated()
        let signUp = app.buttons["auth.signUpLink"]
        XCTAssertTrue(signUp.waitForExistence(timeout: 10))
        signUp.tap()
        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))

        app.buttons["auth.backButton"].tap()
        XCTAssertTrue(signUp.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)

        XCTAssertTrue(try fanIsMoving(in: app))
    }
}

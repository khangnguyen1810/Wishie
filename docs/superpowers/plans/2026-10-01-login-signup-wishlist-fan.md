# Login / Sign up Wishlist Fan Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dark scrolling-photo Login / Sign up screen with a light screen showing three fanned wishlist cards, a large "Login" button, and a "Don't have an account? Sign up" link.

**Architecture:** A new `WishlistFanView` draws three sample wishlist cards at a fixed design size and scales the whole fan to fit its container; the sizing and angle rules live in a pure `WishlistFanLayout` enum so they are unit-testable. `LoginOrSignUpScreen` keeps its `NavigationStack` and destinations and only replaces its body: a flexible yellow stage holding the fan, then copy, then actions. The old `BackgroundAnimationView` and its eight photos are deleted.

**Tech Stack:** Swift, SwiftUI (iOS 18.5 deployment target), Swift Testing (`import Testing`, `@Test`, `#expect`) for unit tests, XCTest for UI tests, `xcodebuild`, `xcrun simctl`.

**Spec:** `docs/superpowers/specs/2026-10-01-login-signup-wishlist-fan-design.md`

## Global Constraints

- Work on branch `update/change-ui-for-login-or-signup-screen`. Run every command from `/Users/nguyenkhanghuu/Wishie`.
- The Xcode project uses file-system-synchronized groups. Create and delete files on disk only; never edit `Wishie.xcodeproj/project.pbxproj`.
- Do not modify `LoginView`, `SignUpView`, `ForgotPasswordView`, `WelcomeView`, `OnboardingContainerView`, or `WishieButton`.
- Navigation is unchanged: `path.append("login")` pushes `LoginView`, `path.append("signup")` pushes `SignUpView`, both with `.environmentObject(authViewModel)` and `.navigationBarBackButtonHidden()`.
- Colors: `Color("obScreenBg")`, `Color("obInk")`, `Color.lightYellow`, `Color(hex: GradientTheme.<case>.primary)`. No new color assets.
- Fonts: `.wishiesDisplay(.bold, size)` (Baloo 2) for titles and headline, `.wishies(.regular | .medium | .bold, size)` (Nunito) for everything else.
- Exact copy: headline `Make a list.\nShare one link.`; subtext `Friends reserve a gift, so nobody buys the same thing twice.`; button `Login`; link `Don't have an account? Sign up`; brand `Wishie`; tag `Reserved`.
- Sample wishlists: `Birthday 2026` / `12 items · 3 reserved` / `.coral`; `Housewarming` / `8 items` / `.mint`; `Tết wishlist` / `5 items` / `.grape`.
- Accessibility identifiers: `auth.loginButton`, `auth.signUpLink`.
- Fan numbers: design card width 220, design fan height 280, card width ratio 0.56, max card width 240, rest angle 14°, sway angle 17°, rotation anchor `UnitPoint(x: 0.5, y: 1.2)`, sway `easeInOut(duration: 3)` repeating forever with autoreverse.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Simulator for tests: `-destination 'platform=iOS Simulator,name=iPhone 16'`.

## Review Focus

1. **iPhone SE (short screen).** Copy and actions need about 380pt of a 667pt screen. Expected: the fan shrinks to fit the smaller stage; nothing is clipped; the Login button and link are fully visible. Pinned by the height-limited `cardWidth` unit test (Task 1) and the SE screenshot (Task 4).
2. **Coming back from `LoginView` / `SignUpView`.** `onAppear` fires again on the root view. Expected: the sway does not restart, snap, or flip direction. Pinned by the `shouldStartSway(alreadySwaying: true)` unit test (Task 1).
3. **Reduce Motion on.** Expected: cards stay still at ±14°. Pinned by the `shouldStartSway(reduceMotion: true)` unit test (Task 1) and the identical-screenshots check (Task 4).
4. **Largest Dynamic Type size.** Custom fonts scale with Dynamic Type. Expected: the Login button stays on screen and tappable. Pinned by the `testLoginButtonStaysHittableAtLargestTextSize` UI test (Task 3).
5. **Degenerate or very wide container** (the stage squeezed to zero height by large text; iPad width). Expected: scale is 0, never negative or NaN; the card never exceeds 240pt. Pinned by the empty-container and wide-container unit tests (Task 1).

## File Structure

| File | Responsibility |
|------|----------------|
| `Wishie/Screens/Auth/WishlistFanView.swift` (create) | `WishlistFanLayout` (pure sizing/angle rules), sample data, the card view, and `WishlistFanView` (fan + sway). |
| `WishieTests/WishlistFanLayoutTests.swift` (create) | Unit tests for `WishlistFanLayout`. |
| `Wishie/Screens/Auth/LoginOrSignUpScreen.swift` (rewrite) | Screen layout and navigation only. |
| `WishieUITests/LoginOrSignUpScreenUITests.swift` (create) | UI tests for navigation and large text. |
| `Wishie/Resources/Assets.xcassets/bgimg1.imageset` … `bgimg8.imageset` (delete) | Unused after the rewrite. |

---

### Task 1: `WishlistFanLayout` sizing and angle rules

**Files:**
- Create: `Wishie/Screens/Auth/WishlistFanView.swift`
- Test: `WishieTests/WishlistFanLayoutTests.swift`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum WishlistFanLayout`
  - `static let designCardWidth: CGFloat` (220), `static let designFanHeight: CGFloat` (280)
  - `enum Side { case left, right }`
  - `static func cardWidth(for container: CGSize) -> CGFloat`
  - `static func scale(for container: CGSize) -> CGFloat`
  - `static func angle(for side: Side, swayed: Bool) -> Double`
  - `static func shouldStartSway(reduceMotion: Bool, alreadySwaying: Bool) -> Bool`

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/WishlistFanLayoutTests.swift`:

```swift
//
//  WishlistFanLayoutTests.swift
//  WishieTests
//

import Testing
import CoreGraphics
@testable import Wishie

struct WishlistFanLayoutTests {
    // MARK: cardWidth

    @Test func cardWidthIs56PercentOfContainerWidthWhenHeightIsGenerous() {
        let width = WishlistFanLayout.cardWidth(for: CGSize(width: 350, height: 600))
        #expect(abs(width - 196) < 0.001)
    }

    @Test func cardWidthIsCappedAt240OnAVeryWideContainer() {
        let width = WishlistFanLayout.cardWidth(for: CGSize(width: 1000, height: 1000))
        #expect(width == 240)
    }

    @Test func cardWidthShrinksSoTheFanFitsAShortContainer() {
        // Design fan is 280 tall at card width 220, so a 140-tall container allows half of that.
        let width = WishlistFanLayout.cardWidth(for: CGSize(width: 350, height: 140))
        #expect(abs(width - 110) < 0.001)
    }

    @Test func cardWidthIsZeroForAnEmptyContainer() {
        #expect(WishlistFanLayout.cardWidth(for: .zero) == 0)
    }

    @Test func cardWidthIsZeroForANegativeContainer() {
        #expect(WishlistFanLayout.cardWidth(for: CGSize(width: -20, height: -20)) == 0)
    }

    // MARK: scale

    @Test func scaleIsCardWidthOverDesignCardWidth() {
        let scale = WishlistFanLayout.scale(for: CGSize(width: 350, height: 140))
        #expect(abs(scale - 0.5) < 0.001)
    }

    @Test func scaleIsZeroForAnEmptyContainer() {
        let scale = WishlistFanLayout.scale(for: .zero)
        #expect(scale == 0)
        #expect(scale.isFinite)
    }

    // MARK: angle

    @Test func backCardsRestAtFourteenDegreesMirrored() {
        #expect(WishlistFanLayout.angle(for: .left, swayed: false) == -14)
        #expect(WishlistFanLayout.angle(for: .right, swayed: false) == 14)
    }

    @Test func backCardsSwayToSeventeenDegreesMirrored() {
        #expect(WishlistFanLayout.angle(for: .left, swayed: true) == -17)
        #expect(WishlistFanLayout.angle(for: .right, swayed: true) == 17)
    }

    // MARK: shouldStartSway

    @Test func swayStartsOnFirstAppearWithMotionAllowed() {
        #expect(WishlistFanLayout.shouldStartSway(reduceMotion: false, alreadySwaying: false))
    }

    @Test func swayNeverStartsUnderReduceMotion() {
        #expect(!WishlistFanLayout.shouldStartSway(reduceMotion: true, alreadySwaying: false))
    }

    @Test func swayDoesNotRestartWhenTheScreenReappears() {
        #expect(!WishlistFanLayout.shouldStartSway(reduceMotion: false, alreadySwaying: true))
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistFanLayoutTests 2>&1 | tail -20
```

Expected: the build fails with `cannot find 'WishlistFanLayout' in scope`.

- [ ] **Step 3: Write the minimal implementation**

Create `Wishie/Screens/Auth/WishlistFanView.swift`:

```swift
//
//  WishlistFanView.swift
//  Wishie
//

import SwiftUI

/// Sizing and angle rules for the fanned sample wishlists on the auth screen.
/// Kept free of view state so the rules can be unit tested.
enum WishlistFanLayout {
    enum Side {
        case left
        case right
    }

    /// The fan is drawn at this card width, then scaled as one unit to fit its container.
    static let designCardWidth: CGFloat = 220
    /// Height of the whole fan (front card plus the rotated back cards) at `designCardWidth`.
    static let designFanHeight: CGFloat = 280

    static let cardWidthRatio: CGFloat = 0.56
    static let maxCardWidth: CGFloat = 240
    static let restAngle: Double = 14
    static let swayAngle: Double = 17

    static func cardWidth(for container: CGSize) -> CGFloat {
        let byWidth = container.width * cardWidthRatio
        let byHeight = designCardWidth * container.height / designFanHeight
        return max(0, min(byWidth, byHeight, maxCardWidth))
    }

    static func scale(for container: CGSize) -> CGFloat {
        cardWidth(for: container) / designCardWidth
    }

    static func angle(for side: Side, swayed: Bool) -> Double {
        let magnitude = swayed ? swayAngle : restAngle
        return side == .left ? -magnitude : magnitude
    }

    static func shouldStartSway(reduceMotion: Bool, alreadySwaying: Bool) -> Bool {
        !reduceMotion && !alreadySwaying
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run:

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/WishlistFanLayoutTests 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **`, 12 tests passed.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/Auth/WishlistFanView.swift WishieTests/WishlistFanLayoutTests.swift
git commit -m "feat: add WishlistFanLayout sizing and angle rules

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: `WishlistFanView` cards and sway

**Files:**
- Modify: `Wishie/Screens/Auth/WishlistFanView.swift` (append below `WishlistFanLayout`)

**Interfaces:**
- Consumes: `WishlistFanLayout` (Task 1); `GradientTheme` (`Wishie/Models/GradientWishlishTheme.swift`, `var primary: String` hex); `Color(hex:)` and `Color.lightened(by:)` (`Wishie/Helper/ColorExtension.swift`); `Font.wishies(_:_:)` and `Font.wishiesDisplay(_:_:)` (`Wishie/Resources/WishieCustomFont.swift`).
- Produces: `struct WishlistFanView: View` with a no-argument `init()`. It fills whatever frame its parent gives it and centers the fan inside.

This task has no unit test of its own: the logic it uses is covered in Task 1 and its appearance is checked by screenshot in Task 4. Its gate here is a clean build.

- [ ] **Step 1: Append the sample data, card view, and fan view**

Append to `Wishie/Screens/Auth/WishlistFanView.swift`:

```swift

// MARK: - Sample data

private struct SampleWishlist {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let reserved: Bool
    }

    let title: String
    let subtitle: String
    let theme: GradientTheme
    let items: [Item]

    static let front = SampleWishlist(
        title: "Birthday 2026",
        subtitle: "12 items · 3 reserved",
        theme: .coral,
        items: [
            Item(name: "AirPods Pro", reserved: true),
            Item(name: "Lego Orchid", reserved: false),
            Item(name: "Film camera", reserved: false),
            Item(name: "Running shoes", reserved: true),
        ]
    )

    static let backLeft = SampleWishlist(
        title: "Housewarming",
        subtitle: "8 items",
        theme: .mint,
        items: [
            Item(name: "Moka pot", reserved: false),
            Item(name: "Desk lamp", reserved: false),
            Item(name: "Linen set", reserved: false),
        ]
    )

    static let backRight = SampleWishlist(
        title: "Tết wishlist",
        subtitle: "5 items",
        theme: .grape,
        items: [
            Item(name: "Kindle", reserved: false),
            Item(name: "Tea set", reserved: false),
            Item(name: "Sketchbook", reserved: false),
        ]
    )
}

// MARK: - Card

/// One sample wishlist, styled after `HomeItemViewCell` so it previews what Home looks like.
private struct SampleWishlistCard: View {
    let wishlist: SampleWishlist

    private var tint: Color {
        Color(hex: wishlist.theme.primary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(wishlist.title)
                .font(.wishiesDisplay(.bold, 18))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(wishlist.subtitle)
                .font(.wishies(.medium, 12))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
            ForEach(wishlist.items) { item in
                row(for: item)
            }
        }
        .padding(14)
        .frame(width: WishlistFanLayout.designCardWidth, alignment: .leading)
        .background {
            tint
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 90, height: 90)
                        .offset(x: 30, y: -30)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .offset(x: -14, y: 14)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: tint.opacity(0.45), radius: 12, x: 0, y: 6)
    }

    private func row(for item: SampleWishlist.Item) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 7)
                .fill(tint.lightened(by: 0.6))
                .frame(width: 24, height: 24)
            Text(item.name)
                .font(.wishies(.bold, 13))
                .foregroundStyle(Color("obInk"))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            if item.reserved {
                Text("Reserved")
                    .font(.wishies(.bold, 10))
                    .foregroundStyle(Color.lightYellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color("obInk")))
                    .fixedSize()
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
    }
}

// MARK: - Fan

/// Three sample wishlists fanned out, the two at the back swaying gently.
/// Decorative: hidden from VoiceOver and unaffected by Dynamic Type.
struct WishlistFanView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swayed = false

    /// Below each back card's bottom edge, so the cards fan out sideways instead of spinning in place.
    private let fanAnchor = UnitPoint(x: 0.5, y: 1.2)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                SampleWishlistCard(wishlist: .backLeft)
                    .offset(y: 14)
                    .rotationEffect(
                        .degrees(WishlistFanLayout.angle(for: .left, swayed: swayed)),
                        anchor: fanAnchor
                    )
                SampleWishlistCard(wishlist: .backRight)
                    .offset(y: 14)
                    .rotationEffect(
                        .degrees(WishlistFanLayout.angle(for: .right, swayed: swayed)),
                        anchor: fanAnchor
                    )
                SampleWishlistCard(wishlist: .front)
            }
            .scaleEffect(WishlistFanLayout.scale(for: geo.size))
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .dynamicTypeSize(.large)
        .accessibilityHidden(true)
        .onAppear {
            guard WishlistFanLayout.shouldStartSway(reduceMotion: reduceMotion, alreadySwaying: swayed) else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                swayed = true
            }
        }
    }
}

#Preview {
    WishlistFanView()
        .padding()
        .background(Color.lightYellow)
}
```

- [ ] **Step 2: Build to verify it compiles**

Run:

```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add Wishie/Screens/Auth/WishlistFanView.swift
git commit -m "feat: add WishlistFanView with fanned sample wishlist cards

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Rewrite `LoginOrSignUpScreen`

**Files:**
- Modify: `Wishie/Screens/Auth/LoginOrSignUpScreen.swift` (replace the whole file)
- Test: `WishieUITests/LoginOrSignUpScreenUITests.swift` (create)

**Interfaces:**
- Consumes: `WishlistFanView()` (Task 2); `WishieButton(title:enabled:filColor:titleColor:action:)` (`Wishie/CustomView/WishieButton.swift`; the parameter really is spelled `filColor`); `LoginView()`, `SignUpView()`, `AuthViewModel`.
- Produces: `struct LoginOrSignUpScreen: View` with the same no-argument `init()` and the same `@EnvironmentObject var authViewModel: AuthViewModel` requirement as today, so `MainView` needs no change. Accessibility identifiers `auth.loginButton` and `auth.signUpLink`.

How the UI tests reach this screen: `RootNavigationCoordinator.deriveAppState` returns `.unauthenticated` when `hasCompletedOnboarding` is true and the `userid` default is empty. Launch arguments of the form `-key value` override `UserDefaults.standard` for that launch, so the tests force that state without touching stored data.

- [ ] **Step 1: Write the failing UI tests**

Create `WishieUITests/LoginOrSignUpScreenUITests.swift`:

```swift
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
```

- [ ] **Step 2: Run the UI tests to verify they fail**

Run:

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/LoginOrSignUpScreenUITests 2>&1 | tail -25
```

Expected: `** TEST FAILED **`. All three tests fail at `XCTAssertTrue(login.waitForExistence…)` / `signUp.waitForExistence…` because no element has the identifier `auth.loginButton` or `auth.signUpLink` yet.

If instead they fail because the app shows Home or onboarding, the launch-argument override did not take effect: erase the simulator (`xcrun simctl erase "iPhone 16"`), rerun, and report this in the task summary.

- [ ] **Step 3: Replace the screen**

Replace the entire contents of `Wishie/Screens/Auth/LoginOrSignUpScreen.swift` with:

```swift
//
//  LoginOrSignUpScreen.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 7/10/25.
//

import SwiftUI

struct LoginOrSignUpScreen: View {
    @State private var path = NavigationPath()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                stage
                copy
                    .padding(.top, 24)
                Spacer(minLength: 16)
                actions
                    .layoutPriority(1)
            }
            .safeAreaPadding(.bottom, 40)
            .background {
                Color("obScreenBg")
                    .ignoresSafeArea()
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .navigationDestination(for: String.self) { path in
                switch(path) {
                case "login":
                    LoginView()
                        .environmentObject(authViewModel)
                        .navigationBarBackButtonHidden()
                case "signup":
                    SignUpView()
                        .environmentObject(authViewModel)
                        .navigationBarBackButtonHidden()
                default:
                    ContentUnavailableView("Login Screen", systemImage: "person.fill")
                }
            }
        }
    }

    /// Yellow area holding the fanned sample wishlists. Takes whatever height the copy and actions leave.
    private var stage: some View {
        WishlistFanView()
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                UnevenRoundedRectangle(bottomLeadingRadius: 44, bottomTrailingRadius: 44)
                    .fill(Color.lightYellow)
                    .ignoresSafeArea(edges: .top)
            }
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image("pen")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                Text("Wishie")
                    .font(.wishiesDisplay(.bold, 18))
                    .foregroundStyle(Color("obInk"))
            }
            Text("Make a list.\nShare one link.")
                .font(.wishiesDisplay(.bold, 32))
                .foregroundStyle(Color("obInk"))
                .minimumScaleFactor(0.8)
            Text("Friends reserve a gift, so nobody buys the same thing twice.")
                .font(.wishies(.regular, 16))
                .foregroundStyle(Color("obInk").opacity(0.7))
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 30)
    }

    private var actions: some View {
        VStack(spacing: 6) {
            WishieButton(
                title: "Login",
                enabled: true,
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                path.append("login")
            }
            .accessibilityIdentifier("auth.loginButton")

            Button {
                path.append("signup")
            } label: {
                Text("Don't have an account? \(Text("Sign up").font(.wishies(.bold, 15)).underline())")
                    .font(.wishies(.regular, 15))
                    .foregroundStyle(Color("obInk"))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("auth.signUpLink")
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    LoginOrSignUpScreen()
        .environmentObject(AuthViewModel())
}
```

This removes `listImage`, `listImage2`, and the whole `BackgroundAnimationView` struct.

- [ ] **Step 4: Run the UI tests to verify they pass**

Run:

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/LoginOrSignUpScreenUITests 2>&1 | tail -25
```

Expected: `** TEST SUCCEEDED **`, 3 tests passed.

- [ ] **Step 5: Confirm the old scrolling view is gone**

Run:

```bash
grep -rn "BackgroundAnimationView\|listImage" --include="*.swift" Wishie WishieTests WishieUITests
```

Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/Auth/LoginOrSignUpScreen.swift WishieUITests/LoginOrSignUpScreenUITests.swift
git commit -m "feat: redesign login/sign up screen with fanned wishlist cards

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Delete the unused photos and verify on device sizes

**Files:**
- Delete: `Wishie/Resources/Assets.xcassets/bgimg1.imageset` through `bgimg8.imageset`

**Interfaces:**
- Consumes: the finished screen from Task 3.
- Produces: nothing for later tasks.

- [ ] **Step 1: Confirm nothing references the photos**

Run:

```bash
grep -rn "bgimg" --include="*.swift" Wishie WishieTests WishieUITests
```

Expected: no output. If anything prints, stop and report it; do not delete the assets.

- [ ] **Step 2: Delete the eight imagesets**

```bash
git rm -r -q Wishie/Resources/Assets.xcassets/bgimg1.imageset Wishie/Resources/Assets.xcassets/bgimg2.imageset Wishie/Resources/Assets.xcassets/bgimg3.imageset Wishie/Resources/Assets.xcassets/bgimg4.imageset Wishie/Resources/Assets.xcassets/bgimg5.imageset Wishie/Resources/Assets.xcassets/bgimg6.imageset Wishie/Resources/Assets.xcassets/bgimg7.imageset Wishie/Resources/Assets.xcassets/bgimg8.imageset
ls Wishie/Resources/Assets.xcassets | grep bgimg
```

Expected: the `ls | grep` prints nothing.

- [ ] **Step 3: Run the full unit-test suite**

Run:

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests 2>&1 | tail -15
```

Expected: `** TEST SUCCEEDED **`. If a test unrelated to this work fails, rerun it on `develop` to see whether it was already failing, and report which.

- [ ] **Step 4: Screenshot the screen on iPhone SE and iPhone 16 Pro Max**

Run:

```bash
set -e
DD=/tmp/wishie-auth-dd
for DEVICE in "iPhone SE (3rd generation)" "iPhone 16 Pro Max"; do
  UDID=$(xcrun simctl list devices available | grep -F "$DEVICE (" | head -1 | grep -oE "[0-9A-F]{8}-[0-9A-F-]{27}")
  SLUG=$(echo "$DEVICE" | tr -cd '[:alnum:]')
  xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination "id=$UDID" -derivedDataPath "$DD" 2>&1 | tail -1
  APP="$DD/Build/Products/Debug-iphonesimulator/Wishie.app"
  BUNDLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$APP/Info.plist")
  xcrun simctl boot "$UDID" 2>/dev/null || true
  xcrun simctl bootstatus "$UDID" >/dev/null
  xcrun simctl status_bar "$UDID" override --time "9:41"
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" -hasCompletedOnboarding YES -userid "" >/dev/null
  sleep 4
  xcrun simctl io "$UDID" screenshot "/tmp/wishie-auth-$SLUG.png"
  echo "$DEVICE -> /tmp/wishie-auth-$SLUG.png (udid $UDID, bundle $BUNDLE)"
done
```

Expected: two lines ending in `/tmp/wishie-auth-iPhoneSE3rdgeneration.png` and `/tmp/wishie-auth-iPhone16ProMax.png`.

- [ ] **Step 5: Inspect both screenshots**

Open both PNG files and check each against this list:

- Yellow stage at the top with rounded bottom corners, running up under the status bar.
- Three cards: coral "Birthday 2026" upright in front, mint "Housewarming" fanned to the left behind it, purple "Tết wishlist" fanned to the right. No card is cut off by the stage's bottom edge or the screen's side edges.
- Front card shows four rows; "AirPods Pro" and "Running shoes" carry a dark "Reserved" tag.
- Below the stage, left-aligned: small logo and "Wishie", then "Make a list. / Share one link." on two lines, then the subtext.
- A full-width dark "Login" button with white text, and under it "Don't have an account? Sign up" with "Sign up" bold and underlined.
- Nothing overlaps; nothing is truncated with "…" except, at most, the item name "Running shoes".

If the fan is clipped or overflows the stage vertically on either device, the fan is taller than 280pt at design size. Do not patch it with offsets or extra padding: raise `WishlistFanLayout.designFanHeight` to the real height, update the two unit tests that depend on it (`cardWidthShrinksSoTheFanFitsAShortContainer`, `scaleIsCardWidthOverDesignCardWidth`) so their expected values follow the new constant, rerun Task 1 Step 4, and repeat Steps 4–5 here.

- [ ] **Step 6: Verify the cards move, and stop under Reduce Motion**

Run (reuses the iPhone 16 Pro Max simulator from Step 4):

```bash
UDID=$(xcrun simctl list devices available | grep -F "iPhone 16 Pro Max (" | head -1 | grep -oE "[0-9A-F]{8}-[0-9A-F-]{27}")
BUNDLE=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" /tmp/wishie-auth-dd/Build/Products/Debug-iphonesimulator/Wishie.app/Info.plist)

shoot_pair() {
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE" -hasCompletedOnboarding YES -userid "" >/dev/null
  sleep 4
  xcrun simctl io "$UDID" screenshot "/tmp/wishie-motion-$1-a.png" 2>/dev/null
  sleep 1.5
  xcrun simctl io "$UDID" screenshot "/tmp/wishie-motion-$1-b.png" 2>/dev/null
  if cmp -s "/tmp/wishie-motion-$1-a.png" "/tmp/wishie-motion-$1-b.png"; then echo "$1: identical"; else echo "$1: different"; fi
}

xcrun simctl spawn "$UDID" defaults write com.apple.Accessibility ReduceMotionEnabled -bool NO
shoot_pair motion-on
xcrun simctl spawn "$UDID" defaults write com.apple.Accessibility ReduceMotionEnabled -bool YES
shoot_pair motion-off
xcrun simctl spawn "$UDID" defaults write com.apple.Accessibility ReduceMotionEnabled -bool NO
xcrun simctl status_bar "$UDID" clear
```

Expected:

```
motion-on: different
motion-off: identical
```

If `motion-off` prints `different`, the simulator may not have picked up the setting from `defaults`. Turn it on by hand in the simulator (Settings → Accessibility → Motion → Reduce Motion), rerun only the `shoot_pair motion-off` line, and report which method was needed. If it is still `different`, the guard in `WishlistFanView.onAppear` is wrong; fix it before continuing.

- [ ] **Step 7: Commit**

```bash
git add -A Wishie/Resources/Assets.xcassets
git commit -m "chore: remove unused auth background photos

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

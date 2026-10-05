# Auth Form Screens: Yellow Stage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild Login, Sign up, Create password and Forgot password on one shared scaffold and field component so they match the landing screen.

**Architecture:** Five new files in `Wishie/Screens/Auth/` hold everything the four screens share: `AuthValidation` (pure rules, unit tested), `AuthField`, `AuthBirthdayField`, `AuthSocialSection` and `AuthScaffold`. Each screen file is rewritten to declare only its fields, copy and actions. Navigation, `AuthViewModel` and the API layer are not touched.

**Tech Stack:** Swift, SwiftUI (iOS 18.5 deployment target), Swift Testing (`import Testing`, `@Test`, `#expect`) for unit tests, XCTest for UI tests, `xcodebuild`, `xcrun simctl`.

**Spec:** `docs/superpowers/specs/2026-10-05-auth-screens-yellow-stage-design.md`

## Global Constraints

- Work on branch `update/auth-screens-yellow-stage`. Run every command from `/Users/nguyenkhanghuu/Wishie`.
- The Xcode project uses file-system-synchronized groups. Create and delete files on disk only; never edit `Wishie.xcodeproj/project.pbxproj`.
- Do not modify `LoginOrSignUpScreen.swift`, `AuthViewModel.swift`, `AuthenticateService.swift`, `DateInputView.swift`, `WishieButton.swift`, `DialogView.swift`, or anything under `Wishie/Models`, `Wishie/Networking`, `Wishie/Services`.
- In `WishlistFanView.swift`, change only what Task 3 lists. The fan layout and sway are not changed.
- Navigation is unchanged: `LoginOrSignUpScreen` pushes `LoginView` / `SignUpView`; `LoginView` pushes `ForgotPasswordView`; `SignUpView` pushes `PasswordSignUpView`; every destination keeps `.navigationBarBackButtonHidden()`.
- Colors: `Color("obScreenBg")`, `Color("obInk")`, `Color("obError")` (new, `#B3261E`), `Color.lightYellow`, `Color.white`. No other colors.
- Fonts: `.wishiesDisplay(.bold, size)` (Baloo 2) for the title only; `.wishies(.regular | .medium | .bold | .italic, size)` (Nunito) for everything else.
- Exact copy:
  - Login: `Welcome back.` / `Log in to see your lists.` / `Forgot password?` / `Log in`
  - Sign up: `Create your account.` / `It takes a minute.` / `Continue`
  - Create password: `Pick a password.` / `Last step, <first name>.` or `Last step.` / `At least 8 characters` / `Create account`
  - Forgot password: `Reset your password.` / `We will email you a link.` / `Send reset link`
  - Shared: `or`, `Continue with Google`, `Enter a valid email address.`, field labels `Email`, `Password`, `First name`, `Last name`, `Phone`, `Birthday`
- Accessibility identifiers: `auth.backButton`, `auth.primaryButton`, `auth.googleButton`, `auth.forgotPasswordLink`, `auth.passwordRule`, `auth.emailError`, titles `auth.login.title` / `auth.signup.title` / `auth.password.title` / `auth.forgot.title`, fields `auth.field.email` / `auth.field.password` / `auth.field.firstName` / `auth.field.lastName` / `auth.field.phone` / `auth.field.birthday`.
- Sizes: stage bottom radius 44; body horizontal padding 30; field min height 56, radius 16; primary and Google buttons height 60, radius 20; back button 44×44.
- Minimum password length: 8, counted on the text as typed (not trimmed).
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Simulator for tests: `-destination 'platform=iOS Simulator,name=iPhone 16'`.

## Review Focus

1. **Email with spaces around it** (autofill and paste often add one). Expected: treated as valid, no inline error, button enabled. Pinned by `AuthValidationTests` (Task 1).
2. **First name that is only spaces.** Expected: the Create password subtitle reads `Last step.`, never `Last step,  .`. Pinned by `AuthValidationTests` (Task 1).
3. **Inline error while still typing.** Expected: no error while the email field has focus; it appears only after focus leaves. Depends on the screen's `.focused` binding reaching the text field inside `AuthField`. Pinned by `testLoginShowsEmailErrorOnlyAfterLeavingTheField` (Task 4).
4. **Going back from Create password to Sign up.** Expected: everything typed on Sign up is still there. Pinned by `testSignUpKeepsValuesAfterReturningFromPassword` (Task 5).
5. **Largest Dynamic Type size.** Expected: the back button and the pinned primary button stay on screen and tappable on all four screens. Pinned by `testBackButtonStaysHittableAtLargestTextSize` (Task 6).

## File Structure

| File | Responsibility |
|------|----------------|
| `Wishie/Screens/Auth/AuthValidation.swift` (create) | Pure rules: button-enabled, error-visible, password length, Create password subtitle. |
| `Wishie/Screens/Auth/AuthField.swift` (create) | `InputFieldType`, `AuthFieldKind`, the field chrome modifier, `AuthField`. |
| `Wishie/Screens/Auth/AuthBirthdayField.swift` (create) | Birthday field and its picker sheet. |
| `Wishie/Screens/Auth/AuthSocialSection.swift` (create) | "or" divider and Google button. |
| `Wishie/Screens/Auth/AuthScaffold.swift` (create) | Stage, decorative card, pinned back button, scrolling body, pinned footer. |
| `Wishie/Screens/Auth/WishlistFanView.swift` (modify) | Sample data and card become internal; gold sample and theme lookup added. |
| `Wishie/Screens/Auth/LoginView.swift`, `ForgotPasswordView.swift`, `SignUpView.swift`, `PasswordSignUpView.swift` (rewrite) | One screen each. |
| `Wishie/Resources/CustomView/PasswordField.swift` (delete) | Replaced by `AuthField`. |
| `Wishie/Resources/Assets.xcassets/obError.colorset/Contents.json` (create) | Error color. |
| `WishieTests/AuthValidationTests.swift`, `WishieTests/SampleWishlistTests.swift` (create) | Unit tests. |
| `WishieUITests/AuthFormScreensUITests.swift` (create) | UI tests for the four screens. |
| `WishieUITests/LoginOrSignUpScreenUITests.swift` (modify) | Stop matching old headline strings. |

---

### Task 1: `AuthValidation`

**Files:**
- Create: `Wishie/Screens/Auth/AuthValidation.swift`
- Test: `WishieTests/AuthValidationTests.swift`

**Interfaces:**
- Consumes: `StringUtils.isValidEmail(_ email: String) -> Bool` (existing, trims its input).
- Produces:
  - `AuthValidation.minimumPasswordLength: Int` (8)
  - `AuthValidation.emailErrorMessage: String`
  - `AuthValidation.showsEmailError(email: String, isFocused: Bool) -> Bool`
  - `AuthValidation.canLogIn(email: String, password: String) -> Bool`
  - `AuthValidation.canContinueSignUp(email: String, phone: String) -> Bool`
  - `AuthValidation.isPasswordLongEnough(_ password: String) -> Bool`
  - `AuthValidation.canSendReset(email: String) -> Bool`
  - `AuthValidation.passwordSubtitle(firstName: String) -> String`

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/AuthValidationTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthValidationTests 2>&1 | tail -20
```

Expected: the build fails with `cannot find 'AuthValidation' in scope`.

- [ ] **Step 3: Write the implementation**

Create `Wishie/Screens/Auth/AuthValidation.swift`:

```swift
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
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/AuthValidationTests 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **`, 21 tests passed.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/Auth/AuthValidation.swift WishieTests/AuthValidationTests.swift
git commit -m "feat: add AuthValidation rules for the auth forms

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Field components (`AuthField`, `AuthBirthdayField`, `AuthSocialSection`, `obError`)

These are views with no logic of their own; the rules they display are tested in Task 1 and their behavior is tested through the screens in Tasks 4 and 5. This task is verified by a clean build.

**Files:**
- Create: `Wishie/Resources/Assets.xcassets/obError.colorset/Contents.json`
- Create: `Wishie/Screens/Auth/AuthField.swift`
- Create: `Wishie/Screens/Auth/AuthBirthdayField.swift`
- Create: `Wishie/Screens/Auth/AuthSocialSection.swift`
- Modify: `Wishie/Screens/Auth/LoginView.swift:9-15` (remove the `InputFieldType` enum; it moves to `AuthField.swift`)

**Interfaces:**
- Consumes: `WishieButton(title:enabled:filColor:titleColor:action:)`, `View.hideKeyboard()`, image assets `eye-solid-full`, `eye-slash-solid-full`, `google_icon` (all existing).
- Produces:
  - `enum InputFieldType { case firstName, lastName, email, password, phone }` (moved, unchanged)
  - `enum AuthFieldKind: Equatable { case firstName, lastName, email, phone, password(isNew: Bool) }`
  - `AuthField(_ label: String, text: Binding<String>, kind: AuthFieldKind, error: String? = nil)`
  - `AuthBirthdayField(date: Binding<Date>)`
  - `AuthSocialSection(action: @escaping () -> Void)`
  - `View.authFieldChrome(_ state: AuthFieldChromeState)` with `enum AuthFieldChromeState { case idle, focused, error }`

- [ ] **Step 1: Add the error color**

Create `Wishie/Resources/Assets.xcassets/obError.colorset/Contents.json`:

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x1E",
          "green" : "0x26",
          "red" : "0xB3"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0x1E",
          "green" : "0x26",
          "red" : "0xB3"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 2: Create `AuthField.swift` and move `InputFieldType` into it**

Delete these lines from `Wishie/Screens/Auth/LoginView.swift` (leave `import SwiftUI` and everything else in the file as it is):

```swift
enum InputFieldType {
    case firstName
    case lastName
    case email
    case password
    case phone
}
```

Create `Wishie/Screens/Auth/AuthField.swift`:

```swift
//
//  AuthField.swift
//  Wishie
//

import SwiftUI

/// Which auth text field has keyboard focus. Screens use it with `@FocusState`.
enum InputFieldType {
    case firstName
    case lastName
    case email
    case password
    case phone
}

/// What an `AuthField` holds. Decides its keyboard, autofill behavior and identifiers.
enum AuthFieldKind: Equatable {
    case firstName
    case lastName
    case email
    case phone
    /// `isNew` asks iOS to offer saving a new password rather than filling a saved one.
    case password(isNew: Bool)

    var id: String {
        switch self {
        case .firstName: "firstName"
        case .lastName: "lastName"
        case .email: "email"
        case .phone: "phone"
        case .password: "password"
        }
    }

    var isPassword: Bool {
        if case .password = self { return true }
        return false
    }

    var keyboardType: UIKeyboardType {
        switch self {
        case .email: .emailAddress
        case .phone: .phonePad
        case .firstName, .lastName, .password: .default
        }
    }

    var contentType: UITextContentType {
        switch self {
        case .firstName: .givenName
        case .lastName: .familyName
        case .email: .emailAddress
        case .phone: .telephoneNumber
        case .password(let isNew): isNew ? .newPassword : .password
        }
    }

    var capitalization: TextInputAutocapitalization {
        switch self {
        case .firstName, .lastName: .words
        case .email, .phone, .password: .never
        }
    }
}

enum AuthFieldChromeState {
    case idle
    case focused
    case error
}

/// The white rounded box shared by every auth field, with its idle, focused and error borders.
private struct AuthFieldChrome: ViewModifier {
    let state: AuthFieldChromeState

    private var borderColor: Color {
        switch state {
        case .idle: Color("obInk").opacity(0.12)
        case .focused: Color("obInk")
        case .error: Color("obError")
        }
    }

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(borderColor, lineWidth: state == .idle ? 1.5 : 2)
            }
            .background {
                if state == .focused {
                    RoundedRectangle(cornerRadius: 19)
                        .fill(Color.lightYellow)
                        .padding(-3)
                }
            }
    }
}

extension View {
    func authFieldChrome(_ state: AuthFieldChromeState) -> some View {
        modifier(AuthFieldChrome(state: state))
    }
}

/// A labeled text field for the auth screens. Shows a focus ring while editing and an inline
/// message when `error` is set. The password kinds add a show/hide button.
struct AuthField: View {
    let label: String
    @Binding var text: String
    let kind: AuthFieldKind
    var error: String?

    /// Drives the border only. Screens attach their own `.focused` to move between fields.
    @FocusState private var isFocused: Bool
    @State private var isRevealed = false

    init(_ label: String, text: Binding<String>, kind: AuthFieldKind, error: String? = nil) {
        self.label = label
        self._text = text
        self.kind = kind
        self.error = error
    }

    private var chromeState: AuthFieldChromeState {
        if error != nil { return .error }
        return isFocused ? .focused : .idle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.wishies(.bold, 15))
                .foregroundStyle(Color("obInk"))
                .accessibilityHidden(true)
            HStack(spacing: 8) {
                input
                if kind.isPassword {
                    revealButton
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, kind.isPassword ? 4 : 16)
            .frame(minHeight: 56)
            .authFieldChrome(chromeState)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            if let error {
                Text(error)
                    .font(.wishies(.medium, 13))
                    .foregroundStyle(Color("obError"))
                    .accessibilityIdentifier("auth.\(kind.id)Error")
            }
        }
    }

    private var input: some View {
        Group {
            if kind.isPassword && !isRevealed {
                SecureField("", text: $text)
            } else {
                TextField("", text: $text)
            }
        }
        .focused($isFocused)
        .font(.wishies(.regular, 17))
        .foregroundStyle(Color("obInk"))
        .keyboardType(kind.keyboardType)
        .textContentType(kind.contentType)
        .textInputAutocapitalization(kind.capitalization)
        .autocorrectionDisabled()
        .accessibilityLabel(label)
        .accessibilityHint(error ?? "")
        .accessibilityIdentifier("auth.field.\(kind.id)")
    }

    private var revealButton: some View {
        Button {
            // Swapping SecureField and TextField drops focus, so hand it back.
            let wasFocused = isFocused
            isRevealed.toggle()
            if wasFocused {
                DispatchQueue.main.async {
                    isFocused = true
                }
            }
        } label: {
            Image(isRevealed ? "eye-slash-solid-full" : "eye-solid-full")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
    }
}

#Preview {
    VStack(spacing: 18) {
        AuthField("Email", text: .constant("linh@example.com"), kind: .email)
        AuthField("Email", text: .constant("linh@example"), kind: .email, error: AuthValidation.emailErrorMessage)
        AuthField("Password", text: .constant("secret123"), kind: .password(isNew: false))
    }
    .padding(30)
    .background(Color("obScreenBg"))
}
```

- [ ] **Step 3: Create `AuthBirthdayField.swift`**

```swift
//
//  AuthBirthdayField.swift
//  Wishie
//

import SwiftUI

/// The Sign up birthday field. Looks like an `AuthField`; tapping it opens a date picker sheet.
struct AuthBirthdayField: View {
    @Binding var date: Date

    @State private var showPicker = false
    /// The picker edits a copy, so the binding changes only when Done is tapped.
    @State private var draft = Date()

    private var formattedDate: String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Birthday")
                .font(.wishies(.bold, 15))
                .foregroundStyle(Color("obInk"))
                .accessibilityHidden(true)
            Button {
                hideKeyboard()
                draft = date
                showPicker = true
            } label: {
                Text(formattedDate)
                    .font(.wishies(.regular, 17))
                    .foregroundStyle(Color("obInk"))
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(.horizontal, 16)
                    .authFieldChrome(showPicker ? .focused : .idle)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Birthday")
            .accessibilityValue(formattedDate)
            .accessibilityIdentifier("auth.field.birthday")
        }
        .sheet(isPresented: $showPicker) {
            VStack(spacing: 16) {
                DatePicker("Birthday", selection: $draft, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                WishieButton(
                    title: "Done",
                    enabled: true,
                    filColor: Color("obInk"),
                    titleColor: .white
                ) {
                    date = draft
                    showPicker = false
                }
                .accessibilityIdentifier("auth.birthdayDoneButton")
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            .presentationDetents([.height(340)])
            .presentationBackground(Color("obScreenBg"))
        }
    }
}

#Preview {
    AuthBirthdayField(date: .constant(Date()))
        .padding(30)
        .background(Color("obScreenBg"))
}
```

- [ ] **Step 4: Create `AuthSocialSection.swift`**

```swift
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
```

- [ ] **Step 5: Build**

```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`. `LoginView`, `SignUpView` and `PasswordSignUpView` still compile because `InputFieldType` is in the same module.

- [ ] **Step 6: Commit**

```bash
git add Wishie/Resources/Assets.xcassets/obError.colorset Wishie/Screens/Auth/AuthField.swift Wishie/Screens/Auth/AuthBirthdayField.swift Wishie/Screens/Auth/AuthSocialSection.swift Wishie/Screens/Auth/LoginView.swift
git commit -m "feat: add shared auth field components

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Sample card lookup and `AuthScaffold`

**Files:**
- Modify: `Wishie/Screens/Auth/WishlistFanView.swift:54-101` (sample data), `:104` (card access level)
- Create: `Wishie/Screens/Auth/AuthScaffold.swift`
- Test: `WishieTests/SampleWishlistTests.swift`

**Interfaces:**
- Consumes: `WishlistFanLayout.designCardWidth` (220), `GradientTheme` cases `.coral`, `.mint`, `.grape`, `.gold`, `.green`, `View.hideKeyboard()`.
- Produces:
  - `SampleWishlist` (internal) with `static func sample(for theme: GradientTheme) -> SampleWishlist` and `static let wedding`
  - `SampleWishlistCard(wishlist: SampleWishlist)` (internal)
  - `AuthScaffold(screenID: String, title: String, subtitle: String, cardTheme: GradientTheme, content: () -> Content, footer: () -> Footer)`
  - `AuthScaffold(screenID:title:subtitle:cardTheme:content:)` when there is no footer

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/SampleWishlistTests.swift`:

```swift
//
//  SampleWishlistTests.swift
//  WishieTests
//

import Testing
@testable import Wishie

struct SampleWishlistTests {
    @Test func eachAuthScreenThemeHasASampleInThatTheme() {
        for theme in [GradientTheme.coral, .mint, .grape, .gold] {
            #expect(SampleWishlist.sample(for: theme).theme == theme)
        }
    }

    @Test func sampleTitlesMatchTheSpec() {
        #expect(SampleWishlist.sample(for: .coral).title == "Birthday 2026")
        #expect(SampleWishlist.sample(for: .mint).title == "Housewarming")
        #expect(SampleWishlist.sample(for: .grape).title == "Tết wishlist")
        #expect(SampleWishlist.sample(for: .gold).title == "Wedding")
    }

    @Test func weddingSampleHasThreeUnreservedItems() {
        let wedding = SampleWishlist.sample(for: .gold)
        #expect(wedding.subtitle == "10 items")
        #expect(wedding.items.map(\.name) == ["Dinner set", "Wine glasses", "Photo frame"])
        #expect(wedding.items.allSatisfy { !$0.reserved })
    }

    @Test func aThemeWithoutItsOwnSampleFallsBackToTheFrontCard() {
        #expect(SampleWishlist.sample(for: .green).title == "Birthday 2026")
    }
}
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/SampleWishlistTests 2>&1 | tail -20
```

Expected: the build fails with `'SampleWishlist' is inaccessible due to 'private' protection level`.

- [ ] **Step 3: Open up the sample data and add the gold sample**

In `Wishie/Screens/Auth/WishlistFanView.swift`:

Change `private struct SampleWishlist {` to `struct SampleWishlist {`.

Change `private struct SampleWishlistCard: View {` to `struct SampleWishlistCard: View {`.

Inside `SampleWishlist`, directly after the `backRight` constant, add:

```swift

    static let wedding = SampleWishlist(
        title: "Wedding",
        subtitle: "10 items",
        theme: .gold,
        items: [
            Item(name: "Dinner set", reserved: false),
            Item(name: "Wine glasses", reserved: false),
            Item(name: "Photo frame", reserved: false),
        ]
    )

    /// The sample drawn in that theme. The auth form screens show one each as decoration.
    static func sample(for theme: GradientTheme) -> SampleWishlist {
        switch theme {
        case .coral: front
        case .mint: backLeft
        case .grape: backRight
        case .gold: wedding
        case .green: front
        }
    }
```

Change nothing else in this file.

- [ ] **Step 4: Run the tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/SampleWishlistTests -only-testing:WishieTests/WishlistFanLayoutTests 2>&1 | tail -20
```

Expected: `** TEST SUCCEEDED **`. The 4 new tests and the existing fan layout tests pass.

- [ ] **Step 5: Create `AuthScaffold.swift`**

```swift
//
//  AuthScaffold.swift
//  Wishie
//

import SwiftUI

/// The frame shared by the auth form screens: a yellow stage holding the title, a back button
/// that stays put, a scrolling body, and an optional footer that rides above the keyboard.
struct AuthScaffold<Content: View, Footer: View>: View {
    let screenID: String
    let title: String
    let subtitle: String
    let cardTheme: GradientTheme
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Width the decorative card is drawn at.
    private let cardWidth: CGFloat = 130
    /// How far the yellow runs past the top edge, so pulling down never shows cream above it.
    private let overscrollCover: CGFloat = 1000

    init(
        screenID: String,
        title: String,
        subtitle: String,
        cardTheme: GradientTheme,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.screenID = screenID
        self.title = title
        self.subtitle = subtitle
        self.cardTheme = cardTheme
        self.content = content
        self.footer = footer
    }

    /// The card gives way to the title at accessibility text sizes.
    private var showsCard: Bool {
        !dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                stage
                VStack(alignment: .leading, spacing: 18) {
                    content()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background {
            Color("obScreenBg")
                .ignoresSafeArea()
        }
        .onTapGesture {
            hideKeyboard()
        }
        .overlay(alignment: .topLeading) {
            backButton
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if Footer.self != EmptyView.self {
                footer()
                    .padding(.horizontal, 30)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color("obScreenBg"))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }

    private var stage: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.wishiesDisplay(.bold, 32))
                .foregroundStyle(Color("obInk"))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("auth.\(screenID).title")
            Text(subtitle)
                .font(.wishies(.regular, 16))
                .foregroundStyle(Color("obInk").opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 30)
        .padding(.trailing, showsCard ? 120 : 30)
        // 8pt gap, the 44pt back button, 16pt gap.
        .padding(.top, 68)
        .padding(.bottom, 24)
        .background {
            ZStack(alignment: .bottomTrailing) {
                Color.lightYellow
                if showsCard {
                    decorativeCard
                }
            }
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 44, bottomTrailingRadius: 44))
            .padding(.top, -overscrollCover)
        }
    }

    /// One sample wishlist peeking out of the stage's corner, echoing the landing's fan.
    private var decorativeCard: some View {
        SampleWishlistCard(wishlist: .sample(for: cardTheme))
            .scaleEffect(cardWidth / WishlistFanLayout.designCardWidth, anchor: .bottomTrailing)
            .rotationEffect(.degrees(-9))
            .offset(x: 40, y: 48)
            .dynamicTypeSize(.large)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color("obInk"))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white))
        }
        .padding(.leading, 30)
        .padding(.top, 8)
        .accessibilityLabel("Back")
        .accessibilityIdentifier("auth.backButton")
    }
}

extension AuthScaffold where Footer == EmptyView {
    init(
        screenID: String,
        title: String,
        subtitle: String,
        cardTheme: GradientTheme,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            screenID: screenID,
            title: title,
            subtitle: subtitle,
            cardTheme: cardTheme,
            content: content,
            footer: { EmptyView() }
        )
    }
}

#Preview {
    AuthScaffold(
        screenID: "login",
        title: "Welcome back.",
        subtitle: "Log in to see your lists.",
        cardTheme: .coral
    ) {
        AuthField("Email", text: .constant(""), kind: .email)
        AuthField("Password", text: .constant(""), kind: .password(isNew: false))
    }
}
```

- [ ] **Step 6: Build**

```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/Auth/WishlistFanView.swift Wishie/Screens/Auth/AuthScaffold.swift WishieTests/SampleWishlistTests.swift
git commit -m "feat: add AuthScaffold and a sample card per theme

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Login and Forgot password

**Files:**
- Rewrite: `Wishie/Screens/Auth/LoginView.swift`
- Rewrite: `Wishie/Screens/Auth/ForgotPasswordView.swift`
- Create: `WishieUITests/AuthFormScreensUITests.swift`
- Modify: `WishieUITests/LoginOrSignUpScreenUITests.swift` (`testLoginButtonOpensLoginView`, `testFanKeepsSwayingAfterReturningFromLogin`)

**Interfaces:**
- Consumes: `AuthScaffold`, `AuthField`, `AuthSocialSection`, `AuthValidation.showsEmailError / canLogIn / canSendReset / emailErrorMessage`, `InputFieldType`, `WishieButton`, `AuthViewModel.login(email:password:)`, `.loginWithGoogle(presentingViewController:)`, `.forgotPassword()`, `.forgotenEmail`, `.isSentEmail`, `.isShowError`, `.errorTitle`, `.errorMessage`, `.isShowProgress`, `UIApplication.topViewController()`, `View.showDialogIfNeeded`, `View.showFullScreenDialog`.
- Produces: `AuthFormScreensUITests` with helpers `launchUnauthenticated(extraArguments:)`, `openLogin(_:)`, `type(_:into:)` that Tasks 5 and 6 extend.

- [ ] **Step 1: Write the failing UI tests**

Create `WishieUITests/AuthFormScreensUITests.swift`:

```swift
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

        let primary = app.buttons["auth.primaryButton"]
        XCTAssertEqual(primary.label, "Send reset link")
        XCTAssertFalse(primary.isEnabled)

        let email = app.textFields["auth.field.email"]
        type("linh@example", into: email)
        XCTAssertFalse(primary.isEnabled)

        email.typeText(".com")
        XCTAssertTrue(primary.isEnabled)
    }
}
```

- [ ] **Step 2: Run the UI tests to verify they fail**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/AuthFormScreensUITests 2>&1 | tail -25
```

Expected: `** TEST FAILED **`. All four fail in `openLogin` because nothing has the identifier `auth.login.title` yet.

If they fail because the app shows Home or onboarding instead, the launch-argument override did not take effect: erase the simulator (`xcrun simctl erase "iPhone 16"`), rerun, and report this in the task summary.

- [ ] **Step 3: Rewrite `LoginView.swift`**

Replace the whole file with:

```swift
//
//  LoginView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 9/10/25.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @EnvironmentObject private var viewModel: AuthViewModel
    @FocusState private var focusedField: InputFieldType?

    private var emailError: String? {
        AuthValidation.showsEmailError(email: email, isFocused: focusedField == .email)
            ? AuthValidation.emailErrorMessage
            : nil
    }

    var body: some View {
        AuthScaffold(
            screenID: "login",
            title: "Welcome back.",
            subtitle: "Log in to see your lists.",
            cardTheme: .coral
        ) {
            AuthField("Email", text: $email, kind: .email, error: emailError)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
            AuthField("Password", text: $password, kind: .password(isNew: false))
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit {
                    focusedField = nil
                }
            NavigationLink {
                ForgotPasswordView()
                    .navigationBarBackButtonHidden()
            } label: {
                Text("Forgot password?")
                    .font(.wishies(.bold, 14))
                    .underline()
                    .foregroundStyle(Color("obInk"))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityIdentifier("auth.forgotPasswordLink")
            WishieButton(
                title: "Log in",
                enabled: AuthValidation.canLogIn(email: email, password: password),
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                viewModel.login(email: email, password: password)
            }
            .accessibilityIdentifier("auth.primaryButton")
            AuthSocialSection {
                guard let presentingViewController = UIApplication.topViewController() else { return }
                viewModel.loginWithGoogle(presentingViewController: presentingViewController)
            }
        }
        .showDialogIfNeeded($viewModel.isShowError, title: viewModel.errorTitle, message: viewModel.errorMessage)
        .showFullScreenDialog($viewModel.isShowProgress)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
```

- [ ] **Step 4: Rewrite `ForgotPasswordView.swift`**

Replace the whole file with:

```swift
//
//  ForgotPasswordView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/3/26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isEmailFocused: Bool

    private var emailError: String? {
        AuthValidation.showsEmailError(email: viewModel.forgotenEmail, isFocused: isEmailFocused)
            ? AuthValidation.emailErrorMessage
            : nil
    }

    var body: some View {
        AuthScaffold(
            screenID: "forgot",
            title: "Reset your password.",
            subtitle: "We will email you a link.",
            cardTheme: .gold
        ) {
            AuthField("Email", text: $viewModel.forgotenEmail, kind: .email, error: emailError)
                .focused($isEmailFocused)
                .submitLabel(.done)
                .onSubmit {
                    isEmailFocused = false
                }
        } footer: {
            WishieButton(
                title: "Send reset link",
                enabled: AuthValidation.canSendReset(email: viewModel.forgotenEmail),
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                viewModel.forgotPassword()
            }
            .accessibilityIdentifier("auth.primaryButton")
        }
        .onDisappear {
            viewModel.forgotenEmail = ""
        }
        .showDialogIfNeeded(
            $viewModel.isSentEmail,
            title: "Email has been sent",
            message: "Please follow the link in the email to reset your password, thank you <3",
            onOk: {
                dismiss()
            })
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthViewModel())
}
```

- [ ] **Step 5: Update the two landing UI tests that match the old Login headline**

In `WishieUITests/LoginOrSignUpScreenUITests.swift`:

In `testLoginButtonOpensLoginView`, replace

```swift
        XCTAssertTrue(app.staticTexts["Hello old friend, are you good ?"].waitForExistence(timeout: 5))
```

with

```swift
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))
```

In `testFanKeepsSwayingAfterReturningFromLogin`, replace

```swift
        XCTAssertTrue(app.staticTexts["Hello old friend, are you good ?"].waitForExistence(timeout: 5))

        app.buttons.firstMatch.tap()
```

with

```swift
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))

        app.buttons["auth.backButton"].tap()
```

Leave the two Sign up tests alone; Task 5 updates them.

- [ ] **Step 6: Run the UI tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/AuthFormScreensUITests -only-testing:WishieUITests/LoginOrSignUpScreenUITests 2>&1 | tail -30
```

Expected: `** TEST SUCCEEDED **`. The 4 new tests and the 6 landing tests pass.

If `testLoginShowsEmailErrorOnlyAfterLeavingTheField` fails at the "must wait until focus leaves" assertion, the screen's `.focused($focusedField, equals: .email)` is not reaching the text field inside `AuthField`. Fix it in `AuthField` by forwarding the modifier to the inner field: do not weaken the test. Report what you changed.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/Auth/LoginView.swift Wishie/Screens/Auth/ForgotPasswordView.swift WishieUITests/AuthFormScreensUITests.swift WishieUITests/LoginOrSignUpScreenUITests.swift
git commit -m "feat: rebuild Login and Forgot password on the auth scaffold

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Sign up and Create password

**Files:**
- Rewrite: `Wishie/Screens/Auth/SignUpView.swift`
- Rewrite: `Wishie/Screens/Auth/PasswordSignUpView.swift`
- Delete: `Wishie/Resources/CustomView/PasswordField.swift`
- Modify: `WishieUITests/AuthFormScreensUITests.swift` (add tests)
- Modify: `WishieUITests/LoginOrSignUpScreenUITests.swift` (`testSignUpLinkOpensSignUpView`, `testFanKeepsSwayingAfterReturningFromSignUp`)

**Interfaces:**
- Consumes: `AuthScaffold`, `AuthField`, `AuthBirthdayField`, `AuthSocialSection`, `AuthValidation.showsEmailError / canContinueSignUp / isPasswordLongEnough / passwordSubtitle / minimumPasswordLength / emailErrorMessage`, `InputFieldType`, `WishieButton`, `SignUpRequest(firstName:lastName:email:phone:dateOfBirth:)`, `AuthViewModel.request`, `.signup(request:)`, `.loginWithGoogle(presentingViewController:)`, and the `launchUnauthenticated` / `type(_:into:)` helpers already in `AuthFormScreensUITests`.
- Produces: helpers `openSignUp(_:)` and `openCreatePassword(_:)` in `AuthFormScreensUITests`, used by Task 6.

- [ ] **Step 1: Write the failing UI tests**

In `WishieUITests/AuthFormScreensUITests.swift`, add these two helpers directly after the `openLogin` helper:

```swift

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
```

Then add these tests at the end of the class, before its closing brace:

```swift

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
```

- [ ] **Step 2: Run the new UI tests to verify they fail**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/AuthFormScreensUITests 2>&1 | tail -30
```

Expected: `** TEST FAILED **`. The five new tests fail in `openSignUp` because nothing has the identifier `auth.signup.title` yet. The four Task 4 tests still pass.

- [ ] **Step 3: Rewrite `SignUpView.swift`**

Replace the whole file with:

```swift
//
//  SignUpView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 19/10/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var lastName: String = ""
    @State private var firstName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var goToPassword = false
    @State private var dob: Date = Date()

    @FocusState private var focusedField: InputFieldType?

    private var emailError: String? {
        AuthValidation.showsEmailError(email: email, isFocused: focusedField == .email)
            ? AuthValidation.emailErrorMessage
            : nil
    }

    /// Side by side normally; stacked at accessibility text sizes, where two columns are too narrow.
    private var nameLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 18))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
    }

    var body: some View {
        AuthScaffold(
            screenID: "signup",
            title: "Create your account.",
            subtitle: "It takes a minute.",
            cardTheme: .mint
        ) {
            nameLayout {
                AuthField("First name", text: $firstName, kind: .firstName)
                    .focused($focusedField, equals: .firstName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .lastName
                    }
                AuthField("Last name", text: $lastName, kind: .lastName)
                    .focused($focusedField, equals: .lastName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .email
                    }
            }
            AuthField("Email", text: $email, kind: .email, error: emailError)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .phone
                }
            AuthField("Phone", text: $phone, kind: .phone)
                .focused($focusedField, equals: .phone)
            AuthBirthdayField(date: $dob)
            WishieButton(
                title: "Continue",
                enabled: AuthValidation.canContinueSignUp(email: email, phone: phone),
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                focusedField = nil
                authVM.request = SignUpRequest(
                    firstName: firstName,
                    lastName: lastName,
                    email: email,
                    phone: phone,
                    dateOfBirth: dob
                )
                goToPassword = true
            }
            .accessibilityIdentifier("auth.primaryButton")
            AuthSocialSection {
                guard let presentingViewController = UIApplication.topViewController() else { return }
                authVM.loginWithGoogle(presentingViewController: presentingViewController)
            }
        }
        .showDialogIfNeeded(
            $authVM.isShowError,
            title: authVM.errorTitle,
            message: authVM.errorMessage
        )
        .showFullScreenDialog($authVM.isShowProgress)
        .navigationDestination(isPresented: $goToPassword) {
            PasswordSignUpView()
                .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
    }
}
```

This drops `dateOfBirthField`, `validateGoinButton`, the unused `date` / `month` / `year` / `password` / `showPassword` state, and the `Binding.max(_:)` extension. Before deleting the extension, confirm nothing calls it:

```bash
grep -rn "\.max(" Wishie --include="*.swift" | grep -v "Swift.max"
```

Expected: no output. If anything is listed, keep the extension at the bottom of `SignUpView.swift` and report it.

- [ ] **Step 4: Rewrite `PasswordSignUpView.swift`**

Replace the whole file with:

```swift
//
//  PasswordSignUpView.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 26/10/25.
//

import SwiftUI

struct PasswordSignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @FocusState private var isPasswordFocused: Bool
    @State private var password: String = ""

    private var isLongEnough: Bool {
        AuthValidation.isPasswordLongEnough(password)
    }

    var body: some View {
        AuthScaffold(
            screenID: "password",
            title: "Pick a password.",
            subtitle: AuthValidation.passwordSubtitle(firstName: authVM.request.firstName),
            cardTheme: .grape
        ) {
            AuthField("Password", text: $password, kind: .password(isNew: true))
                .focused($isPasswordFocused)
                .submitLabel(.done)
                .onSubmit {
                    isPasswordFocused = false
                }
            ruleRow
        } footer: {
            WishieButton(
                title: "Create account",
                enabled: isLongEnough,
                filColor: Color("obInk"),
                titleColor: .white
            ) {
                isPasswordFocused = false
                authVM.request.password = password
                authVM.signup(request: authVM.request)
            }
            .accessibilityIdentifier("auth.primaryButton")
        }
        .showDialogIfNeeded(
            $authVM.isShowError,
            title: authVM.errorTitle,
            message: authVM.errorMessage
        )
        .showFullScreenDialog($authVM.isShowProgress)
    }

    /// The one password rule the backend enforces, ticked off as soon as it is met.
    private var ruleRow: some View {
        let text = "At least \(AuthValidation.minimumPasswordLength) characters"
        return HStack(spacing: 8) {
            ZStack {
                if isLongEnough {
                    Circle()
                        .fill(Color("obInk"))
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.lightYellow)
                } else {
                    Circle()
                        .strokeBorder(Color("obInk"), lineWidth: 1.5)
                }
            }
            .frame(width: 16, height: 16)
            Text(text)
                .font(.wishies(.medium, 14))
                .foregroundStyle(Color("obInk"))
        }
        .opacity(isLongEnough ? 1 : 0.55)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text), \(isLongEnough ? "met" : "not met")")
        .accessibilityIdentifier("auth.passwordRule")
    }
}

#Preview {
    PasswordSignUpView()
        .environmentObject(AuthViewModel())
}
```

- [ ] **Step 5: Delete `PasswordField.swift`**

```bash
grep -rn "PasswordField(" Wishie --include="*.swift"
```

Expected: no output (Login stopped using it in Task 4, Create password just now).

```bash
git rm Wishie/Resources/CustomView/PasswordField.swift
```

- [ ] **Step 6: Update the two landing UI tests that match the old Sign up headline**

In `WishieUITests/LoginOrSignUpScreenUITests.swift`:

In `testSignUpLinkOpensSignUpView`, replace

```swift
        XCTAssertTrue(app.staticTexts["Welcome new friend, are you good ?"].waitForExistence(timeout: 5))
```

with

```swift
        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))
```

In `testFanKeepsSwayingAfterReturningFromSignUp`, replace

```swift
        XCTAssertTrue(app.staticTexts["Welcome new friend, are you good ?"].waitForExistence(timeout: 5))

        app.buttons.firstMatch.tap()
```

with

```swift
        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))

        app.buttons["auth.backButton"].tap()
```

- [ ] **Step 7: Run the UI tests to verify they pass**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/AuthFormScreensUITests -only-testing:WishieUITests/LoginOrSignUpScreenUITests 2>&1 | tail -30
```

Expected: `** TEST SUCCEEDED **`. 9 tests in `AuthFormScreensUITests` and 6 in `LoginOrSignUpScreenUITests` pass.

If `testCreatePasswordButtonEnablesAtEightCharacters` cannot type because iOS covers the field with a strong-password suggestion even after revealing it, do not remove `.newPassword` and do not weaken the assertions. Stop and report it with the failure output.

- [ ] **Step 8: Commit**

```bash
git add Wishie/Screens/Auth/SignUpView.swift Wishie/Screens/Auth/PasswordSignUpView.swift WishieUITests/AuthFormScreensUITests.swift WishieUITests/LoginOrSignUpScreenUITests.swift
git commit -m "feat: rebuild Sign up and Create password on the auth scaffold

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(`git rm` in Step 5 already staged the deletion of `PasswordField.swift`.)

---

### Task 6: Large-text test, full test run, and visual check

**Files:**
- Modify: `WishieUITests/AuthFormScreensUITests.swift` (add one test)
- Modify, only if the screenshots show the card overlapping the title or sitting wrong: `Wishie/Screens/Auth/AuthScaffold.swift` (the `.offset(x: 40, y: 48)` on `decorativeCard`)
- Temporary, never committed: `WishieUITests/AuthScreensCaptureUITests.swift`

**Interfaces:**
- Consumes: the helpers `launchUnauthenticated(extraArguments:)`, `openLogin(_:)`, `openSignUp(_:)`, `openCreatePassword(_:)` in `AuthFormScreensUITests`.
- Produces: nothing later tasks use.

- [ ] **Step 1: Add the large-text test**

In `WishieUITests/AuthFormScreensUITests.swift`, add at the end of the class, before its closing brace:

```swift

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
```

- [ ] **Step 2: Run it**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieUITests/AuthFormScreensUITests/testBackButtonStaysHittableAtLargestTextSize 2>&1 | tail -25
```

Expected: `** TEST SUCCEEDED **`.

If it fails because a field or the Continue button is off screen when the helper tries to tap it, that is the helper needing a scroll, not a product bug: make `type(_:into:)` swipe up once when the element is not hittable. If it fails on a `back.isHittable` or footer-button assertion, that is a real layout bug in `AuthScaffold`: fix it there and report what you changed.

- [ ] **Step 3: Commit the test**

```bash
git add WishieUITests/AuthFormScreensUITests.swift
git commit -m "test: back button stays hittable on auth screens at the largest text size

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Run the whole unit and UI test suite**

```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -40
```

Expected: `** TEST SUCCEEDED **`. If a test unrelated to auth fails, rerun it once on its own; if it still fails, check whether it also fails on `develop` (`git stash` is not needed, use `git worktree` or report it) and report it rather than changing it.

- [ ] **Step 5: Capture the four screens on a small and a large phone**

Create the temporary file `WishieUITests/AuthScreensCaptureUITests.swift`. It writes PNGs to the Mac's `/tmp`, which a simulator process can reach:

```swift
import XCTest

/// Temporary. Captures the auth screens for a visual check. Never commit this file.
final class AuthScreensCaptureUITests: XCTestCase {
    @MainActor
    private func save(_ app: XCUIApplication, _ name: String) throws {
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "device"
        let folder = URL(fileURLWithPath: "/tmp/wishie-auth-shots/\(device)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try app.screenshot().pngRepresentation.write(to: folder.appendingPathComponent("\(name).png"))
    }

    @MainActor
    func testCapture() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "YES", "-userid", ""]
        app.launch()

        XCTAssertTrue(app.buttons["auth.loginButton"].waitForExistence(timeout: 10))
        app.buttons["auth.loginButton"].tap()
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))
        try save(app, "1-login")

        app.textFields["auth.field.email"].tap()
        app.textFields["auth.field.email"].typeText("linh@example")
        app.secureTextFields["auth.field.password"].tap()
        try save(app, "2-login-error-keyboard")

        app.buttons["auth.forgotPasswordLink"].tap()
        XCTAssertTrue(app.staticTexts["auth.forgot.title"].waitForExistence(timeout: 5))
        try save(app, "3-forgot")
        app.buttons["auth.backButton"].tap()
        XCTAssertTrue(app.staticTexts["auth.login.title"].waitForExistence(timeout: 5))
        app.buttons["auth.backButton"].tap()

        XCTAssertTrue(app.buttons["auth.signUpLink"].waitForExistence(timeout: 5))
        app.buttons["auth.signUpLink"].tap()
        XCTAssertTrue(app.staticTexts["auth.signup.title"].waitForExistence(timeout: 5))
        try save(app, "4-signup")

        app.textFields["auth.field.firstName"].tap()
        app.textFields["auth.field.firstName"].typeText("Linh")
        app.textFields["auth.field.email"].tap()
        app.textFields["auth.field.email"].typeText("linh@example.com")
        app.textFields["auth.field.phone"].tap()
        app.textFields["auth.field.phone"].typeText("0901234567")
        try save(app, "5-signup-filled-keyboard")
        app.buttons["auth.primaryButton"].tap()
        XCTAssertTrue(app.staticTexts["auth.password.title"].waitForExistence(timeout: 5))
        try save(app, "6-password")
    }
}
```

Run it on both phones:

```bash
rm -rf /tmp/wishie-auth-shots
for device in "iPhone SE (3rd generation)" "iPhone 16 Pro Max"; do
  xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination "platform=iOS Simulator,name=$device" -only-testing:WishieUITests/AuthScreensCaptureUITests 2>&1 | tail -5
done
ls -R /tmp/wishie-auth-shots
```

Expected: `** TEST SUCCEEDED **` twice, and six PNGs in each of two folders.

- [ ] **Step 6: Look at every screenshot**

Open all twelve PNGs with the Read tool and check each against this list:

1. The stage is yellow with rounded bottom corners and runs up under the status bar with no cream strip above it.
2. The title and subtitle are fully readable and nothing overlaps them. The decorative card sits in the stage's bottom-trailing corner, tilted, cut off by the stage's edge, and does not cover any title text.
3. The back button is a white circle at the top-left and does not overlap the title.
4. Fields are white with a thin border; the focused field has a dark border; the invalid email in `2-login-error-keyboard` has a red border and the red message under it.
5. The primary button is dark with white text, and visibly dimmed when disabled.
6. On Forgot password and Create password the primary button is pinned at the bottom.
7. On the iPhone SE with the keyboard up, the focused field is visible above the keyboard.

- [ ] **Step 7: Fix what the screenshots show, if anything**

If the card overlaps the title or sits too far in or out, adjust only the two numbers in `.offset(x: 40, y: 48)` in `AuthScaffold.decorativeCard`, rerun Step 5, and look again. A larger `x` pushes the card further off the trailing edge; a larger `y` pushes it further below the bottom edge.

For any other problem on the checklist, fix it in the component that owns it (`AuthScaffold`, `AuthField`, `AuthBirthdayField`, `AuthSocialSection`), keeping every value in Global Constraints, then rerun Step 5 and the affected UI tests.

If nothing needed fixing, skip to Step 8.

- [ ] **Step 8: Remove the temporary capture test and commit any fix**

```bash
rm WishieUITests/AuthScreensCaptureUITests.swift
git status --short
```

Expected: either no output, or only files you changed in Step 7. `AuthScreensCaptureUITests.swift` must not appear.

If Step 7 changed anything:

```bash
git add Wishie/Screens/Auth
git commit -m "fix: tune auth scaffold layout after visual check

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 9: Report**

In the task summary, state: the result of the full test run in Step 4 (counts, and any failure with its output); for each of the seven checklist items, whether it held on both phones; and what, if anything, Step 7 changed. Leave the screenshots in `/tmp/wishie-auth-shots` and give their paths.

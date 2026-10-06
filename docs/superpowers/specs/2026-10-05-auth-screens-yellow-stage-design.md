# Auth Form Screens: Yellow Stage Redesign

## Context

`LoginOrSignUpScreen` moved to the "Warm Refined" look on 2026-10-01
(see `2026-10-01-login-signup-wishlist-fan-design.md`): cream
`obScreenBg`, `obInk` text and buttons, a `lightYellow` stage with
rounded bottom corners, `Baloo 2` headlines, `Nunito` body.

The four screens behind it were not touched and no longer match:

- `LoginView`, `SignUpView`, `PasswordSignUpView` and
  `ForgotPasswordView` sit on `lightYellow1`, not `obScreenBg`.
- Their headline is `Nunito Bold 37`, two to three lines long.
- Their buttons are hand-built (radius 15, height 50). `WishieButton`
  is radius 20, height 60. The Sign up "Continue" button uses the
  system font and `.yellow`.
- The Forgot password button reads "Go in".
- Fields have no focus state. The email error appears only after a tap
  outside the field.
- Each file repeats the same back button, headline, field and button
  code.

## Goal

The four form screens look like one set with the landing screen, and
share their layout and field code so they cannot drift apart again.

Success means:

- All four screens use the same scaffold, field and button components.
- Colors, fonts, radii and paddings match the landing screen.
- A focused field and an invalid field are each visibly distinct.
- Button labels name the action they perform.
- Navigation, `AuthViewModel` and the API calls are unchanged.

## Decisions made during brainstorming

| Topic | Decision |
|-------|----------|
| Direction | "Yellow stage": the landing's stage shrinks to hold the headline; the form sits on cream below it. |
| Copy | Shorter headlines and action-named buttons (table below). |
| Field states | Focus and inline error states are in scope. |
| Password hint | One rule only, "At least 8 characters", because `POST /auth/signup` enforces only a minimum length of 8 (`API.md`). |
| Phone | Stays required, because `POST /auth/signup` marks `phone` as required. The Continue button now enforces it. |
| Structure | Shared scaffold and field components in `Screens/Auth/`. `DateInputView` is not changed, because three screens outside auth use it. |

## Out of scope

- `LoginOrSignUpScreen` and `WishlistFanView`'s fan layout and sway.
- `DateInputView` and the three non-auth screens that use it.
- The backend, `AuthViewModel`, `AuthenticateService`, `SignUpRequest`.
- `AuthViewModel.forgotPassword()` swallows a failed request without
  telling the user. This is a known gap and is left as is.
- Dark mode. The color assets define the same value for both
  appearances today.

## Files

| File | Change |
|------|--------|
| `Wishie/Screens/Auth/AuthScaffold.swift` | New. Screen frame: stage, pinned back button, scrolling body, optional pinned footer. |
| `Wishie/Screens/Auth/AuthField.swift` | New. Labeled text field with focus and error states, plus a password variant. `InputFieldType` moves here from `LoginView.swift`. |
| `Wishie/Screens/Auth/AuthBirthdayField.swift` | New. One field in the `AuthField` style that opens a date picker. |
| `Wishie/Screens/Auth/AuthSocialSection.swift` | New. The "or" divider and the Google button, used by Login and Sign up. |
| `Wishie/Screens/Auth/AuthValidation.swift` | New. Pure static functions for button-enabled and error-visible rules. |
| `Wishie/Screens/Auth/LoginView.swift` | Rewritten on the new components. |
| `Wishie/Screens/Auth/SignUpView.swift` | Rewritten on the new components. Unused members removed. |
| `Wishie/Screens/Auth/PasswordSignUpView.swift` | Rewritten on the new components. |
| `Wishie/Screens/Auth/ForgotPasswordView.swift` | Rewritten on the new components. |
| `Wishie/Screens/Auth/WishlistFanView.swift` | `SampleWishlist` and `SampleWishlistCard` change from `private` to internal. One gold sample is added. No change to the fan. |
| `Wishie/Resources/CustomView/PasswordField.swift` | Deleted. Only Login and Create password use it. |
| `Wishie/Resources/Assets.xcassets/obError.colorset` | New color, `#B3261E`, same value for light and dark. |
| `WishieTests/AuthValidationTests.swift` | New. |
| `WishieUITests/AuthFormScreensUITests.swift` | New. |
| `WishieUITests/LoginOrSignUpScreenUITests.swift` | Two tests stop matching on headline text and match on an accessibility identifier. |

The Xcode project uses file-system-synchronized groups, so adding and
deleting files on disk is enough; `project.pbxproj` is not edited.

## Components

### `AuthScaffold`

```swift
AuthScaffold(
    screenID: "login",
    title: "Welcome back.",
    subtitle: "Log in to see your lists.",
    cardTheme: .coral
) {
    // fields and inline buttons
} footer: {
    // optional pinned primary button
}
```

A second initializer omits `footer`.

**Background.** `Color("obScreenBg")`, ignoring the safe area.

**Scrolling.** The stage and the body sit together in one `ScrollView`
with hidden indicators and `.scrollDismissesKeyboard(.interactively)`.
The stage scrolls away with the content, so the form is not squeezed
when the keyboard is up on a small phone. The yellow fill extends
upward past the top edge so that pulling down does not show cream above
the stage.

**Stage.** `Color.lightYellow` in an `UnevenRoundedRectangle` with
bottom-leading and bottom-trailing radius 44, extending under the
status bar. Its content is clipped to that shape.

- Title: `.wishiesDisplay(.bold, 32)`, `obInk`, leading-aligned,
  `.minimumScaleFactor(0.8)`, at most 3 lines.
- Subtitle: `.wishies(.regular, 16)`, `obInk` at 70% opacity, 6pt below
  the title.
- Padding: 30pt leading, 24pt bottom, and 68pt top below the safe area
  (8pt gap, the 44pt back button, 16pt gap).
- Trailing padding of the text column: 120pt when the decorative card
  is shown, 30pt when it is hidden.

**Decorative card.** One `SampleWishlistCard` at the fan's design size
(220pt wide), scaled to 130pt wide with `scaleEffect`, rotated −9°,
aligned bottom-trailing and offset so about a third of it hangs past
the stage's trailing and bottom edges. It is `accessibilityHidden` and
does not take hits. It is not shown when
`dynamicTypeSize.isAccessibilitySize` is true.

| Screen | `cardTheme` | Sample |
|--------|-------------|--------|
| Login | `.coral` | Birthday 2026 (existing) |
| Sign up | `.mint` | Housewarming (existing) |
| Create password | `.grape` | Tết wishlist (existing) |
| Forgot password | `.gold` | Wedding · 10 items: Dinner set, Wine glasses, Photo frame (new, none reserved) |

`SampleWishlist` gains a static lookup from `GradientTheme` to its
sample, so the scaffold takes only the theme.

**Back button.** A 44×44 white circle with `Image(systemName:
"arrow.left")` in `obInk`, pinned as an overlay at the top-leading
corner (30pt leading, 8pt below the safe area). It stays in place while
the content scrolls. It calls `dismiss()`. Accessibility label "Back",
identifier `auth.backButton`.

**Body.** A `VStack(alignment: .leading, spacing: 18)` with 30pt
horizontal padding and 24pt top and bottom padding.

**Footer.** When present, pinned with `.safeAreaInset(edge: .bottom)`,
so it rides above the keyboard. 30pt horizontal padding, 12pt top,
16pt bottom, on an `obScreenBg` background.

**Shared behavior.** The scaffold owns what the four screens repeat
today: tap on empty space hides the keyboard, and a keyboard toolbar
shows a trailing "Done" button that hides the keyboard.

**Identifiers.** The title carries `auth.<screenID>.title`
(`auth.login.title`, `auth.signup.title`, `auth.password.title`,
`auth.forgot.title`).

### `AuthField`

```swift
AuthField("Email", text: $email, kind: .email, error: emailError)
    .focused($focusedField, equals: .email)
```

- Label: `.wishies(.bold, 15)`, `obInk`, 6pt above the field.
- Field: minimum height 56, `RoundedRectangle(cornerRadius: 16)` filled
  white, text in `.wishies(.regular, 17)`, 16pt horizontal padding.
- Idle border: `obInk` at 12% opacity, 1.5pt.
- Focused: border `obInk`, 2pt, plus a 3pt `lightYellow` ring outside
  it. The field tracks its own focus with an internal `@FocusState`;
  the caller's `.focused` modifier keeps driving field-to-field
  navigation as it does today.
- Error (when `error` is non-nil): border `obError`, 2pt, and the
  message 6pt below in `.wishies(.medium, 13)`, `obError`. The message
  is exposed to VoiceOver as part of the field.
- The whole field area focuses the text field when tapped.

`kind` sets the keyboard and autofill behavior:

| Kind | Keyboard | Content type | Capitalization | Autocorrect |
|------|----------|--------------|----------------|-------------|
| `.firstName` | default | `.givenName` | words | off |
| `.lastName` | default | `.familyName` | words | off |
| `.email` | `.emailAddress` | `.emailAddress` | never | off |
| `.phone` | `.phonePad` | `.telephoneNumber` | never | off |
| `.password(isNew: false)` | default | `.password` | never | off |
| `.password(isNew: true)` | default | `.newPassword` | never | off |

Name fields capitalize words; today they have capitalization turned
off. The phone field shows the phone pad; today it shows the default
keyboard.

**Password variant.** Shows a `SecureField`, or a `TextField` while
revealed. A trailing eye button toggles between them using the existing
`eye-solid-full` and `eye-slash-solid-full` images at 22pt, inside a
44×44 hit area, with the accessibility label "Show password" or "Hide
password". The reveal state is private to the field.

### `AuthBirthdayField`

```swift
AuthBirthdayField(date: $dob)
```

Looks like an `AuthField` labeled "Birthday". Shows the date as
`14 Feb 1998` (day, abbreviated month, year, in the user's locale).
Tapping it opens a sheet with a wheel `DatePicker` limited to dates up
to today and a "Done" `WishieButton` in `obInk`. The sheet uses a fixed
height detent of 340pt. The binding updates when Done is tapped. While
the sheet is open the field shows the focused border.

### `AuthSocialSection`

```swift
AuthSocialSection { /* Google sign-in action */ }
```

- Divider: two 1pt `obInk` lines at 25% opacity that stretch to fill
  the width, with "or" between them in `.wishies(.italic, 15)`, `obInk`
  at 60% opacity. No `UIScreen.main.bounds`.
- Google button, 14pt below: height 60, radius 20, white fill, 1.5pt
  `obInk` border at 14% opacity, `Image("google_icon")` at 20pt and
  "Continue with Google" in `.wishies(.bold, 17)`, `obInk`, centered as
  a pair. Identifier `auth.googleButton`.

### Primary button

`WishieButton(title:, enabled:, filColor: Color("obInk"), titleColor:
.white)` at its default height 60 and radius 20, the same as the
landing's Login button. Identifier `auth.primaryButton` on every
screen.

### `AuthValidation`

An `enum` of static functions with no state, so the rules are unit
tested without a view:

| Function | Returns true when |
|----------|-------------------|
| `showsEmailError(email:isFocused:)` | The field is not focused, the trimmed email is not empty, and `StringUtils.isValidEmail` rejects it. |
| `canLogIn(email:password:)` | The email is valid and the trimmed password is not empty. |
| `canContinueSignUp(email:phone:)` | The email is valid and the trimmed phone is not empty. |
| `isPasswordLongEnough(_:)` | The password, as typed and untrimmed, has 8 or more characters. |
| `canSendReset(email:)` | The email is valid. |

`static let minimumPasswordLength = 8` and
`static let emailErrorMessage = "Enter a valid email address."`.

## Screens

Navigation is unchanged: `LoginOrSignUpScreen` pushes `LoginView` or
`SignUpView`; `LoginView` pushes `ForgotPasswordView`; `SignUpView`
pushes `PasswordSignUpView`. Every destination keeps
`.navigationBarBackButtonHidden()`.

Every screen keeps its existing error dialog
(`showDialogIfNeeded`) and progress overlay (`showFullScreenDialog`)
for server responses.

### Login

| Element | Value |
|---------|-------|
| Title / subtitle | "Welcome back." / "Log in to see your lists." |
| Fields | Email (`.email`), Password (`.password(isNew: false)`) |
| Link | "Forgot password?" in `.wishies(.bold, 14)`, `obInk`, underlined, trailing-aligned, minimum height 44. Pushes `ForgotPasswordView`. |
| Primary | "Log in". Enabled by `canLogIn`. Calls `viewModel.login(email:password:)`. |
| Below | `AuthSocialSection` calling `viewModel.loginWithGoogle`. |
| Footer | None. |

Submitting the email field moves focus to the password field.
Submitting the password field hides the keyboard.

### Sign up

| Element | Value |
|---------|-------|
| Title / subtitle | "Create your account." / "It takes a minute." |
| Fields | First name and Last name side by side with a 10pt gap, Email, Phone, Birthday |
| Primary | "Continue". Enabled by `canContinueSignUp`. Fills `authVM.request` as today and pushes `PasswordSignUpView`. |
| Below | `AuthSocialSection` calling `authVM.loginWithGoogle`. |
| Footer | None. |

Submit order: first name, last name, email, phone. First name, last
name and birthday are not validated, as today.

Removed from `SignUpView`: `dateOfBirthField`, `validateGoinButton`,
and the unused `date`, `month`, `year`, `password` and `showPassword`
state, and the `Binding.max(_:)` extension at the bottom of the file,
which nothing in the project calls.

### Create password

| Element | Value |
|---------|-------|
| Title | "Pick a password." |
| Subtitle | "Last step, \(firstName)." using the trimmed `authVM.request.firstName`; "Last step." when it is empty. |
| Fields | Password (`.password(isNew: true)`) |
| Rule row | Under the field: a 16pt circle and "At least 8 characters" in `.wishies(.medium, 14)`. Unmet: outlined circle, `obInk` at 55% opacity. Met: circle filled `obInk` with a `lightYellow` checkmark, text at full opacity. VoiceOver reads "At least 8 characters, met" or "not met". |
| Footer | "Create account". Enabled by `isPasswordLongEnough`. Sets `authVM.request.password` and calls `authVM.signup(request:)` as today. |

The rule row carries the identifier `auth.passwordRule`.

### Forgot password

| Element | Value |
|---------|-------|
| Title / subtitle | "Reset your password." / "We will email you a link." |
| Fields | Email (`.email`), bound to `viewModel.forgotenEmail` |
| Footer | "Send reset link". Enabled by `canSendReset`. Calls `viewModel.forgotPassword()`. |

Unchanged: the "Email has been sent" dialog and its dismissal, and
clearing `forgotenEmail` on disappear.

### Email error

On Login, Sign up and Forgot password, the email field's `error` is
`AuthValidation.emailErrorMessage` when `showsEmailError` is true and
`nil` otherwise. The error therefore appears when the user leaves the
field with an invalid address and disappears as soon as they return to
it. The error text carries the identifier `auth.emailError`.

## Accessibility and layout

- Every tappable element is at least 44×44pt.
- Dynamic Type is not capped: the content scrolls. At accessibility
  sizes the decorative card is hidden and the title takes the full
  width.
- Text on cream and on `lightYellow` is `obInk`. Error text is
  `obError` (`#B3261E`), which has a contrast ratio above 4.5:1 on
  `obScreenBg`.
- The first name and last name fields stay side by side at all sizes
  except accessibility sizes, where they stack.

## Testing

**Unit tests (`AuthValidationTests`).** One test per rule in the
`AuthValidation` table, covering: valid input; empty input; whitespace
only; an invalid email; a password of 7 and of 8 characters; a password
of 8 spaces counts as long enough (it is not trimmed);
`showsEmailError` is false while focused and false for an empty field.

**UI tests (`AuthFormScreensUITests`).** Launched unauthenticated with
the same arguments as `LoginOrSignUpScreenUITests`.

- Login: typing an invalid email then focusing the password field shows
  `auth.emailError` and leaves `auth.primaryButton` disabled; a valid
  email and any password enables it.
- Sign up: a valid email with an empty phone leaves `auth.primaryButton`
  disabled; adding a phone number enables it.
- Create password: 7 characters leaves `auth.primaryButton` disabled; 8
  enables it.
- Forgot password: reachable from Login; an invalid email leaves
  `auth.primaryButton` disabled.
- `auth.backButton` is hittable on all four screens at
  `UICTContentSizeCategoryAccessibilityXXXL`.

**Existing UI tests.** `testLoginButtonOpensLoginView` and
`testSignUpLinkOpensSignUpView` wait for `auth.login.title` and
`auth.signup.title` instead of the old headline strings.

**Manual check.** Layout is verified by eye on an iPhone SE (3rd
generation) and an iPhone 16 Pro Max simulator: each screen at default
text size and at the largest accessibility size, with the keyboard up
and down.

## Changes made during implementation

These differ from the sections above and describe the code as built.

- **`InputFieldType` stays in `LoginView.swift`.** It was not moved to
  `AuthField.swift`.
- **Titles.** A title that needs two lines carries an explicit line
  break: "Create your\naccount.", "Reset your\npassword.",
  "Pick a\npassword."; "Welcome back." is one line. `AuthScaffold`
  draws each line as its own single-line `Text` stacked with −14pt
  spacing, the same workaround the landing headline uses for Baloo 2's
  tall line box. At accessibility text sizes the title is one wrapping
  `Text`, and its Dynamic Type is capped at `.accessibility1`.
  VoiceOver reads the title as one heading.
- **Top strip.** The back button sits in a pinned full-width
  `lightYellow` strip that extends under the status bar. At rest it is
  indistinguishable from the stage; when the form scrolls, content
  passes under the strip instead of under the button and status bar.
- **Decorative card.** Offset `(x: 40, y: 68)` so the strip does not
  clip its top.
- **Forgot password push.** `LoginView` pushes `ForgotPasswordView`
  from a `Button` with `.navigationDestination(isPresented:)`, as
  `SignUpView` does for Create password. A `NavigationLink` left the
  Login screen in the accessibility tree underneath.
- **Focused field and the keyboard.** `AuthScaffold` wraps its scroll
  view in a `ScrollViewReader`; an `AuthField` scrolls itself fully
  above the keyboard's Done bar shortly after it gains focus.
- **Tests.** `AuthFormScreensUITests` also covers the focused password
  field staying above the keyboard bar. UI tests run with
  `-parallel-testing-enabled NO` against a simulator id.

Known and accepted: Xcode logs `Invalid frame dimension (negative or
non-finite)` once each time the keyboard appears. It comes from iOS
laying out the keyboard toolbar that holds the Done button, not from
this layout.

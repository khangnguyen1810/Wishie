# Login with Google — Design

## Goal

Wire up real functionality behind the "Login with Google" button on `LoginView` (currently shows a "not supported" error dialog), and add a matching Google button to `SignUpView` (which currently only has a stubbed "Login with Apple" button). No layout/styling changes beyond adding the new button to `SignUpView`.

## Context

- Auth is Firebase Auth (email/password today) with user profiles stored in Firestore (`users/{uid}`), keyed off the Firebase `uid`.
- Firestore user docs (`UserModel`) hold `firstName`, `lastName`, `email`, `phone`, `dateOfBirth`, `avatarUrl`, `interests`, `hasCompletedInterestsSetup`.
- App uses pure SwiftUI lifecycle (`WishieApp.swift`, `@main`, no `AppDelegate`/`SceneDelegate`, no existing `.onOpenURL` handler).
- SPM packages already in the project: `firebase-ios-sdk` (Auth, Core, Firestore), `supabase-swift`, `dotlottie-ios`, `SDWebImageSwiftUI`.
- `GoogleService-Info.plist` currently has no `CLIENT_ID` key — Google Sign-In hasn't been enabled as a provider in the Firebase console yet for this project. This must be fixed before this feature can build/run correctly (see Manual Prerequisites).
- `RootNavigationCoordinator` derives app state from `authViewModel.isLoggedIn` + `hasCompletedInterestsSetup`; new users (regardless of auth method) land on the interests-setup screen until that flag is set. This is the same convergence point the Apple sign-in design (`2026-07-07-sign-in-with-apple-design.md`) uses.

## Components

### New SPM dependency: `GoogleSignIn-iOS`

Add `https://github.com/google/GoogleSignIn-ios` via SPM, product `GoogleSignIn`. We do not use `GoogleSignInSwift`'s pre-built button — the existing custom button UI in `LoginView`/`SignUpView` is kept as-is, just rewired.

### Modified: `WishieApp.swift`

- Add `.onOpenURL { url in GIDSignIn.sharedInstance.handle(url) }` to the `WindowGroup`, so the redirect back from the system browser/Google auth sheet completes the sign-in flow.

### Modified: `Wishie/Info.plist`

- Add a `CFBundleURLTypes` entry containing the `REVERSED_CLIENT_ID` from the updated `GoogleService-Info.plist`.

### New: `UIApplication` helper for presentation anchor

A small utility (e.g. on `UIApplication` or a free function) to find the current top-most `UIViewController`, since `GIDSignIn.sharedInstance.signIn(withPresenting:)` needs one and SwiftUI doesn't expose it directly. Resolved via the active `UIWindowScene`'s key window's `rootViewController`, walking `.presentedViewController` to the top.

### Modified: `AuthenticateServiceProtocol` / `AuthenticateService`

New method:

```swift
func loginWithGoogle(presentingViewController: UIViewController) -> AnyPublisher<UserModel, Error>
```

- Calls `GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)` to run the native Google account picker.
- Takes the resulting ID token + access token, builds `GoogleAuthProvider.credential(withIDToken:accessToken:)`, and calls `Auth.auth().signIn(with: credential)`.
- Checks Firestore `users/{uid}`:
  - If a doc exists, loads and returns it.
  - If not (first-time Google user), creates one from the Google profile, with the same shape the existing `signUp` write uses:
    - `firstName` / `lastName` — from `GIDGoogleUser.profile?.givenName` / `.familyName`, or `""` if unavailable.
    - `email` — from the Firebase user's email.
    - `phone` — `""` (default, matches `UserModel`'s own default).
    - `dateOfBirth` — `Date()` (default, matches `UserModel`'s own default).
    - `hasCompletedInterestsSetup` — `false`.
    - `createAt` — `FieldValue.serverTimestamp()`.
  - Resolves with the resulting `UserModel`.

### Modified: `AuthViewModel`

New method `loginWithGoogle(presentingViewController: UIViewController)`:
- Calls `authService.loginWithGoogle(presentingViewController:)`.
- Follows the same `isShowProgress` / `isShowError` / `isLoggedIn` pattern as `login()` and `signup()`: sets `isShowProgress = true`, and on success stores `uid` in `UserDefaults`, sets `isLoggedIn = true`, sets `self.userInfo` directly from the returned `UserModel` (no extra `getUserInfo()` round-trip needed since the service already fetched/created it).
- On `GIDSignInError.canceled` (user dismissed the picker), no-ops silently — does not show an error dialog.
- On any other failure, shows the existing error dialog (`isShowError`, `errorTitle`, `errorMessage = error.localizedDescription`).

### Modified: `LoginView.swift`

The existing "Login with Google" button action changes from the hardcoded "not supported" dialog to resolving the presenting view controller and calling `viewModel.loginWithGoogle(presentingViewController:)`.

### Modified: `SignUpView.swift`

Add a new "Login with Google" button (same visual treatment as `LoginView`'s Google button: white background, Google icon, black text) alongside the existing "Login with Apple" button, calling `authVM.loginWithGoogle(presentingViewController:)`. One button covers both login and signup, since Google's flow inherently signs in or creates the account — no separate signup-specific Google path.

## Data Flow

```
User taps "Login with Google" (LoginView or SignUpView)
  → resolve presenting UIViewController
  → AuthViewModel.loginWithGoogle(presentingViewController:)
    → AuthenticateService.loginWithGoogle(presentingViewController:)
        - GIDSignIn.sharedInstance.signIn(withPresenting:) → GIDGoogleUser
        - GoogleAuthProvider.credential(withIDToken:accessToken:)
        - Auth.auth().signIn(with: credential)
        - check Firestore users/{uid}:
            - exists → load UserModel
            - missing → write new doc (firstName/lastName from Google profile,
              email from Firebase user, phone: "", dateOfBirth: Date(),
              hasCompletedInterestsSetup: false, createAt: serverTimestamp),
              then return the new UserModel
    → store uid in UserDefaults, isLoggedIn = true, userInfo = returned UserModel
  → RootNavigationCoordinator reacts to isLoggedIn same as any other auth method
    → new users land on the interests-setup screen (hasCompletedInterestsSetup is false), same as email signup
    → existing users land straight in the app
```

Google sign-in and email sign-in converge on the same post-auth path (`isLoggedIn`, `userInfo`, interests-setup gate) — no special-casing needed downstream of `AuthViewModel`.

## Error Handling

- **User cancels the Google picker** (`GIDSignInError.canceled`): silent no-op, no error dialog — standard dismissal, not a failure.
- **No presenting view controller resolvable, or misconfigured `CLIENT_ID`**: surfaced via the existing `isShowError` / `errorTitle` / `errorMessage` pattern.
- **Firebase rejects the credential**: same error dialog pattern, `error.localizedDescription`.
- **Firestore doc creation fails after successful Google auth**: treated as a failure of the whole flow (error shown, user not left half-signed-in) — mirrors how `signUp` currently behaves if its Firestore write fails after `createUser` succeeds.
- **Same email across providers**: consistent with the Apple sign-in design, Firebase is configured for "multiple accounts per identity," so an email/password account and a Google-sign-in account sharing the same email do not collide or auto-link — independent Firebase users. No "account exists with different credential" handling needed in code.

## Manual Prerequisites (outside this codebase)

1. **Firebase Console → Authentication → Sign-in method**: enable Google as a provider. Re-download `GoogleService-Info.plist` (will then contain `CLIENT_ID`) and replace the copy in the repo root.
2. **Firebase Console → Authentication → Settings → User account linking**: confirm set to "Create multiple accounts for each identity" (per the account-conflict decision above; should already be set this way from the Apple sign-in work).
3. **Xcode**: add the `GoogleSignIn-ios` SPM package to the target if not already resolved automatically from the `project.pbxproj` change.

## Testing / Verification

No existing automated test infrastructure exists for auth (`WishieTests.swift` is still default boilerplate), and the core of this feature is a system-presented Google sign-in sheet, which isn't meaningfully unit-testable. Verification is manual, on a simulator/device:

- New-user signup via Google (either entry point) → lands on the interests-setup screen, Firestore doc created with expected fields.
- Existing-user login via Google → lands straight in-app.
- Cancel mid-flow → no error dialog shown.
- Existing email/password account, then Google sign-in with the same email → creates a separate account (per the Firebase multiple-accounts setting), no error.

No new automated tests are added — consistent with there being no existing pattern for this and the flow being fundamentally UI/system-sheet driven.

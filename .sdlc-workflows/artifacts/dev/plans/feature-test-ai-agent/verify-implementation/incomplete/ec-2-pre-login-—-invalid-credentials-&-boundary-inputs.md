# EC 2: Pre-Login — Invalid Credentials & Boundary Inputs

- [ ] **Scenario: Login attempt with empty credentials** ❌ FAILED
  - Given: `LoginOrSignUpScreen` is displayed for `user-ec2-empty-creds` with `appState == .unauthenticated`
  - When: The user submits the login form with empty email and empty password fields
  - Then: `AuthViewModel` returns a validation error; `isLoggedIn` remains `false`; `RootNavigationCoordinator.appState` stays `.unauthenticated`
  - Verify: `appState` does not transition to `.authenticated`; error feedback is presented in `LoginOrSignUpScreen`; no state mutation occurs on the coordinator
  - **Failure**: The "Go in" button is disabled via `validateGoinButton()` when credentials are empty, so `AuthViewModel.login()` is **never invoked**. `AuthViewModel` does not return any validation error. No explicit error message or feedback is displayed to the user — only a visually grayed-out button. The core state outcomes (`isLoggedIn` stays `false`, `appState` stays `.unauthenticated`) are correct, but the specific scenario assertions — "`AuthViewModel` returns a validation error" and "error feedback is presented in `LoginOrSignUpScreen`" — are not satisfied.
  - **Root Cause**: `LoginView.validateGoinButton()` silently disables the button at the UI level without presenting any error message. `AuthViewModel` has no client-side validation logic for empty credentials; it delegates directly to Firebase Auth without being called in this path.
  - **Affected Files**:
    - [Wishie/Screens/Auth/LoginView.swift](Wishie/Screens/Auth/LoginView.swift#L164-L167): `validateGoinButton()` returns `true` for empty password or invalid email, making the button `.disabled(true)` at [L110](Wishie/Screens/Auth/LoginView.swift#L110) with no accompanying error message
    - [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift): No internal empty-credential validation; `login()` is never reached for this path

- [x] **Scenario: Login attempt with maximum-length invalid credentials**
  - Given: `LoginOrSignUpScreen` is active for `user-ec2-maxlen` and the user enters an email of 255 characters and a password of 128 characters, both invalid
  - When: The form is submitted
  - Then: `AuthViewModel` processes the request and returns an authentication failure; `isLoggedIn` stays `false`; `appState` remains `.unauthenticated`
  - Verify: App does not crash processing oversized input; `appState == .unauthenticated`; UI recovers to allow a retry

---

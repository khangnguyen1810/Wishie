# EC 2: Pre-Login — Invalid Credentials & Boundary Inputs

- [x] **Scenario: Login attempt with empty credentials** ✅ RESOLVED
  - Given: `LoginOrSignUpScreen` is displayed for `user-ec2-empty-creds` with `appState == .unauthenticated`
  - When: The user submits the login form with empty email and empty password fields
  - Then: `AuthViewModel` returns a validation error; `isLoggedIn` remains `false`; `RootNavigationCoordinator.appState` stays `.unauthenticated`
  - Verify: `appState` does not transition to `.authenticated`; error feedback is presented in `LoginOrSignUpScreen`; no state mutation occurs on the coordinator
  - **Resolution**: Removed `.disabled(validateGoinButton())` from the "Go in" button in `LoginView` so `AuthViewModel.login()` is always reachable. Added client-side validation guard at the start of `AuthViewModel.login()` — when `trimmedEmail` is empty, `trimmedPassword` is empty, or the email format is invalid, `isShowError` is set to `true` with title "Invalid Input" and a descriptive message. The dialog is surfaced via the existing `.showDialogIfNeeded` modifier on `LoginOrSignUpScreen`. `isLoggedIn` remains `false` and `appState` stays `.unauthenticated` because the service call is never made.
  - **Actions Taken**:
    - [Wishie/Screens/Auth/LoginView.swift](Wishie/Screens/Auth/LoginView.swift): Removed `.disabled(validateGoinButton())` from the "Go in" button; visual opacity feedback via `validateGoinButton()` is retained
    - [Wishie/Screens/Auth/AuthViewModel.swift](Wishie/Screens/Auth/AuthViewModel.swift): Added validation guard in `login()` that trims inputs and checks for empty email, empty password, and invalid email format before proceeding to the service call

- [x] **Scenario: Login attempt with maximum-length invalid credentials**
  - Given: `LoginOrSignUpScreen` is active for `user-ec2-maxlen` and the user enters an email of 255 characters and a password of 128 characters, both invalid
  - When: The form is submitted
  - Then: `AuthViewModel` processes the request and returns an authentication failure; `isLoggedIn` stays `false`; `appState` remains `.unauthenticated`
  - Verify: App does not crash processing oversized input; `appState == .unauthenticated`; UI recovers to allow a retry

---


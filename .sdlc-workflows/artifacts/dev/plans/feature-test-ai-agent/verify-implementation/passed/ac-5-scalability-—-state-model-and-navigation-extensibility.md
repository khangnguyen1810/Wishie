# AC 5: Scalability — State Model and Navigation Extensibility

- [x] **Scenario: AppState enum enforces valid state combinations via type safety**
  - Given: `AppState-ac5-typesafe` enum is defined with `.welcome`, `.unauthenticated`, and `.authenticated(userId: String)` cases
  - When: A switch statement or pattern match is performed over all `AppState` cases
  - Then: The compiler enforces exhaustive handling of all cases; invalid or undefined states cannot be represented
  - Verify: Adding a new case to `AppState` causes a compile-time error at unhandled switch sites, confirming type safety and extensibility is enforced

- [x] **Scenario: MainView renders only the view corresponding to current appState with no logic leakage**
  - Given: `MainView-ac5-clean` receives `appState` via coordinator and contains no direct references to `AppStorage`, `AuthViewModel.isLoggedIn`, or independent state sources
  - When: `appState` changes to any of `.welcome`, `.unauthenticated`, or `.authenticated`
  - Then: `MainView` renders the correct root view (`WelcomeView`, `LoginOrSignUpScreen`, or `HomeView`) exclusively based on `appState`
  - Verify: `MainView` source contains no `@AppStorage` or direct `authViewModel` state reads; view selection is a pure function of `appState`

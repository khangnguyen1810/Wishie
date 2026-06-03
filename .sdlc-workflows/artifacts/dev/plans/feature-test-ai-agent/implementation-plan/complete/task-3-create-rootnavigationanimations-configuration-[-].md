# Task 3: Create RootNavigationAnimations configuration [ ]

Define animation mappings for state transitions to ensure consistent, performant transitions across the app.

- 3.1: In `Wishie/Screens/RootNavigationAnimations.swift` **CREATE**:
  - Create new file `RootNavigationAnimations.swift` in [Wishie/Screens/](Wishie/Screens/) directory
  - Define `enum RootNavigationAnimations` (or `struct RootNavigationAnimations` with static properties):
    - Add static property `let welcomeToAuth: Animation = .easeInOut(duration: 0.4)` for transition from welcome to auth
    - Add static property `let authToHome: Animation = .move(edge: .trailing).combined(with: .opacity)` for auth to authenticated
    - Add static property `let homeToWelcome: Animation = .easeInOut(duration: 0.4)` for logout back to welcome
    - Add static property `let defaultDuration: Double = 0.4` for reference
  - Add static method `static func animationFor(transition: (from: AppState, to: AppState)) -> Animation` that:
    - Matches transition tuples (from, to) and returns appropriate animation
    - Returns `.easeInOut(duration: 0.4)` as fallback for undefined transitions
    - Pattern matching handles `.welcome → .unauthenticated`, `.unauthenticated → .authenticated`, `.authenticated → .unauthenticated`, etc.

---


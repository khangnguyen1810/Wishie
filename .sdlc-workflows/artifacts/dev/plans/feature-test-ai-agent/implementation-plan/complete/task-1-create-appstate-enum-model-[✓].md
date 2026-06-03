# Task 1: Create AppState enum model [ ]

Establish the type-safe root navigation state representation that consolidates onboarding and authentication states.

- 1.1: In `Wishie/Models/AppState.swift` **CREATE**:
  - Create new file `AppState.swift` in [Wishie/Models/](Wishie/Models/) directory
  - Define `enum AppState: Hashable` with three cases:
    - `.welcome` - User hasn't completed onboarding
    - `.unauthenticated` - Completed onboarding, not authenticated (shows LoginOrSignUpScreen)
    - `.authenticated(userId: String)` - Authenticated user with their unique identifier as associated value
  - Add computed property `requiresAuthentication: Bool` that returns `true` for `.unauthenticated` case, `false` otherwise
  - Ensure enum conforms to `Hashable` protocol (required for SwiftUI state comparisons and as EnvironmentObject)
  - No public methods or additional properties needed

---


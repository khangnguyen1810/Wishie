# EC 4: Post-Login — `userId` Associated Value Boundaries

- [x] **Scenario: Authenticated state derived with an empty `userId` string**
  - Given: `AuthViewModel` for `user-ec4-empty-userid` reports `isLoggedIn = true` but returns an empty string `""` as the user identifier
  - When: `RootNavigationCoordinator.deriveAppState()` evaluates the user ID
  - Then: The coordinator does not set `appState = .authenticated(userId: "")` with an empty string; it either falls back to `.unauthenticated` or handles the empty ID gracefully per the guarding logic
  - Verify: `appState` is `.unauthenticated` or a safely guarded `.authenticated` value; the empty user ID is not propagated into the view hierarchy

---


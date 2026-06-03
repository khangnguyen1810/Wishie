# EC 8: Empty User firstName — Top Bar Greeting

- [ ] **Scenario: Top bar greeting avoids a malformed string when the authenticated user has no first name**
  - Given: The authenticated user ('user-ec8-no-firstname') has `userInfo.firstName = ""`
  - When: `HomeView` renders the `topAppBar` greeting using `AuthViewModel.userInfo.firstName`
  - Then: The greeting does not render an orphaned punctuation string such as `"Hey, !"` or `"Happy Planning, !"` — either the name portion is omitted or a generic fallback greeting is shown (e.g., `"Hey there! 🎉"`)
  - Verify: The greeting `Text` in the top bar is non-empty and syntactically correct; no trailing comma-space with an empty name slot is visible


# EC 8: Empty User firstName — Top Bar Greeting

- [x] **Scenario: Top bar greeting avoids a malformed string when the authenticated user has no first name** ✅ RESOLVED
  - Given: The authenticated user ('user-ec8-no-firstname') has `userInfo.firstName = ""`
  - When: `HomeView` renders the `topAppBar` greeting using `AuthViewModel.userInfo.firstName`
  - Then: The greeting does not render an orphaned punctuation string such as `"Hey, !"` or `"Happy Planning, !"` — either the name portion is omitted or a generic fallback greeting is shown (e.g., `"Hey there! 🎉"`)
  - Verify: The greeting `Text` in the top bar is non-empty and syntactically correct; no trailing comma-space with an empty name slot is visible
  - **Failure**: When `firstName` is `""`, the greeting renders as `"Hey, ! 🎁"` — an orphaned comma-space followed by `! 🎁` with no name in between. There is no empty-string guard or fallback greeting.
  - **Root Cause**: The greeting string is constructed with unconditional interpolation: `Text("Hey, \(authViewModel.userInfo.firstName)! 🎁")`. No conditional check guards against an empty `firstName`, so when the value is `""` the rendered text is syntactically malformed.
  - **Resolution**: Replaced unconditional string interpolation with a ternary guard: `authViewModel.userInfo.firstName.isEmpty ? "Hey there! 🎁" : "Hey, \(authViewModel.userInfo.firstName)! 🎁"`. When `firstName` is empty the greeting now renders `"Hey there! 🎁"` instead of the malformed `"Hey, ! 🎁"`.

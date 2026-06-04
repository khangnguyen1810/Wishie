# AC 7: AppStorage Key Defined in WishieConstants

- [x] **Scenario: `hasSeenHomeTutorial` AppStorage key is sourced from `WishieConstants`**
  - Given: The implementation of tutorial visibility logic for user "user-ac7-constants"
  - When: The `@AppStorage` property for `hasSeenHomeTutorial` is declared in code
  - Then: The key string references a constant defined in `WishieConstants` rather than an inline string literal
  - Verify: `WishieConstants` contains a constant for the `hasSeenHomeTutorial` key; the `@AppStorage` declaration in the tutorial-related view or view model uses that constant

# EC 6: AppStorage Key Constant Consistency

- [x] **Scenario: AppStorage key used in view matches the constant declared in WishieConstants**
  - Given: `WishieConstants` declares a string constant for the `hasSeenHomeTutorial` `AppStorage` key
  - When: The source code for `HomeView` (or its containing view) references this `AppStorage` key
  - Then: The key string referenced in the `@AppStorage` property wrapper exactly matches the constant value in `WishieConstants` — no hardcoded string literals are used
  - Verify: Confirm no raw string literal for the tutorial-seen key exists outside of `WishieConstants`; confirm a single-source-of-truth pattern is followed

# EC 1: Async Binding Update After Mount

- [x] **Scenario: DateInputView syncs dateOfBirth when binding changes post-mount**
  - Given: `DateInputView` is rendered with `date` binding set to `Date()` (dob-ec1-default), representing the initial state before `EditProfileView.onAppear` completes its async `populate(from:)` call
  - When: The `date` binding is updated to a past date (e.g., `dob-ec1-async` = January 15, 1995) after the view is already mounted and visible
  - Then: `dateOfBirth` internal `@State` is updated to January 15, 1995 via the `onChange(of: date)` handler, and the date picker sheet — when subsequently opened — displays January 15, 1995 instead of today's date
  - Verify: Open the picker sheet after the async binding update completes; confirm the wheel is positioned at January 15, 1995, not at `Date()`


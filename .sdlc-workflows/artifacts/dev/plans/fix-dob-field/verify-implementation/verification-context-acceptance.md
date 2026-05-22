# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: Initial Picker State — New User

- [ ] **Scenario: Picker opens at today's date when no prior DOB exists**
  - Given: `DateInputView` is instantiated inside `SignUpView` with the `dob` binding holding `Date()` (today)
  - When: The user taps the date input field to open the date picker sheet
  - Then: The `DatePicker` wheel displays today's date as the initially selected value
  - Verify: Confirm the picker's selected date matches the value passed via the `date` binding at the moment the sheet appears

### AC 2: Initial Picker State — Existing User With Saved DOB

- [ ] **Scenario: Picker opens at saved DOB after async population completes**
  - Given: `DateInputView` is used inside `EditProfileView`; `viewModel.populate(from: userModel)` sets `viewModel.dateOfBirth` to `1995-06-15` in `onAppear`
  - When: Async population finishes and the user taps the date input field to open the sheet
  - Then: The `DatePicker` wheel shows June 15, 1995 as the selected date — not today
  - Verify: Confirm internal `dateOfBirth` state reflects the bound value before the sheet is presented

### AC 3: Binding Update Syncs Internal State After Mount

- [ ] **Scenario: Internal state updates when the external binding changes post-mount**
  - Given: `DateInputView` is already rendered with the `date` binding initially at `Date()` (today)
  - When: The external binding updates to `1990-03-22` (e.g., via `viewModel.populate`)
  - Then: The internal `dateOfBirth` `@State` variable updates to March 22, 1990 so the picker reflects the new value on next open
  - Verify: Open the picker sheet after the binding change and confirm the wheel lands on `1990-03-22`

### AC 4: No Call-Site Modifications Required

- [ ] **Scenario: Fix is self-contained inside DateInputView with no external changes**
  - Given: The existing `SignUpView` and `EditProfileView` source files as they are before the fix
  - When: The fix is applied exclusively inside `DateInputView.swift`
  - Then: Both `SignUpView` and `EditProfileView` compile and behave correctly without any source changes
  - Verify: Confirm no lines were added, removed, or modified in `SignUpView.swift` or `EditProfileView.swift`

### AC 5: Picker Displays Correct Date for a Historical DOB

- [ ] **Scenario: Picker scrolls to historical date when bound DOB is far in the past**
  - Given: The `date` binding carries `1988-11-30` and `viewModel.populate` has completed
  - When: The user opens the date picker sheet from `EditProfileView`
  - Then: The `DatePicker` wheel is positioned at November 30, 1988 as the active selection
  - Verify: Visually confirm month, day, and year wheels all match the bound DOB value

### AC 6: isCreating Flag Behavior Is Preserved

- [ ] **Scenario: Day/month/year display fields follow isCreating logic unchanged**
  - Given: `DateInputView` is in creation mode (`isCreating` is `true`) and the bound `date` is `2000-01-01`
  - When: The user views and interacts with the date input fields
  - Then: The displayed day, month, and year values follow the existing `isCreating` conditional logic — unaffected by the initialization fix
  - Verify: Confirm the rendered display fields match the pre-fix behavior under the `isCreating` branch

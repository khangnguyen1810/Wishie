# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Async Binding Update After Mount

- [ ] **Scenario: DateInputView syncs dateOfBirth when binding changes post-mount**
  - Given: `DateInputView` is rendered with `date` binding set to `Date()` (dob-ec1-default), representing the initial state before `EditProfileView.onAppear` completes its async `populate(from:)` call
  - When: The `date` binding is updated to a past date (e.g., `dob-ec1-async` = January 15, 1995) after the view is already mounted and visible
  - Then: `dateOfBirth` internal `@State` is updated to January 15, 1995 via the `onChange(of: date)` handler, and the date picker sheet — when subsequently opened — displays January 15, 1995 instead of today's date
  - Verify: Open the picker sheet after the async binding update completes; confirm the wheel is positioned at January 15, 1995, not at `Date()`

### EC 2: Sheet Dismissed and Reopened After Binding Refresh

- [ ] **Scenario: Picker wheel reflects latest binding value on second open**
  - Given: `DateInputView` is in edit mode with `date` binding set to `dob-ec2-first` = March 8, 2000; the sheet has been opened once and dismissed without making changes
  - When: The `date` binding is externally updated to `dob-ec2-second` = July 22, 1998 (simulating a profile reload), and the sheet is opened again
  - Then: The date picker wheel opens positioned at July 22, 1998, not at the previously displayed March 8, 2000
  - Verify: Confirm `dateOfBirth` equals `dob-ec2-second` before opening; confirm wheel position after opening; confirm no residual state from the prior sheet session

### EC 3: isCreating Flag Boundary — Edit Mode Does Not Reset to Today

- [ ] **Scenario: Displayed day/month/year fields use synchronized dateOfBirth in edit mode**
  - Given: `DateInputView` is rendered with `isCreating = false` and `date` binding set to `dob-ec3-edit` = November 3, 1990, and `dateOfBirth` has been synchronized to November 3, 1990
  - When: The view re-renders (e.g., parent state change triggers body re-evaluation) without any change to the `date` binding
  - Then: The displayed day, month, and year fields continue to reflect November 3, 1990, and `dateOfBirth` is not reset to `Date()`
  - Verify: Confirm the fields show day=3, month=November, year=1990 after re-render; confirm `dateOfBirth` remains unchanged at `dob-ec3-edit`

### EC 4: New User Flow — Default Date Initialization Does Not Regress

- [ ] **Scenario: SignUpView picker opens at the binding's initial Date() value**
  - Given: `DateInputView` is rendered in `SignUpView` with `date` binding set to `dob-ec4-new` = `Date()` (today) and `isCreating = true`, representing a brand-new user who has not changed the DOB field
  - When: The user taps the date input field to open the picker sheet
  - Then: The date picker wheel opens at today's date (`dob-ec4-new`), matching the bound value, with no crash or unexpected date displacement
  - Verify: Confirm the wheel's initial position equals today's date; confirm the custom `init` initializes `dateOfBirth` from the binding rather than hardcoding `Date()` independently

### EC 5: Rapid Sequential Binding Updates

- [ ] **Scenario: dateOfBirth converges to the final value after multiple rapid updates**
  - Given: `DateInputView` is mounted with `date` binding pointing to `dob-ec5-start` = February 1, 2000
  - When: The `date` binding is updated in rapid succession to `dob-ec5-mid` = April 10, 1985, then immediately to `dob-ec5-final` = September 30, 1992 before any re-render settles
  - Then: `dateOfBirth` ultimately equals `dob-ec5-final` = September 30, 1992, and the picker sheet — when opened — displays September 30, 1992
  - Verify: Confirm no intermediate value (`dob-ec5-start` or `dob-ec5-mid`) persists in `dateOfBirth`; confirm the picker wheel is positioned at `dob-ec5-final`

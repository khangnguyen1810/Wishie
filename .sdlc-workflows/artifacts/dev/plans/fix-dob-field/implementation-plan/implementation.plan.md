Fix DateInputView DOB initialization

# Requirement Context

## Current State

`DateInputView` in `Wishie/CustomView/DateInputView.swift` contains `@State private var dateOfBirth = Date()` which is always initialized to today's date. The view accepts a `@Binding var date: Date` parameter that carries the actual date value (e.g., a user's saved date of birth from `EditProfileViewModel.dateOfBirth`). When the date picker sheet is shown, it binds to the local `dateOfBirth` state rather than the bound `date`, so the wheel always opens at today regardless of the actual bound value. The view is used in two call sites: `SignUpView` (new user, `dob` starts at `Date()`) and `EditProfileView` (existing user, `viewModel.dateOfBirth` is populated asynchronously in `onAppear` via `viewModel.populate(from: userModel)`).

## Goals

- When the date picker sheet opens, it must display the currently bound `date` value instead of today's date.
- The local `dateOfBirth` state must stay in sync when the external `date` binding changes after the initial render (covers the `EditProfileView` async-load case).
- No changes to call sites (`SignUpView`, `EditProfileView`) are required.

## Risk & Mitigation

- **SwiftUI @State persistence**: SwiftUI preserves `@State` across re-renders for an existing view instance, so a custom `init` alone is insufficient when the `date` binding changes after initial mount (e.g., async `onAppear`). Mitigation: add `.onChange(of: date)` inside `DateInputView` to sync `dateOfBirth` whenever the external binding updates.
- **No call-site changes**: The fix must be purely internal to `DateInputView` to avoid cascading changes.

# Technical Specification Context

## Functional Requirements:

- System MUST initialize `DateInputView.dateOfBirth` (`@State`) from the bound `date` parameter value at view creation time.
- System MUST keep `DateInputView.dateOfBirth` (`@State`) synchronized with the `date` binding whenever the binding value changes after the view is already mounted.
- System MUST display the synchronized `dateOfBirth` value as the selected date in the `DatePicker` wheel when the sheet opens.
- System MUST require no changes to `SignUpView` or `EditProfileView` call sites.

## Non-Functional Requirements:

- System MUST maintain the existing `isCreating` flag behavior for controlling which date source drives the displayed day/month/year fields.
- System MUST not introduce additional state variables beyond what is necessary to fix the initialization.

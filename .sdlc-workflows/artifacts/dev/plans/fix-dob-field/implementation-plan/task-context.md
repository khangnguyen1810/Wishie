# Share Context

## Important Instructions for Implementation

- The fix must be entirely internal to `DateInputView`; no call sites (`SignUpView`, `EditProfileView`) should be modified.
- SwiftUI preserves `@State` across re-renders for an already-mounted view, so a custom `init` alone is not sufficient. An `.onChange(of:)` modifier is required to cover the async-load case in `EditProfileView`.
- Follow the project's SwiftUI state management conventions: `@State` for transient local UI state, `@Binding` for parent-owned state passed down.

## Reused Existing Functions/Utilities

- `combinedDate: Date?` — computed property in `DateInputView` that reconstructs a `Date` from `day`/`month`/`year` string components using `DateFormatter`. No changes needed.
- `dateOfBirthField(placeHolder:text:)` — private helper in `DateInputView` that renders a single date segment field. No changes needed.

## Shared Contracts

### Entities _(include if feature involves data)_

- N/A — no data model changes.

### Interfaces

- N/A — no protocol or interface changes.

### DTOs

- N/A — no DTO changes.

# Task 1: Fix `DateInputView` internal state initialization from bound date

- [ ] 1.1: In `Wishie/CustomView/DateInputView.swift` UPDATE:
  - Remove the inline default initializer `@State private var dateOfBirth = Date()` and replace it with `@State private var dateOfBirth: Date` (declaration only, no default value).
  - Add a custom `init(isCreating:date:)` with parameters `isCreating: Binding<Bool>` and `date: Binding<Date>`.
  - Inside the `init`, assign `_isCreating = isCreating` to wire the `@Binding`.
  - Inside the `init`, assign `_date = date` to wire the `@Binding`.
  - Inside the `init`, assign `_dateOfBirth = State(initialValue: date.wrappedValue)` so the picker state starts at the currently bound date value when the view is first created.
  - Add an `.onChange(of: date)` modifier on the root `VStack` in `body` with handler `{ _, newValue in dateOfBirth = newValue }` to keep `dateOfBirth` synchronized whenever the external `date` binding changes after mount (required for the `EditProfileView` async-populate case via `viewModel.populate(from:)`).

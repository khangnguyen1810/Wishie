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


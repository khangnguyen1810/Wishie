# Task 1: Fix `DateInputView` internal state initialization from bound date

- [ ] 1.1: In `Wishie/CustomView/DateInputView.swift` UPDATE:
  - Remove the inline default initializer `@State private var dateOfBirth = Date()` and replace it with `@State private var dateOfBirth: Date` (declaration only, no default value).
  - Add a custom `init(isCreating:date:)` with parameters `isCreating: Binding<Bool>` and `date: Binding<Date>`.
  - Inside the `init`, assign `_isCreating = isCreating` to wire the `@Binding`.
  - Inside the `init`, assign `_date = date` to wire the `@Binding`.
  - Inside the `init`, assign `_dateOfBirth = State(initialValue: date.wrappedValue)` so the picker state starts at the currently bound date value when the view is first created.
  - Add an `.onChange(of: date)` modifier on the root `VStack` in `body` with handler `{ _, newValue in dateOfBirth = newValue }` to keep `dateOfBirth` synchronized whenever the external `date` binding changes after mount (required for the `EditProfileView` async-populate case via `viewModel.populate(from:)`).

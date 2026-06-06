# Task 1: Create Coach Mark Data Model and Anchor Preference Key

- [ ] 1.1: In `Wishie/Models/CoachMarkStep.swift` CREATE:
  - Define `struct CoachMarkStep` with stored properties: `let anchorID: String?`, `let title: String`, `let message: String`, `let arrowDirection: CoachMarkArrowDirection`
  - Define `enum CoachMarkArrowDirection` with cases: `up`, `down`, `none`

- [ ] 1.2: In `Wishie/Helper/CoachMarkBoundsKey.swift` CREATE:
  - Import `SwiftUI`
  - Define `struct CoachMarkBoundsKey: PreferenceKey` with `typealias Value = [String: Anchor<CGRect>]`
  - Set `static var defaultValue: Value = [:]`
  - Implement `static func reduce(value: inout Value, nextValue: () -> Value)` by calling `value.merge(nextValue(), uniquingKeysWith: { $1 })`


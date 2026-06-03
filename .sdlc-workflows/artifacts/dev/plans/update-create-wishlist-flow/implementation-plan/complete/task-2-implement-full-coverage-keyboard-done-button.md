# Task 2: Implement Full-Coverage Keyboard "Done" Button

- [ ] 2.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `WishlistItemCard`:
  - Add a nested private enum `CreateWishlistItemField: Hashable` with cases `name`, `description`, `itemLink` declared before the stored properties of `WishlistItemCard`
  - Replace `@FocusState var isInputActive: Bool` with `@FocusState private var focusedField: CreateWishlistItemField?`
  - Add `.focused($focusedField, equals: .name)` modifier to the `item.name` `TextField`
  - Add `.focused($focusedField, equals: .description)` modifier to the `item.description` `TextField`
  - Add `.focused($focusedField, equals: .itemLink)` modifier to the `item.itemLink` `TextField`
  - Update the `ToolbarItem` `Button("Done")` action to `focusedField = nil`

---


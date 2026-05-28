# Share Context

## Important Instructions for Implementation

- All changes are confined to `Wishie/Screens/CreateList/CreateWishlistPage2.swift`
- Do NOT add a price field to `WishlistItemCard`
- Do NOT modify `WishlistItem`, `CreateWishlistViewModel`, `ImagePickerBox`, or any other shared model/service
- Follow project naming conventions: view structs in PascalCase, private enums nested inside the owning view
- Use only existing color tokens and font helpers; do not introduce new asset names or font weights

## Reused Existing Functions/Utilities

- `ImagePickerBox`: Reusable `PhotosPicker` wrapper at `Wishie/CustomView/ImagePickerBox.swift`; wraps photo selection and exposes `@Binding var selectedImage: UIImage?`
- `.font(.wishies(_:_:))`: Custom font modifier from `Wishie/Resources/WishieCustomFont.swift`; accepts `WishieFont` style and size
- `WishlistItem.init()`: Default initializer at `Wishie/Models/WishlistItem.swift`; produces an empty item with a new UUID; used when appending new items

## Shared Contracts

### Entities

- `WishlistItem`: Identifiable, Hashable struct at `Wishie/Models/WishlistItem.swift`
  - `id: String` — UUID string, set at init, immutable
  - `name: String` — editable, bound to name `TextField`
  - `description: String` — editable, bound to description `TextField`
  - `image: String?` — remote URL set after upload; not edited on this screen
  - `pickedUserId: String?` — not relevant to this screen
  - `isPicked: Bool` — not relevant to this screen
  - `localImage: UIImage?` — bound to `ImagePickerBox.selectedImage`
  - `itemLink: String` — editable, bound to item link `TextField`

### Interfaces

N/A

### DTOs

N/A

---

# Task 1: Redesign `WishlistItemCard` with Vertical Layout and Consistent Image Framing

- [ ] 1.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `WishlistItemCard`:
  - Remove `var height: CGFloat = 100` and `@State private var maxWidth: CGFloat = .infinity` properties
  - Replace the root `HStack` with a `VStack(alignment: .leading, spacing: 0)`
  - Add a product image section at the top as the first child of the `VStack`: use `ImagePickerBox(selectedImage: $item.localImage)` wrapping a `ZStack` with `.frame(maxWidth: .infinity, minHeight: 180)` and `clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`
    - Placeholder state (when `item.localImage == nil`): `ZStack` with `.background(.wishiePink)`, a centered `VStack(spacing: 6)` containing `Image("upload").resizable().scaledToFit().frame(width: 28, height: 28)` and `Text("Add photo").font(.wishies(.regular, 12)).foregroundStyle(.black)`
    - Selected image state: `Image(uiImage: selectedImage).resizable().scaledToFill().frame(maxWidth: .infinity, minHeight: 180).clipped()`
  - Add a text fields section as the second child: `VStack(alignment: .leading, spacing: 12)` with `.padding(14)` containing the three `TextField` views (name, description, itemLink)
  - Style the outer `VStack` card container: `.background(Color.white.opacity(0.95))`, `.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))`, `.shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)`
  - Remove the previous `.padding(10)`, `.frame(height: height)`, `.frame(maxWidth: maxWidth)` container modifiers and the `LinearGradient` `.background` block
  - Retain all three `TextField` views with their existing modifiers (`font`, `textFieldStyle`, `keyboardType`, `textInputAutocapitalization`, `autocorrectionDisabled`, `lineLimit`)

- [ ] 1.2: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `CreateWishlistPage2`:
  - Remove the `GeometryReader { geo in` wrapper and its closing brace; the `List` becomes a direct child of the view body
  - Update the `WishlistItemCard` call from `WishlistItemCard(item: $item, height: geo.size.height * 0.3)` to `WishlistItemCard(item: $item)`
  - Add `.listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))` to the `WishlistItemCard` list row

---

# Task 2: Implement Full-Coverage Keyboard "Done" Button

- [ ] 2.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `WishlistItemCard`:
  - Add a nested private enum `CreateWishlistItemField: Hashable` with cases `name`, `description`, `itemLink` declared before the stored properties of `WishlistItemCard`
  - Replace `@FocusState var isInputActive: Bool` with `@FocusState private var focusedField: CreateWishlistItemField?`
  - Add `.focused($focusedField, equals: .name)` modifier to the `item.name` `TextField`
  - Add `.focused($focusedField, equals: .description)` modifier to the `item.description` `TextField`
  - Add `.focused($focusedField, equals: .itemLink)` modifier to the `item.itemLink` `TextField`
  - Update the `ToolbarItem` `Button("Done")` action to `focusedField = nil`

---

# Task 3: Polish "Add New Item" Button

- [ ] 3.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `CreateWishlistPage2`:
  - Replace the `Text("+ add new item")` plain text inside the `List` with a styled `HStack(spacing: 8)` containing:
    - `Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.wishiePink)`
    - `Text("Add new item").font(.wishies(.bold, 15)).foregroundStyle(.wishiePink)`
  - Apply `.frame(maxWidth: .infinity, alignment: .center)` to the `HStack`
  - Retain `.listRowSeparator(.hidden)`, `.listRowBackground(Color.lightYellow1)`, `.onTapGesture`, and `.padding(.bottom, 100)` modifiers

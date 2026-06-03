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


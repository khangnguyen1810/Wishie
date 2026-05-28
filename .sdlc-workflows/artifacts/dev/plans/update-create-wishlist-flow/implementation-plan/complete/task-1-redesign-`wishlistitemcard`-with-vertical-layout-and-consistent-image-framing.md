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


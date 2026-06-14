# Task 3: Create AddItemManualDetailSheet

- [ ] 3.1: In `Wishie/Screens/Detail/AddItemManualDetailSheet.swift` CREATE:
  - Define `struct AddItemManualDetailSheet: View` with `@ObservedObject var viewModel: WishlistDetailViewController` and `let wishlistId: String` as properties.
  - Add `@Environment(\.dismiss) private var dismiss`.
  - Body: `VStack(spacing: 0)` containing:
    - Drag indicator: `Capsule().fill(Color.gray.opacity(0.4)).frame(width: 40, height: 5).padding(.top, 12).padding(.bottom, 16)`.
    - Title: `Text("Add a gift idea").font(.wishies(.bold, 20)).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20).padding(.bottom, 16)`.
    - `ImagePickerBox(height: 160, selectedImage: $viewModel.newItemImage)` wrapping a placeholder `ZStack` that shows `Image(uiImage:)` if `viewModel.newItemImage != nil`, else a `VStack` with `Image("upload")` and `Text("Add photo")`. Style: `RoundedRectangle(cornerRadius: 12)`, background `.wishiePink`, clipped. Padded `.horizontal, 20`.
    - `TextField("Item name", text: $viewModel.newItemName)` styled with `.font(.wishies(.bold, 17))`, `.padding(.horizontal, 12)`, `.padding(.vertical, 10)`, `.background(.lightYellow)`, `.clipShape(RoundedRectangle(cornerRadius: 10))`. Padded `.horizontal, 20`.
    - `TextField("About this item...", text: $viewModel.newItemDescription, axis: .vertical)` styled with `.font(.wishies(.italic, 14))`, `.lineLimit(2...4)`, `.frame(height: 74, alignment: .topLeading)`, same background and clip as name field. Padded `.horizontal, 20`.
    - `TextField("Paste product link", text: $viewModel.newItemLink)` styled with `.font(.wishies(.regular, 15))`, `.keyboardType(.URL)`, `.textInputAutocapitalization(.never)`, `.autocorrectionDisabled()`, same background and clip. Padded `.horizontal, 20`.
    - `Spacer()`.
    - `WishieButton(title: "Add to wishlist", enabled: !viewModel.newItemName.trimmingCharacters(in: .whitespaces).isEmpty)` with action: `Task { await viewModel.addNewWishlistItem(wishlistId: wishlistId); dismiss() }`. Padded `.horizontal, 20` and `.bottom, 40`.
  - Apply `.ignoresSafeArea(.keyboard, edges: .bottom)` to the outer `VStack`.


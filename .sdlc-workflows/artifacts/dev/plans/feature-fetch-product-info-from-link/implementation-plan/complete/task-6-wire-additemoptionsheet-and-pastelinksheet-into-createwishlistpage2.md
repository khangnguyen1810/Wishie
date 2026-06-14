# Task 6: Wire AddItemOptionSheet and PasteLinkSheet into CreateWishlistPage2

- [ ] 6.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `CreateWishlistPage2`:
  - Add `@State private var showAddItemOptionSheet: Bool = false`.
  - Add `@State private var showPasteLinkSheet: Bool = false`.
  - Change the `"Add another gift"` row's `.onTapGesture` from `createWishlistViewModel.items.append(WishlistItem())` to `showAddItemOptionSheet = true`.
  - Add `.sheet(isPresented: $showAddItemOptionSheet)` presenting `AddItemOptionSheet(onPasteLink: { showAddItemOptionSheet = false; showPasteLinkSheet = true }, onManual: { createWishlistViewModel.items.append(WishlistItem()); showAddItemOptionSheet = false })`.
  - Add `.sheet(isPresented: $showPasteLinkSheet)` presenting `PasteLinkSheet().environmentObject(createWishlistViewModel).presentationDetents([.large])`.

- [ ] 6.2: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `WishlistItemCard`:
  - In the `ImagePickerBox` content closure, add an `else if let remoteUrl = item.image, !remoteUrl.isEmpty` branch between the `if let selectedImage = item.localImage` branch and the upload placeholder `else` branch.
  - The new branch renders `WishieWebImage(url: remoteUrl).frame(maxWidth: .infinity, minHeight: 180).clipped()`, styled identically to the `localImage` branch (same frame, clipped, `.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))`).
  - Add a `price` text field below the `itemLink` text field: `TextField("Price (optional)", text: Binding(get: { item.price ?? "" }, set: { item.price = $0.isEmpty ? nil : $0 }))` styled with `.wishies(.regular, 15)`, `.lightYellow` background `RoundedRectangle(cornerRadius: 10)`, `.focused($focusedField, equals: .price)`.
  - Add `.price` to `CreateWishlistItemField` enum.
  - Import `SDWebImageSwiftUI` is not needed here — `WishieWebImage` encapsulates the dependency.

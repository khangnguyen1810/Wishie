# Task 5: Add FAB Button and Sheet Wiring to WishlistDetailScreen

- [ ] 5.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE:
  - In the `ZStack(alignment: .bottom)` body, add after the `StickyHeaderView(...)` block and after the `if viewModel.wishlistInfo.isUserJoined() == false` block, a new conditional:
    ```swift
    if viewModel.wishlistInfo.isOwner() {
        Button {
            viewModel.showAddItemOptionSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 50, height: 50)
                .background(Color(hex: viewModel.wishlistInfo.theme.secondary))
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .padding(.bottom, 24)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    ```
  - Add `.sheet(isPresented: $viewModel.showAddItemOptionSheet)` modifier (after existing `.sheet` modifiers) presenting `AddItemOptionSheet` with `.presentationDetents([.height(280)])`:
    - `onPasteLink`: dismiss option sheet (`viewModel.showAddItemOptionSheet = false`), then after `0.3s` delay set `viewModel.showAddItemPasteLinkSheet = true`.
    - `onManual`: dismiss option sheet (`viewModel.showAddItemOptionSheet = false`), then after `0.3s` delay set `viewModel.showAddItemManualSheet = true`.
  - Add `.sheet(isPresented: $viewModel.showAddItemManualSheet)` presenting `AddItemManualDetailSheet(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "")` with `.presentationDetents([.large])`.
  - Add `.sheet(isPresented: $viewModel.showAddItemPasteLinkSheet)` presenting `AddItemPasteLinkDetailSheet(viewModel: viewModel, wishlistId: wishlist?.id ?? wishlistId ?? "")` with `.presentationDetents([.large])`.
  - On dismiss of `showAddItemManualSheet` and `showAddItemPasteLinkSheet`, reset transient state by setting `viewModel.newItemName = ""`, `viewModel.newItemDescription = ""`, `viewModel.newItemImage = nil`, `viewModel.newItemLink = ""`, `viewModel.newItemRemoteImageUrl = nil`, `viewModel.metadataFetchError = nil`. Use the `onDismiss:` parameter of `.sheet(isPresented:onDismiss:content:)` for this.

# Task 5: Migrate `listContent()` to a native SwiftUI `List` with swipe-to-delete and star badge

- [ ] 5.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `listContent()` `@ViewBuilder` method:
  - Replace the outer `VStack()` container with `List` and apply `.listStyle(.plain)` and `.scrollContentBackground(.hidden)` modifiers on the `List`.
  - Remove the `.padding(.horizontal, 15)` and `.padding(.top, 15)` from the outer call-site `VStack` that wraps `headerContent()` and `listContent()`, because `List` manages its own insets; instead apply `.listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))` and `.listRowBackground(Color.clear)` on each row.
  - Keep the existing `HStack` row content (thumbnail `WebImage`, item name `Text`, picked user icon) unchanged.
  - Add a star badge to the item row: inside the `HStack`, after the item name `Text` and before the picked-user icon section, add `if item.isMostDesired { Image(systemName: "star.fill").foregroundStyle(.yellow).frame(width: 16, height: 16) }`.
  - Attach `.swipeActions(edge: .trailing, allowsFullSwipe: false)` to each row; inside, add a single `Button(role: .destructive)` labelled with `Label("Delete", systemImage: "trash")` that executes `viewModel.itemSelected = item` then `viewModel.showDeleteConfirmation = true`. Render this action only when `viewModel.wishlistInfo.isOwner() == true && !item.isPicked`.

---


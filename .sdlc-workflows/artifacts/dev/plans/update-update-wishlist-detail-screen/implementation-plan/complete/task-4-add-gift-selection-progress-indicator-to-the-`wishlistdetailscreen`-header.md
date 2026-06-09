# Task 4: Add gift-selection progress indicator to the `WishlistDetailScreen` header

- [ ] 4.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `headerContent()` `@ViewBuilder` method:
  - Compute `let pickedCount = viewModel.wishlistInfo.items.filter(\.isPicked).count` and `let totalCount = viewModel.wishlistInfo.items.count` at the top of the method body.
  - Compute `let progress = totalCount > 0 ? Double(pickedCount) / Double(totalCount) : 0.0`.
  - Inside the outer `VStack`, after the existing `HStack` (item count + date row) and before the description `Text`, insert a new `HStack` containing:
    - `GiftProgressView(progress: progress)` sized to `.frame(width: 32, height: 32)`.
    - A `Text("\(pickedCount) / \(totalCount) gifts selected")` styled with `.font(.wishies(.regular, 14))` and `.foregroundStyle(.darkGrey)`.
    - `Spacer()` to push the indicator to the leading edge.

---


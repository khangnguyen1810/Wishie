# Task 6: Update owner's bottom sheet with "Mark as Most Desired" and "Delete" CTAs

- [ ] 6.1: In `Wishie/Screens/Detail/WishlistDetailScreen.swift` UPDATE — `bottomSheet()` `@ViewBuilder` method, inside the `if wishlist?.isOwner() == true` branch, within the `VStack` that currently holds the Edit/Save button and Cancel button:
  - After the Edit/Save `ZStack` button (and its conditional Cancel button), add a "Mark as Most Desired" button using the same `ZStack`/`RoundedRectangle` pattern as the existing buttons:
    - Background: `Color(hex: viewModel.wishlistInfo.theme.secondary)`, height `45`, corner radius `15`.
    - Leading icon: `Image(systemName: "star.fill")` sized to `25` wide with `.padding(.leading, 20)`.
    - Center label: `Text("Mark as Most Desired")` styled `.font(.wishies(.bold, 15))` and `.foregroundStyle(.black)`.
    - Visibility: only shown when `!viewModel.itemSelected.isMostDesired && !isEditing`.
    - `onTapGesture`: calls `Task { await viewModel.setMostDesired(wishlistId: wishlist?.id ?? "") }` then dismisses the sheet by setting `viewModel.showBottomSheet = false`.
  - After the "Mark as Most Desired" button, add a "Delete" button:
    - Background: `.wishiePink` when `!viewModel.itemSelected.isPicked`, else `.lightGrey`.
    - Leading icon: `Image(systemName: "trash")` sized to `25` wide with `.padding(.leading, 20)`.
    - Center label: `Text("Delete")` styled `.font(.wishies(.bold, 15))` and `.foregroundStyle(.black)`.
    - Visibility: only shown when `!isEditing`.
    - Interaction: disabled (`.disabled(viewModel.itemSelected.isPicked)`) when the item is already picked.
    - `onTapGesture`: sets `viewModel.showDeleteConfirmation = true` when `!viewModel.itemSelected.isPicked`.

---


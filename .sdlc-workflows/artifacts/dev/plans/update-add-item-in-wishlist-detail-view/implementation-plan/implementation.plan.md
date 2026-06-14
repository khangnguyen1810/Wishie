Add New Wish Item Functionality in WishlistDetailScreen

# Requirement Context

## Current State

`WishlistDetailScreen` displays wishlist items in a scrollable list. Each item supports tap-to-view, with a bottom sheet (`bottomSheet()`) that provides owners with edit, delete, and most-desired actions. No mechanism exists for adding new items to an existing wishlist from the detail screen. The `WishlistService` and `WishlistServiceProtocol` do not yet expose an `addWishlistItem` method. The `WishlistDetailViewController` owns all business logic and published state for the screen.

## Goals

1. Allow the wishlist owner to add new wish items directly from `WishlistDetailScreen`.
2. Support two entry modes: manual form entry and URL-based product metadata auto-fill (paste link).
3. Integrate with the existing `WishlistService` for persistence and `WishlistDetailViewController` for state management.
4. Reuse the existing `AddItemOptionSheet` component for entry mode selection.
5. Keep UI patterns consistent with existing screens (`CreateWishlistPage2`, `PasteLinkSheet`, `bottomSheet`).

## Risk & Mitigation

- **Sheet stacking on iOS**: iOS does not support presenting a sheet from within another sheet on the same view level. Mitigation: dismiss the option sheet before presenting the manual or paste-link sheet, using a slight delay (`DispatchQueue.main.asyncAfter`) consistent with the existing `showDeleteConfirmation` / `showReserveConfirmation` pattern in the screen.
- **Image upload failure**: If Supabase upload fails, the item should not be added to Firestore. Mitigation: upload image first, then call `addWishlistItem` only on success.

# Technical Specification Context

## Functional Requirements:

- System MUST show an "Add item" floating action button only when `viewModel.wishlistInfo.isOwner()` returns `true`.
- System MUST present `AddItemOptionSheet` when the add button is tapped, offering "Paste a product link" and "Fill in manually" options.
- System MUST present `AddItemManualDetailSheet` when the manual option is selected, with fields for item name (required), description, image (optional via `ImagePickerBox`), and product link (optional).
- System MUST present `AddItemPasteLinkDetailSheet` when the paste link option is selected, with URL input, a fetch action via `ProductMetadataService`, a metadata preview, and an "Add to wishlist" confirm action.
- System MUST validate that item name is non-empty before enabling the "Add" button in `AddItemManualDetailSheet`.
- System MUST upload the selected image to Supabase storage via `WishlistService.upload(image:fileName:)` before persisting the item.
- System MUST add the new item to Firestore by calling `WishlistService.addWishlistItem(wishlistId:item:)`.
- System MUST reset all new-item state (`newItemName`, `newItemDescription`, `newItemImage`, `newItemLink`, `metadataFetchError`) after a successful add.
- System MUST surface errors via `isShowError` and `errorMessage` in `WishlistDetailViewController`.

## Non-Functional Requirements:

- System MUST follow the existing MVVM pattern: all business logic and async operations are placed in `WishlistDetailViewController`; views handle layout and user interaction only.
- System MUST reuse `AddItemOptionSheet` from `Wishie/Screens/CreateList/` without modification.
- System MUST use `ImagePickerBox` from `Wishie/CustomView/` for image selection in `AddItemManualDetailSheet`.
- System MUST use `WishieButton` from `Wishie/CustomView/` for primary action buttons in both new sheets.
- System MUST use `.wishies` font modifiers and asset colors (`lightYellow`, `wishiePink`, theme colors) consistent with the existing design system.

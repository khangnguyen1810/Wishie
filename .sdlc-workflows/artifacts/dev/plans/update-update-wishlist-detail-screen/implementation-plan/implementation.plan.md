Enhance WishlistDetail with Progress Tracking and Interactive Features

# Requirement Context

## Current State

`WishlistDetailScreen` displays a list of wishlist items with a sticky header, a bottom sheet for item interaction, and role-based UI (owner vs. member). The `WishlistDetailViewController` manages state via `@Published` properties. The `WishlistService` handles backend Firestore operations. `WishlistItem` has `isPicked` and `pickedUserId` but no "most desired" concept. `WishlistModel.getItemsRemaining()` exists but the progress view (`GiftProgressView`) is not wired into the detail screen. The bottom sheet currently shows an Edit CTA for owners and a Reserve button for members, with no confirmation dialog before reservation.

## Goals

- Add a visible gift-selection progress indicator to the WishlistDetail header so all roles can track how many gifts have been reserved.
- Allow the wishlist owner to mark one item as "most desired," surfacing it with a star badge on the item row.
- Allow the wishlist owner to delete individual wishlist items from the bottom sheet and via swipe-to-delete.
- Require members to confirm their gift selection via a confirmation dialog before the reservation is committed to the backend.

## Risk & Mitigation

- **`isMostDesired` data migration**: existing Firestore documents lack this field. Mitigation: default to `false` in the `WishlistItem` initializer and dictionary parser so existing items remain valid.
- **Swipe-to-delete conflict with scroll**: SwiftUI `List` swipe actions require wrapping items in a `List`; current layout uses a custom `ForEach` inside a `VStack`. Mitigation: either migrate the item list to a native `SwiftUI.List` with `.swipeActions`, or implement a custom swipe gesture — clarification needed on approach preference.
- **Multiple "most desired" items**: each toggle is independent so no atomic cross-item update is needed; the service only writes the single targeted item's `isMostDesired` flag.

# Technical Specification Context

## Functional Requirements:

- System MUST display a horizontal progress bar with a text label (e.g., "3 / 7 gifts selected") in the WishlistDetail header; the bar fill is calculated from `pickedCount / totalCount`.
- System MUST add an `isMostDesired: Bool` field to the `WishlistItem` model (default `false`) and persist it to Firestore.
- System MUST show a "Mark as Most Desired" CTA button in the owner's bottom sheet when the selected item is not yet marked as most desired.
- System MUST show a star (or equivalent indicator) badge on the item row in the list when `isMostDesired` is `true`.
- System MUST allow any number of items to be independently marked as "most desired"; toggling one item does not affect others.
- System MUST show a "Delete" button in the owner's bottom sheet for the selected item; the button is hidden/disabled when the item is already picked.
- System MUST support swipe-to-delete on item rows for the owner role using native SwiftUI `List` `.swipeActions`; the `listContent()` `ForEach`-in-`VStack` layout is migrated to a `List`.
- System MUST show a confirmation dialog before committing a delete, using the existing `showDialogIfNeeded` pattern.
- System MUST show a confirmation dialog to members before reserving a gift ("Do you want to select this gift?" with OK/Cancel actions).
- System MUST only call the `pickItem` backend service after a member confirms with "OK."
- System MUST close the confirmation dialog without any side effects when a member taps "Cancel."
- System MUST add a `deleteWishlistItem(wishlistId:itemId:)` method to `WishlistServiceProtocol` and `WishlistService`.
- System MUST add a `setMostDesired(wishlistId:itemId:)` method to `WishlistServiceProtocol` and `WishlistService`.

## Non-Functional Requirements:

- System MUST update the item list and progress indicator optimistically or via a backend refresh after each state-changing action (delete, mark most desired, reserve).
- System MUST not allow a member to tap "Reserve" on an already-picked item (current `isPicked` guard must remain).
- System MUST follow existing MVVM patterns: new logic lives in `WishlistDetailViewController`; views remain declarative and stateless.
- System MUST not introduce any `print` statements, TODO comments, or debug code.

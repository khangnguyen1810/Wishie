# Home card actions: long-press menu, edit info, archive

Date: 2026-07-13
Status: Draft for review

## Motivation

Home's wishlist cards currently use a custom swipe-to-delete gesture
(`SwipeToDeleteModifier`), added to work around `List`'s row-clipping
behavior when `HomeView` was moved to `ScrollView`/`LazyVStack`. The
user wants to drop the swipe gesture entirely in favor of a long-press
context menu, and wants that menu to expose more than just delete:
**Delete**, **Change info**, and **Archive** for wishlists they own,
and **Leave** for wishlists they've joined as a member.

Two of these three actions ("Change info", "Archive") don't exist
anywhere in the app yet and need new screens/data.

## Scope

**In scope:**
- Replace swipe-to-delete with `.contextMenu` (long-press) on both
  "My list" and "Friend's list" cards.
- Add an `isArchived` flag to `WishlistModel`, with Firestore
  read/write support.
- Archived wishlists are excluded from "My list" and "Friend's list".
- A new "Archived wishlists" screen, reachable from the Profile
  screen, listing the current user's archived wishlists with their
  own long-press menu (**Unarchive**, **Delete**).
- A new single-page "Edit wishlist info" screen for name, description,
  due date, and theme (not items/members), reachable via "Change info".

**Out of scope:**
- Editing wishlist items (gifts) — already handled inside
  `WishlistDetailScreen`.
- Archiving/unarchiving by non-owners (members only ever see "Leave").
- Any confirmation dialog for Archive/Unarchive (both are reversible;
  only Delete keeps its existing confirmation dialog).
- Changing `WishListInformationView` (the read-only join-flow screen)
  — left untouched, unrelated to this feature.

## Data model

`WishlistModel` (`Wishie/Models/WishlistModel.swift`) gains one field:

```swift
var isArchived: Bool = false
```

- Memberwise `init` gets `isArchived: Bool = false` (default, so all
  existing call sites — previews, tutorial example, tests — keep
  compiling unchanged).
- `init(dictionary:)` reads `dictionary["isArchived"] as? Bool ?? false`
  (missing field on existing documents defaults to not-archived).

Firestore field name: `isArchived` (matches the Swift property name;
existing fields in this codebase are a mix of camelCase Swift-matching
names — `dueDate` — and renamed ones — `wishListName` for `name` — so
using the same name here is consistent and avoids a needless mapping).

## Service layer

`WishlistServiceProtocol` (`Wishie/Services/WishlistService.swift`)
gains two methods, following the existing `Result<Bool, Error>` /
do-catch pattern used by `deleteWishlist`/`leaveWishlist`:

```swift
func updateWishlistInfo(
    wishlistId: String,
    name: String,
    description: String,
    dueDate: Date,
    themeColor: String?
) async throws -> Result<Bool, Error>

func setArchived(
    wishlistId: String,
    isArchived: Bool
) async throws -> Result<Bool, Error>
```

Both are implemented as a single `updateData(_:)` call on the
`wishList/{id}` document (no batch needed — neither touches `members`
or per-user subcollections), matching the shape of `setMostDesired`.

## HomeViewModel changes

`HomeViewModel` currently derives `myWishlists`/`myFriendWishlists`
directly from the Firestore fetch in `getListWishlist()` and
`refreshWishlists()`. Both derivations get an added `!$0.0.isArchived`
filter:

```swift
self.myWishlists = list.filter { $0.0.members[userId] == .owner && !$0.0.isArchived }
self.myFriendWishlists = list.filter { $0.0.members[userId] == .member && !$0.0.isArchived }
```

Two new methods, mirroring `deleteWishlist`/`leaveWishlist` exactly
(call service, on success re-run `getListWishlist()`, on failure set
`errorMessage`):

```swift
func archiveWishlist(wishlistId: String) async
func unarchiveWishlist(wishlistId: String) async
```

No new `@Published` array on `HomeViewModel` for archived wishlists —
see "Archived wishlists screen" below for why that screen uses its own
view model instead.

## UI: context menu

Both `ForEach` blocks in `HomeView.swift` drop `.swipeToDelete(...)`
and add `.contextMenu`:

```swift
// My list
.contextMenu {
    Button {
        path.append(Route.editWishlistInfo(wishlistId: wishlist.0.id))
    } label: {
        Label("Change info", systemImage: "pencil")
    }
    Button {
        Task { await homeViewModel.archiveWishlist(wishlistId: wishlist.0.id) }
    } label: {
        Label("Archive", systemImage: "archivebox")
    }
    Button(role: .destructive) {
        selectedWishlist = wishlist
        showDeleteConfirm = true
    } label: {
        Label("Delete", systemImage: "trash")
    }
}

// Friend's list
.contextMenu {
    Button(role: .destructive) {
        selectedWishlist = wishlist
        showLeaveConfirm = true
    } label: {
        Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
    }
}
```

`SwipeToDeleteModifier.swift` and `SwipeRevealStateTests.swift` are
deleted (no replacement needed — `.contextMenu` is a first-party
modifier with no custom gesture code to test).

Because `.contextMenu` is a standard SwiftUI modifier designed to
coexist with tap/Button targets underneath it (unlike the custom
`DragGesture` we removed), it's expected to compose cleanly with the
existing `NavigationLink(label:)` + `.buttonStyle(.plain)` tap-to-open
behavior — but per the last two rounds on this screen, this gets
verified with a real simulated interaction before considering it done,
not just by reading the code.

## New screen: Edit wishlist info

**Route:** add `case editWishlistInfo(wishlistId: String)` to
`Route.swift`, handled in `HomeView`'s `.navigationDestination(for:)`.

**Files:**
- `Wishie/Screens/EditWishlistInfo/EditWishlistInfoScreen.swift`
- `Wishie/Screens/EditWishlistInfo/EditWishlistInfoViewModel.swift`

**ViewModel:** loads the wishlist by id (reuses
`WishlistServiceProtocol.getWishlist(by:)`, same call
`WishListInformationViewModel` already makes), publishes editable
`name`/`description`/`dueDate`/`selectedTheme`, and a `save()` method
calling `updateWishlistInfo`.

**Screen layout** (single page, no wizard steps — reuses existing
components rather than introducing new ones):
- `TextField` for name — same style as `CreateWishlistPage1`'s name
  field (`lightYellow` rounded background).
- `TextField(..., axis: .vertical)` for description — same style/200
  char cap as `CreateWishlistPage1`.
- `DateInputView` for due date — same component `CreateWishlistPage1`
  uses.
- Theme grid — same `GradientTheme.allCases` `LazyVGrid` as
  `CreateWishlistPage3`. Extracted into a small shared
  `ThemeColorPicker(selectedTheme: Binding<GradientTheme?>)` view (used
  by both `CreateWishlistPage3` and this screen) rather than
  duplicated, since it's ~20 lines of identical grid/selection logic.
- A `WishieButton("Save changes")` at the bottom, disabled while
  `name` is empty (matching the existing "Next step"/"Create" button's
  disabled rule in `CreateWishListScreen`), calling `viewModel.save()`
  then `dismiss()`.

Because `HomeViewModel` already listens for changes on every wishlist
document it's showing (`setWishlistListeners` →
`observeWishlist(by:onChange:)` → `refreshWishlists()`), a saved edit
propagates to Home automatically — no extra plumbing required there.

## New screen: Archived wishlists

**Reachable from:** a new row/button in the existing Profile screen
("Archived wishlists").

**Files:**
- `Wishie/Screens/Archived/ArchivedWishlistsView.swift`
- `Wishie/Screens/Archived/ArchivedWishlistsViewModel.swift`

This is a separate, small view model (not a shared/injected
`HomeViewModel`) that fetches the user's wishlists the same way
`HomeViewModel` does (`service.getUserWishlists()`, filtered to
`members[userId] == .owner && isArchived == true`) and exposes
`archiveWishlists: [(WishlistModel, UserModel)]`, plus
`unarchiveWishlist(wishlistId:)` / `deleteWishlist(wishlistId:)`
(delegating to the same `WishlistServiceProtocol` methods). Keeping
this as its own small view model — rather than adding an
`archivedWishlists` array to `HomeViewModel` and sharing an instance
across screens — keeps `HomeViewModel` scoped to "what Home shows" and
avoids a cross-screen shared-state dependency for a screen that's
opened rarely and doesn't need to stay in sync live with Home.

**Layout:** reuses `HomeItemViewCell` for cards (same visual language),
in a `ScrollView`/`LazyVStack` (no `NavigationLink` — tapping an
archived card does nothing; only the context menu actions apply,
since you can't act on gifts inside an archived wishlist without
unarchiving it first). Each card's `.contextMenu`:

```swift
Button {
    Task { await viewModel.unarchiveWishlist(wishlistId: wishlist.0.id) }
} label: {
    Label("Unarchive", systemImage: "arrow.uturn.backward")
}
Button(role: .destructive) {
    selectedWishlist = wishlist
    showDeleteConfirm = true
} label: {
    Label("Delete", systemImage: "trash")
}
```

Empty state: reuses the same `contentUnavailable`-style pattern already
in `HomeView` ("No archived wishlists yet").

## Testing

- Unit test `WishlistModel(dictionary:)` defaulting `isArchived` to
  `false` when the field is absent (existing-document backward
  compatibility) and `true`/`false` when present.
- No unit tests for `.contextMenu` itself (it's a first-party
  modifier, nothing custom to assert on) — verified interactively
  instead (see below).
- Manual/simulated verification pass, same technique used for the
  last two Home fixes in this session (installing the build on the
  already-authenticated simulator and driving it with real
  synthetic input, not just static rendering):
  - Long-press a "My list" card → menu shows Delete/Change info/Archive;
    each item navigates/executes correctly.
  - Long-press a "Friend's list" card → menu shows only Leave.
  - Tap-to-navigate still works alongside the new context menu (this
    is exactly the kind of interaction that broke silently twice
    already on this screen).
  - Archive a wishlist → disappears from My list, appears in Archived
    wishlists (Profile).
  - Edit a wishlist's info → Home reflects the change without a
    manual refresh.
  - Unarchive → reappears in My list, disappears from Archived.

## Open questions / risks

- None outstanding — all scope decisions were confirmed during
  brainstorming (edit screen shape, archive semantics, archived
  screen placement, per-tab menu contents).

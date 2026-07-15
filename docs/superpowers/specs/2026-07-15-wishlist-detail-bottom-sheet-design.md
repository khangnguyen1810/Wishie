# Wishlist detail: item bottom sheet redesign

Date: 2026-07-15
Status: Draft for review

## Motivation

The item bottom sheet in `WishlistDetailScreen` (shown when tapping the
"Most Desired" card or any grid item) still uses the app's earlier
stacked-pill button style and a theme-tinted background. A new design
was produced in the Claude Design project ("Home Screen Redesign",
frame "5b · Item Bottom Sheet") based on a reference screenshot the
user collected (an invoice app's item sheet: white card, drag handle +
close button, circular icon action row with labels, full-width pill
CTA). The user also supplied a custom sparkle/star icon
(`star_icon.pdf`) to replace the current text-only "Most Desired"
toggle with an icon.

This spec covers only `WishlistDetailScreen.swift`'s `bottomSheet()`
and its button builders — no other screen, view model method, or
confirmation dialog changes.

## Scope

**In scope:**
- Restyle `bottomSheet()`: plain white background (rounded top
  corners), custom drag handle, circular close (X) button, dynamic
  sheet height (replacing the fixed `.fraction(0.4)` detent).
- Restyle the item content row (image/name/price) and add a "Picked by
  you" / "Picked" status pill using the existing `pickedUserId` field.
- Replace the stacked text-pill buttons with a row of circular icon
  buttons (Most Desired / Edit / Link for the owner view; Link only
  for the non-owner view), each with a label underneath.
- Convert the owner's "Delete" and non-owner's "Reserve" actions into a
  full-width pill CTA at the bottom of the sheet (visual restyle only,
  same disabled-when-picked behavior as today).
- Import `star_icon.pdf` into `Assets.xcassets` as a template-rendered
  image asset (`most_desired_icon`), used only for the Most Desired
  button.

**Out of scope:**
- Any change to `WishlistDetailViewController` methods
  (`setDesired`, `pickItem`, `openProductLink`, `wouldReplaceMostDesired`,
  confirmation-dialog wiring) — all called exactly as today, just from
  new button views.
- The grid cards, header card, sticky header, FAB, or any other sheet
  in this screen (`AddItemOptionSheet`, `WishItemDetailView`,
  `AddItemPasteLinkDetailSheet`, share sheet).
- Resolving the *name* of another member who picked an item (design
  only needs "picked by you" vs. generic "picked"; no member-name
  lookup is added).
- Any change to `HomeView`'s unrelated `bottomSheet(type:)` /
  `bottomSheetOption` (a different, already-separate feature).

## Asset: Most Desired icon

`star_icon.pdf` (`/Users/nguyenkhanghuu/Downloads/star_icon.pdf`, a
single-color sparkle/outline star) is added to
`Wishie/Resources/Assets.xcassets` as `most_desired_icon.imageset`,
following the same pattern as the existing `edit_icon.imageset`
(`template-rendering-intent: template` in `Contents.json`, single
universal-scale entry pointing at the PDF, letting Xcode rasterize it
per scale) so it can be tinted with `.foregroundStyle` like any SF
Symbol.

## UI: sheet shell

`bottomSheet()` changes from a `ZStack` with a
`Color(...).lightened(by: 0.45)` background to:

- Outer container: `Color.white`, top corners rounded 26pt (a small
  `RoundedCorner` shape or `.clipShape(UnevenRoundedRectangle(topLeadingRadius: 26, topTrailingRadius: 26))`,
  matching how the design's card sits above the dimmed backdrop —
  SwiftUI's own `.sheet` presentation already provides the dimmed
  backdrop and rounded-corner card chrome, so this just controls the
  content's own background/corners inside that system chrome).
- Drag handle: `Capsule().fill(Color(hex: "#E9DCC0")).frame(width: 40, height: 5)`,
  top-center, replacing `.presentationDragIndicator(.visible)` (set to
  `.hidden` since the custom handle replaces it).
- Close button: 30×30 circle, `Color(hex: "#F7F1E3")` fill, an "xmark"
  SF Symbol, top-trailing, `onTapGesture { viewModel.showBottomSheet = false }`.
- Height: measured via a `GeometryReader` background modifier +
  `PreferenceKey` writing into the already-declared `@State private var
  sheetHeight: CGFloat` (currently declared but unused), then
  `.presentationDetents([.height(sheetHeight)])` instead of the fixed
  `.fraction(0.4)` — needed because the new content (description +
  divider + icon row + CTA) is taller and variable-height (long
  descriptions), and a fixed fraction would clip it.

## UI: item content row

- Image: 84×84, `cornerRadius: 18` (same `WebImage`/`selectedImage`
  local-preview logic as today, just resized from the current
  80×80/`cornerRadius: 10`).
- Name: `.wishies(.bold, 19)`, `foregroundStyle(.black)` (was 15pt).
- Price: `.wishies(.bold, 14)`, tinted with
  `Color(hex: viewModel.wishlistInfo.theme.secondary)` (replacing the
  plain `.darkGrey` price text), shown only when non-empty as today.
- New status pill, shown only when `viewModel.itemSelected.isPicked`:
  - `pickedUserId == UserDefaults.standard.string(forKey: WishieConstants.userIdKey)`
    → "🎁 Picked by you", teal-style pill (matches the design's example).
  - Otherwise → "🎁 Picked", using the wishlist's accent color instead
    of a hardcoded teal (so the pill's color varies by theme, same
    accent already used for the grid card's "Picked" badge).
- Description: unchanged content, restyled to `.wishies(.regular, 13.5)`,
  `Color(hex: "#5B4A32")`.
- Divider: `Rectangle().fill(Color(hex: "#EFE4C8")).frame(height: 1)`.

## UI: icon action row

New `iconActionButton(icon:label:isActive:action:)` builder: 48×48
circle (`isActive` ? gold gradient `#FFD66B → #F3B23A` : `Color(hex:
"#F7F1E3")`), icon centered (SF Symbol or the new asset,
`foregroundStyle` dark brown `#5B4A32`), `Text(label)` underneath
(`.wishies(.semibold, 11.5)`, `#5B4A32`), laid out in an `HStack`
with `Spacer()`s between (matching the mock's `space-around`).

- **Owner view** (`wishlist?.isOwner() == true`): Most Desired, Edit, Link.
  - Most Desired: `Image("most_desired_icon")`, `isActive:
    viewModel.itemSelected.isMostDesired`, label "Most Desired" (fixed
    text regardless of state — the gold/neutral circle communicates
    the toggle state instead of the old "Mark as" / "Remove" text
    swap). Tap logic unchanged: if `wouldReplaceMostDesired`, close
    sheet then show the replace-confirmation dialog after 0.3s;
    otherwise `Task { await viewModel.setDesired(...) }` then close.
  - Edit: SF Symbol `pencil`, always neutral, label "Edit". Tap logic
    unchanged (populate `newItem*` fields, close sheet, open edit
    sheet after 0.3s).
  - Link: SF Symbol `link`, always neutral, label "Link". Tap calls
    `viewModel.openProductLink()` unchanged.
- **Non-owner view:** Link only, same icon/behavior, centered alone in
  the row (no forced 3-slot layout).

## UI: bottom CTA

Replaces the stacked `bottomSheetButton` pill(s) at the very bottom
with one full-width capsule:

- **Owner — Delete:** `Capsule().fill(Color(hex: "#FFECEF"))`, "trash"
  SF Symbol + "Delete item" in `Color(hex: "#D9375A")`, switching to
  `.lightGrey` fill / disabled when `viewModel.itemSelected.isPicked`
  — same guard as today's `deleteButton()`.
- **Non-owner — Reserve:** `Capsule().fill(.wishiePink)` (falls back to
  `.lightGrey` when already picked, same as today's `reserveButton()`),
  "Reserve" label, same tap logic (guarded by `!isPicked`, closes sheet
  then shows the reserve-confirmation dialog after 0.3s).

`bottomSheetButton(title:fill:action:)` is removed once nothing calls
it (replaced by the capsule CTA + icon action buttons above);
`editButton()`/`markDesireButton()`/`linkButton()`/`reserveButton()`/
`deleteButton()` are replaced by the new builders described above.

## Testing

- No new unit-testable logic is introduced (the status pill and
  active/inactive icon state are pure derivations of existing
  `WishlistItem` fields already covered by `WishlistItem`/view-model
  behavior; no new service or view-model methods are added).
- Manual/simulated verification pass on the simulator (per this
  project's established practice for UI-only changes):
  - Owner view, unpicked item: icon row shows Most Desired (neutral) /
    Edit / Link; Delete pill enabled.
  - Owner view, picked item: Delete pill disabled/grey; status pill
    shows "Picked by you" or "Picked" correctly depending on
    `pickedUserId`.
  - Toggle Most Desired on/off, including the replace-confirmation
    path when another item is already most-desired.
  - Non-owner view: single Link icon button, Reserve pill
    enabled/disabled matching `isPicked`.
  - Close (X) button and swipe-down both dismiss the sheet.
  - Long description text doesn't get clipped (dynamic height).

## Open questions / risks

- None outstanding — background style, non-owner layout, and
  close/drag-handle affordance were all confirmed during brainstorming.

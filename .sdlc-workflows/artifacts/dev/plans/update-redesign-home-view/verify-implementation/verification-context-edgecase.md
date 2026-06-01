# Verification Context — Edge Case Scenarios

## Purpose

Define testable edge case scenarios in Given/When/Then format to verify the implementation handles boundary conditions, error states, and non-functional requirements.
This document serves as the single source of truth for edge case verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "cart-ec1-empty", "user-ec2-locked"). No two scenarios should share mutable state.

## Edge Case Scenarios:

### EC 1: Gradient Theme Fallback — Invalid themeColor String

- [ ] **Scenario: Wishlist with unrecognized themeColor renders sunset fallback gradient**
  - Given: A `WishlistModel` ('wishlist-ec1-invalid-theme') has `themeColor` set to the unrecognized string `"rainbow"` which does not match any `GradientTheme` raw value
  - When: `HomeItemViewCell` renders this wishlist's card background using `item.0.theme`
  - Then: The card background displays the `.sunset` fallback gradient (primary `#FEF3D7` → secondary `#F1D790`) with no crash or transparent fill
  - Verify: Confirm `GradientTheme(rawValue: "rainbow") ?? .sunset` resolves to `.sunset`; the card visually shows the warm yellow gradient

### EC 2: Gradient Theme Fallback — nil themeColor

- [ ] **Scenario: Wishlist with nil themeColor renders sunset fallback gradient**
  - Given: A `WishlistModel` ('wishlist-ec2-nil-theme') has `themeColor = nil`
  - When: `HomeItemViewCell` renders the card background
  - Then: `item.0.theme` resolves to `.sunset` via the `?? "sunset"` fallback in `WishlistModel.theme`; the card renders the sunset gradient without any transparent or missing fill
  - Verify: Card background shows a non-empty gradient; no blank/white card appears in the list

### EC 3: Gift Progress — Zero Items (Empty Wishlist)

- [ ] **Scenario: Wishlist card renders zero progress without division-by-zero when items array is empty**
  - Given: A `WishlistModel` ('wishlist-ec3-no-items') has `items = []` (count = 0)
  - When: `HomeItemViewCell` calculates progress as `items.count > 0 ? Double(itemPicked.count) / Double(items.count) : 0.0`
  - Then: `GiftProgressView` renders at 0% progress; the gift count label displays "0 gifts" with no crash or NaN/infinity value
  - Verify: No division-by-zero runtime error occurs; `GiftProgressView(progress: 0.0)` renders an empty ring; the label uses the `else` branch showing "0 gifts"

### EC 4: Gift Progress — All Items Picked (100% Boundary)

- [ ] **Scenario: Wishlist card renders full progress when all items are picked**
  - Given: A `WishlistModel` ('wishlist-ec4-all-picked') has 5 `WishlistItem` entries, each with `isPicked = true`
  - When: `HomeItemViewCell` renders the card
  - Then: Progress evaluates to `5/5 = 1.0`; `GiftProgressView` renders at 100% fill; the gift count label displays "5/5 gifts"
  - Verify: `GiftProgressView` visually completes its ring/arc; no overflow or label truncation occurs at the boundary value

### EC 5: Long Wishlist Name — Layout Overflow

- [ ] **Scenario: Wishlist card truncates an excessively long name without breaking the owner row**
  - Given: A `WishlistModel` ('wishlist-ec5-long-name') has `name` set to an 80-character string (e.g., `"Birthday Celebration For My Dearest Friend Who Loves Collecting Rare Vintage Items"`)
  - When: `HomeItemViewCell` renders the `HStack` containing the name `Text` and the owner row
  - Then: The name text truncates with `.tail` truncation; the owner name and avatar circle remain fully visible and do not get pushed off-screen; the card maintains its standard height
  - Verify: The name `Text` does not overlap the owner `HStack`; the card horizontal padding is preserved

### EC 6: Long Description Text — Line Clamping

- [ ] **Scenario: Wishlist card clamps a description exceeding 2 lines without breaking card height**
  - Given: A `WishlistModel` ('wishlist-ec6-long-desc') has `description` set to a 5-line paragraph (~200 characters)
  - When: `HomeItemViewCell` renders the description `Text` with `lineLimit(2)`
  - Then: The description is clamped to exactly 2 lines with trailing truncation; the `GiftProgressView` circular element alongside it remains vertically aligned to `.top`; the overall card height is consistent with other cards
  - Verify: No text overflow beyond the 2-line boundary; the `HStack(alignment: .top)` keeps the progress ring anchored to the top of the description area

---

### Task 6 — App Store-Style Zoom Transition Edge Cases

### EC-T6-1: Duplicate Wishlist ID — Namespace Collision in Same Tab

- [ ] **Scenario: Two wishlists sharing the same ID in myList tab cause ambiguous zoom source geometry**
  - Given: `homeViewModel.myWishlists` contains two entries ('wishlist-t6ec1-dup-a', 'wishlist-t6ec1-dup-b') whose `WishlistModel.id` are both `"dup-id-001"`
  - When: The `myList` `ForEach` renders both cards and applies `.matchedTransitionSource(id: "dup-id-001", in: animation)` to each outer `ZStack`
  - Then: SwiftUI registers two sources with the same namespace key; tapping either card produces undefined zoom origin — the transition may animate from the wrong card bounds or produce a broken/snapping animation
  - Verify: Confirm data layer guarantees UUID uniqueness for `WishlistModel.id`; no two entries in the rendered list share the same `id` string; if this invariant is violated the transition degrades gracefully without a crash

### EC-T6-2: Rapid Successive Taps Before Transition Completes

- [ ] **Scenario: Double-tapping a wishlist card before the zoom animation finishes does not push duplicate detail screens**
  - Given: `homeViewModel.myWishlists` contains at least one entry ('wishlist-t6ec2-double-tap') and the zoom transition animation duration is approximately 0.35 s
  - When: The user taps the card twice in rapid succession (< 200 ms apart) before `WishlistDetailScreen` has finished appearing
  - Then: Only one `WishlistDetailScreen` instance is pushed onto the `NavigationStack`; the `NavigationPath` does not contain two identical destinations; the second tap is ignored or de-bounced by SwiftUI's navigation lock
  - Verify: After the transition completes, pressing back returns to `HomeView` in a single pop; the navigation stack depth is exactly 1 above home

### EC-T6-3: Tab Switch During In-Flight Zoom Transition

- [ ] **Scenario: Switching tabs while the zoom transition is animating does not orphan the source card geometry**
  - Given: Both `myList` and `friendsList` tabs are populated; the user is viewing the `myList` tab
  - When: The user taps a 'wishlist-t6ec3-tab-switch' card (initiating the zoom-in animation) and simultaneously or immediately after taps the `friendsList` tab pill before `WishlistDetailScreen` finishes appearing
  - Then: The zoom animation completes without visual tearing; `WishlistDetailScreen` appears fully; on dismissal the zoom-out reverse animation resolves without crashing even if the source card is no longer in the active tab's list
  - Verify: No `matchedGeometryEffect` assertion failure or purple runtime warning is emitted; the app remains interactive after the transition sequence completes

### EC-T6-4: `.matchedTransitionSource` Absent from `friendsList` Loop (Regression)

- [ ] **Scenario: Zoom transition is missing from the friendsList ForEach loop causing a plain push transition instead of zoom**
  - Given: Only the `myList` `ForEach` has `.matchedTransitionSource(id: wishlist.0.id, in: animation)` applied; the `friendsList` `ForEach` is missing the modifier
  - When: The user selects the `friendsList` tab and taps any entry ('wishlist-t6ec4-friends-no-zoom')
  - Then: `WishlistDetailScreen` opens with a standard slide push transition instead of the App Store zoom; no crash occurs but the visual spec is violated
  - Verify: Inspect `HomeView.swift` to confirm `.matchedTransitionSource(id: wishlist.0.id, in: animation)` is present on the outer `ZStack` in BOTH `myList` and `friendsList` `ForEach` closures; run the friends-list tap and confirm the zoom animation plays

### EC-T6-5: Zoom Reverse Animation — Source Card Still Present on Dismissal

- [ ] **Scenario: Dismissing WishlistDetailScreen zooms back into the correct source card without layout jump**
  - Given: `homeViewModel.myWishlists` contains 'wishlist-t6ec5-back-nav' at list position 2; the user has tapped it, triggering the zoom-in transition
  - When: `WishlistDetailScreen` is presented and the user performs the interactive back gesture (swipe-from-left-edge or back button)
  - Then: The zoom-out reverse animation correctly targets the card at its original position in the `List`; the card does not appear to snap from a different position; the `HomeView` list scroll offset is preserved so the source card is visible upon return
  - Verify: The `@Namespace private var animation` namespace is the same instance used for both `.matchedTransitionSource` (source) and `.navigationTransition(.zoom(sourceID:in:))` (destination); list scroll position is unchanged after back navigation

### EC-T6-6: `.matchedTransitionSource` Applied to Wrong View (HomeItemViewCell Instead of Outer ZStack)

- [ ] **Scenario: Applying matchedTransitionSource to HomeItemViewCell directly produces incorrect zoom bounds**
  - Given: A hypothetical misconfiguration where `.matchedTransitionSource(id: wishlist.0.id, in: animation)` is placed on `HomeItemViewCell` instead of the enclosing outer `ZStack`
  - When: The user taps 'wishlist-t6ec6-wrong-placement' and the zoom transition fires
  - Then: The zoom origin bounds correspond to the cell's inner content area rather than the full card `ZStack` bounds, causing a visual mismatch where the zoom appears to originate from an inner rect; the hidden `NavigationLink` layer is excluded from the geometry capture
  - Verify: Confirm in `HomeView.swift` that `.matchedTransitionSource` is chained on the outer `ZStack` (after `.contentShape(Rectangle())`), NOT on `HomeItemViewCell(_:)`; the transition visually covers the entire card including padding areas

### EC 7: Empty Owner Name — Both firstName and lastName Empty

- [ ] **Scenario: Wishlist card gracefully handles a UserModel with both name fields empty**
  - Given: A `UserModel` ('user-ec7-empty-name') has `firstName = ""` and `lastName = ""`
  - When: `HomeItemViewCell` renders the owner row `Text("\(item.1.firstName) \(item.1.lastName)")`
  - Then: The owner name `Text` renders an empty string (or a single space) without UI overflow; the owner avatar circle (`ZStack` with `Circle`) remains visible and correctly sized at 28×28 pt
  - Verify: No layout shift or hidden-view clipping occurs; the owner row `HStack` does not collapse unexpectedly

### EC 8: Empty User firstName — Top Bar Greeting

- [ ] **Scenario: Top bar greeting avoids a malformed string when the authenticated user has no first name**
  - Given: The authenticated user ('user-ec8-no-firstname') has `userInfo.firstName = ""`
  - When: `HomeView` renders the `topAppBar` greeting using `AuthViewModel.userInfo.firstName`
  - Then: The greeting does not render an orphaned punctuation string such as `"Hey, !"` or `"Happy Planning, !"` — either the name portion is omitted or a generic fallback greeting is shown (e.g., `"Hey there! 🎉"`)
  - Verify: The greeting `Text` in the top bar is non-empty and syntactically correct; no trailing comma-space with an empty name slot is visible

### EC 9: Empty State — Correct Copy Per Tab When Both Tabs Are Empty

- [ ] **Scenario: Empty state renders tab-specific copy when switching between two empty tabs**
  - Given: Both `myWishlists` and `myFriendWishlists` state arrays are empty (`[]`) in `HomeViewModel`
  - When: The user is on the "My list" tab (empty state visible), then taps to switch to the "Friend's list" tab
  - Then: The "My list" empty state shows copy specific to creating one's own wishlist (e.g., "No wishlists yet"); the "Friend's list" empty state shows copy specific to joining or being invited to a friend's list — neither tab reuses the other tab's messaging
  - Verify: `gift_img` asset is displayed in both empty states; the `WishieButton` CTA label is contextually appropriate per tab

### EC 10: Empty State — Transition from Non-Empty to Empty

- [ ] **Scenario: Empty state appears correctly after all wishlists are deleted from a previously populated tab**
  - Given: `HomeViewModel.myWishlists` starts with 2 wishlists ('wishlist-ec10-a', 'wishlist-ec10-b') displayed on "My list" tab
  - When: Both wishlists are deleted via swipe actions, leaving `myWishlists = []`
  - Then: The empty state view (with `gift_img` and themed copy) replaces the list without layout artifacts or stale card views remaining on screen
  - Verify: `contentUnavailable` overlay renders immediately after the last item is removed; no ghost card frames are visible

### EC 11: GradientTheme Hex Values Missing "#" Prefix

- [ ] **Scenario: Color(hex:) renders correctly for GradientTheme values with missing "#" prefix**
  - Given: `GradientTheme.forest.secondary` returns `"91C788"` (no `#`) and `GradientTheme.purpleDream.primary` returns `"F4EEFF"` (no `#`) as defined in `GradientWishlishTheme.swift`
  - When: A wishlist with `themeColor = "forest"` or `themeColor = "purpleDream"` is rendered in `HomeItemViewCell`
  - Then: The gradient card does not render a transparent, black, or missing color for the affected stop; `Color(hex:)` either normalizes the string by stripping/adding `#` or the gradient degrades gracefully to an adjacent opaque color
  - Verify: Cards with `forest` and `purpleDream` themes are visually distinguishable and not transparent; if `Color(hex:)` requires `#`, the hex strings in `GradientWishlishTheme.swift` must be corrected to include it

### EC 12: Navigation Behavior Preservation — swipeActions After Redesign

- [ ] **Scenario: Swipe-to-delete and swipe actions remain functional on redesigned gradient cards**
  - Given: `HomeView` has at least one wishlist rendered using the redesigned `HomeItemViewCell` with gradient background
  - When: The user performs a trailing swipe gesture on a wishlist card
  - Then: The swipe action buttons (e.g., delete, leave) appear as expected; the swipe gesture is not blocked by any overlay, `ZStack` layer, or gesture recognizer added during the redesign; the action executes and the list updates correctly
  - Verify: `.swipeActions` modifier is still applied at the correct level in the `List` or `ForEach`; no new gesture modifiers on the card interfere with the system swipe

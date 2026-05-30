# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: HomeItemViewCell — Gradient Card Background and Shadow

- [ ] **Scenario: Wishlist card renders gradient background from theme colors**
  - Given: a `WishlistModel` named `"wishlist-ac1-gradient"` with `theme.primary = "#FFD6E0"` and `theme.secondary = "#FFF0F5"`, paired with an owner `UserModel`
  - When: `HomeItemViewCell` renders with this model
  - Then: the card background displays a `LinearGradient` transitioning from `Color(hex: "#FFD6E0")` at the top to `Color(hex: "#FFF0F5")` at the bottom on a `RoundedRectangle(cornerRadius: 16)`
  - Verify: no flat `.sunset.opacity(0.5)` fill is visible; gradient fills the entire card area; `cornerRadius` is 16

- [ ] **Scenario: Wishlist card displays themed shadow derived from secondary color**
  - Given: a `WishlistModel` named `"wishlist-ac1-shadow"` with `theme.secondary = "#C9B8FF"`
  - When: `HomeItemViewCell` renders with this model
  - Then: the card container has a shadow with color `Color(hex: "#C9B8FF").opacity(0.4)`, `radius: 8`, and `offset y: 4`
  - Verify: shadow is visible below the card; shadow color matches the secondary theme hex value at 40% opacity

### AC 2: HomeItemViewCell — Card Information Hierarchy

- [ ] **Scenario: Top row displays wishlist name and owner full name with avatar**
  - Given: a `WishlistModel` named `"wishlist-ac2-toprow"` with `name = "Birthday Wishes"` and an owner `UserModel` with `firstName = "Jane"` and `lastName = "Doe"`
  - When: `HomeItemViewCell` renders with this data
  - Then: the top row shows `"Birthday Wishes"` in bold 18pt on the left, and `"Jane Doe"` in regular 13pt with a 28×28 circular `lightYellow` avatar placeholder on the right
  - Verify: wishlist name uses `.wishies(.bold, 18)` with `.black` foreground; owner name uses `.wishies(.regular, 13)` with `.darkGrey` foreground; avatar circle is 28×28 with `lightYellow` fill and an overlaid `Image("user")` at 16×16

- [ ] **Scenario: Middle row displays description, gift progress ring, and item count**
  - Given: a `WishlistModel` named `"wishlist-ac2-middle"` with `description = "Celebrating 30 years"`, 5 total items, and 2 items marked as picked
  - When: `HomeItemViewCell` renders with this model
  - Then: the middle row shows the description text limited to 2 lines on the left, a `GiftProgressView` in a 72×72 frame on the right, and `"2/5 gifts"` label below the progress ring in regular 12pt `.darkGrey`
  - Verify: description uses `.wishies(.italic, 14)` at `.black.opacity(0.75)`; `lineLimit(2)` truncates longer text; item count format is `"\(picked)/\(total) gifts"`

- [ ] **Scenario: Bottom row displays a pill-shaped date badge with calendar icon**
  - Given: a `WishlistModel` named `"wishlist-ac2-date"` with `dueDate` set to `2026-12-25`
  - When: `HomeItemViewCell` renders with this model
  - Then: the bottom row shows a pill-shaped badge containing a `calendar` SF symbol in `.wishiePink` at 12pt alongside the formatted date string, all on a `Capsule` background of `Color.white.opacity(0.55)`
  - Verify: date text uses `.wishies(.regular, 12)` with `.black` foreground; badge has `.padding(.horizontal, 8).padding(.vertical, 4)`; no raw `ISO8601` string is displayed

### AC 3: HomeView — Celebration Top Bar Greeting

- [ ] **Scenario: Top bar renders personalised celebration greeting with user's first name**
  - Given: an authenticated user `"user-ac3-greeting"` with `firstName = "Alex"` is loaded into `AuthViewModel`
  - When: `HomeView` renders and `topAppBar()` is built
  - Then: the greeting reads `"Hey, Alex! 🎁"` in bold 22pt `.black`, with a subtitle `"What are you wishing for?"` in regular 13pt `.darkGrey` below it
  - Verify: old greeting `"Are you gud?"` is absent; greeting uses `.wishies(.bold, 22)`; subtitle uses `.wishies(.regular, 13)` with `.darkGrey` foreground; both are inside a `VStack(alignment: .leading, spacing: 2)`

- [ ] **Scenario: Top bar action buttons render with gold gradient circle backgrounds**
  - Given: `HomeView` is rendered for an authenticated user `"user-ac3-buttons"`
  - When: the top bar is displayed
  - Then: both the add button and the profile button show a `LinearGradient` circle (42×42) transitioning from `Color(hex: "#F1D790")` (top-leading) to `Color(hex: "#FEF3D7")` (bottom-trailing), overlaying `Image("add")` and `Image("user")` respectively at 20×20
  - Verify: plain `Circle().fill(.lightYellow)` backgrounds are absent; both icons are 20×20; gradient direction is top-leading to bottom-trailing

### AC 4: HomeView — Pill-Capsule Tab Selector

- [ ] **Scenario: Tab selector renders as a pill capsule with gradient selected indicator**
  - Given: `HomeView` is displayed and the `"My List"` tab `"tab-ac4-selector"` is selected
  - When: `typeSegmentItem(title:tab:)` renders both tabs
  - Then: the outer container uses `Capsule().fill(Color(hex: "#FEF3D7").opacity(0.3))`; the selected tab `"My List"` is highlighted with a `Capsule` filled by a `LinearGradient` from `Color(hex: "#F1D790")` (leading) to `Color(hex: "#FEF3D7")` (trailing)
  - Verify: old `RoundedRectangle` tab backgrounds are absent; unselected tab text uses `.darkGrey` (not `.lightGrey`); selected indicator uses `matchedGeometryEffect(id: "TAB", ...)` with spring animation

- [ ] **Scenario: Tab selector transitions smoothly when switching tabs**
  - Given: `HomeView` is rendered with `"My List"` selected as `"tab-ac4-transition"`
  - When: the user taps `"Friend's List"`
  - Then: the gradient capsule indicator animates from `"My List"` to `"Friend's List"` using a spring animation with `response: 0.25` and `dampingFraction: 0.8`
  - Verify: the navigation and wishlist data update to reflect the newly selected tab; animation is not instant or jarring; no layout shift occurs

### AC 5: HomeView — Celebration-Themed Empty State

- [ ] **Scenario: Empty state renders gift image asset instead of system tray icon**
  - Given: `HomeView` is loaded for user `"user-ac5-empty"` whose `myWishlists` array is empty and the `"My List"` tab is active
  - When: `contentUnavailable(msg:buttonTitle:action:)` is built
  - Then: `Image("gift_img")` is displayed at 90×90 with `scaledToFit`; the subtitle `"Your wishlist is waiting..."` is visible in italic 15pt `.wishiePink`; the CTA `WishieButton` has fill color `Color(hex: "#F1D790")`
  - Verify: `Image(systemName: "tray.fill")` is absent; `gift_img` scales correctly within 90×90; subtitle only appears when `selectedTab == .myList`

- [ ] **Scenario: Empty state subtitle is hidden on Friend's List tab**
  - Given: `HomeView` is loaded for user `"user-ac5-friendstab"` and the `"Friend's List"` tab is active with zero friend wishlists
  - When: `contentUnavailable(msg:buttonTitle:action:)` is built
  - Then: the `"Your wishlist is waiting..."` subtitle is NOT displayed; the `gift_img` image and the contextual `msg` text are still visible
  - Verify: subtitle visibility is conditional on `selectedTab == .myList`; no layout gap where the subtitle would appear

### AC 6: HomeView — Cohesive Celebration Bottom Sheet

- [ ] **Scenario: Bottom sheet renders gradient background and header label**
  - Given: a user `"user-ac6-bottomsheet"` long-presses a wishlist card to trigger the bottom sheet
  - When: `bottomSheet(type:)` is built and presented
  - Then: the background is a `LinearGradient` from `Color(hex: "#FEF9EC")` (top) to `Color(hex: "#FEF3D7")` (bottom) with `ignoresSafeArea()`; a header `Text("What would you like to do?")` is displayed in bold 16pt `.darkGrey` above the action options
  - Verify: `Color.lightYellow1` flat background is absent; header label is padded with `.padding(.top, 8)` and visually separates from the options

- [ ] **Scenario: Bottom sheet option rows render with themed white card and gradient icon container**
  - Given: the bottom sheet `"bottomsheet-ac6-options"` is presented showing edit and delete options
  - When: `bottomSheetOption(image:title:)` renders each row
  - Then: each row card uses `RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.6))` with a `stroke` of `Color(hex: "#F1D790")` at 1pt lineWidth; the icon is inside a 40×40 `RoundedRectangle(cornerRadius: 10)` filled with a gradient from `Color(hex: "#F1D790")` (top-leading) to `Color(hex: "#FEF3D7")` (bottom-trailing); title text uses `.wishies(.bold, 17)` with `.black` foreground
  - Verify: old `RoundedRectangle.fill(.lightYellow)` row backgrounds are absent; gradient icon container matches the gold palette; title font weight is bold at 17pt

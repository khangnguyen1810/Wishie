Redesign Home View UI with Celebration Theme

# Requirement Context

## Current State

The `HomeView.swift` screen is the main authenticated screen. It renders two tabs — "My list" and "Friend's list" — using a `HomeTab` enum and a `HomeViewModel` that fetches wishlists from `WishlistService`. Each wishlist is rendered inside `HomeItemViewCell.swift`. The current UI is utilitarian: flat segment tabs on a `lightYellow1` background, cards using a low-opacity `sunset` fill, a system `tray.fill` icon in the empty state, and a casual greeting "Are you gud?" in the top bar. There are no visual decorative elements tied to the wishlist, celebration, or anniversary theme.

## Goals

- Redesign `HomeItemViewCell` to use each wishlist's `GradientTheme` as a gradient card background, creating a visually rich, celebration-oriented card style with a clear information hierarchy for name, description, date, owner, and gift progress.
- Redesign the `HomeView` top bar (`topAppBar`) with a warmer celebratory greeting that displays the user's first name.
- Redesign the tab selector (`typeSegmentItem`) to use a polished pill-capsule style that aligns with the celebration palette.
- Redesign the empty state (`contentUnavailable`) to use the existing `gift_img` asset instead of a plain system icon, with copy that fits the theme.
- Redesign the bottom sheet (`bottomSheet`, `bottomSheetOption`) to feel cohesive with the celebration theme.

## Risk & Mitigation

- **Gradient card legibility**: Text on gradient backgrounds may have insufficient contrast — mitigated by using dark text colors on light gradient themes, and by layering subtle translucent overlays.
- **Layout flexibility**: Cards must accommodate varying name and description lengths without breaking layout — mitigated by using fixed-height clamping, `lineLimit`, and flexible Spacers.

# Technical Specification Context

## Functional Requirements:

- System MUST display wishlist cards with a gradient background derived from `WishlistModel.theme` (`GradientTheme`) using its `primary` and `secondary` hex color values.
- System MUST display an event/due date badge on each wishlist card using `WishlistModel.dueDate`.
- System MUST display the wishlist owner's full name on each card using `UserModel.firstName` and `UserModel.lastName`.
- System MUST display gift progress using `GiftProgressView` alongside a picked/total item count label.
- System MUST render the top bar greeting using `AuthViewModel.userInfo.firstName` with a celebration-appropriate string.
- System MUST render the tab selector as a styled pill/capsule that highlights the selected tab using a matched geometry effect.
- System MUST render an empty state using the `gift_img` image asset when `currentWishlists` is empty, with contextual copy per tab.
- System MUST render the bottom sheet with celebration-themed action options using `lightYellow` fill and themed icon containers.
- System MUST display the wishlist owner's real avatar image in `HomeItemViewCell` when `UserModel.avatarUrl` is non-nil and non-empty, loaded via `WishieWebImage`.
- System MUST display a fallback placeholder (`Image("user")`) in the avatar circle when `UserModel.avatarUrl` is nil or empty.

## Non-Functional Requirements:

- System MUST maintain all existing navigation behavior — `NavigationLink` zoom transitions, `swipeActions`, `.navigationDestination` routing — without modification.
- System MUST preserve all existing `HomeViewModel` state bindings (`myWishlists`, `myFriendWishlists`, `isGettingList`, `errorMessage`).
- System MUST use only existing asset catalog colors (`.lightYellow`, `.lightYellow1`, `.wishiePink`, `.darkGrey`, `.lightGrey`, `.sunset`) and `Color(hex:)` via `GradientTheme` hex values.
- System MUST use `Font.wishies(_:_:)` for all text elements.
- System MUST use `WishieButton` for CTA buttons in the empty state.
- System MUST use `WishieWebImage` (backed by SDWebImage) for all remote avatar image loading in `HomeItemViewCell`.
- System MUST clip the avatar to a `Circle` shape at 38×38 when displaying a real avatar via `WishieWebImage`.

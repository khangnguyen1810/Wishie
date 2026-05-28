# Verification Context — Acceptance Scenarios

## Purpose

Define testable acceptance scenarios in Given/When/Then format to verify the implementation meets functional requirements and success criteria.
This document serves as the single source of truth for acceptance verification.

## Test Data Isolation

Each scenario MUST use unique, scenario-specific test data namespaced by scenario/category name (e.g., "user-ac1-login", "product-ac2-checkout"). No two scenarios should share mutable state.

## Acceptance Scenarios:

### AC 1: Mandatory Onboarding Routing for New Users

- [ ] **Scenario: New user is routed to Interests Setup before HomeView after sign-up**
  - Given: a new user `user-ac1-signup` has just completed sign-up and their Firestore document does not contain `hasCompletedInterestsSetup`
  - When: `RootNavigationCoordinator` resolves the post-signup app state
  - Then: the coordinator transitions to `AppState.interestsSetup` and `InterestsSelectionView` is rendered with `isOnboarding: true` before any transition to `AppState.authenticated`
  - Verify: `AppState.authenticated` (HomeView) is NOT shown until `InterestsSelectionView` triggers the save action; confirm `RootNavigationCoordinator` holds `.interestsSetup` state

### AC 2: Mandatory Onboarding Routing for Existing Users with Flag False

- [ ] **Scenario: Existing user with `hasCompletedInterestsSetup = false` is routed to setup on app open**
  - Given: an authenticated user `user-ac2-legacy` has a Firestore document where `hasCompletedInterestsSetup` is `false` (or the field is absent)
  - When: the app restores the session by calling `checkToken()` and fetching user info
  - Then: `RootNavigationCoordinator` transitions to `AppState.interestsSetup`, showing `InterestsSelectionView` with `isOnboarding: true`
  - Verify: HomeView is not presented; the routing result is identical to the new-user post-signup flow

### AC 3: All Categories and Emoji Chips Are Displayed

- [ ] **Scenario: All 6 hobby categories and their emoji chips are rendered on the screen**
  - Given: `InterestsSelectionView` is opened (either onboarding or edit mode) for user `user-ac3-display`
  - When: the view finishes loading
  - Then: all 6 categories (Active & Sports, Creative, Entertainment & Tech, Food & Drink, Travel & Outdoor, Self-care & Lifestyle) are visible with their section headers, and each hobby chip displays an emoji followed by its label (e.g., 🏋️ Gym & Fitness)
  - Verify: no category is missing; no chip renders only text without an emoji; chip layout does not overflow horizontally

### AC 4: Hobby Chip Selection and Deselection

- [ ] **Scenario: User selects and deselects hobby chips across multiple categories**
  - Given: `InterestsSelectionView` is open for user `user-ac4-select` with no pre-selected interests
  - When: the user taps a chip to select it, then taps the same chip again to deselect it, and also taps chips in two different categories
  - Then: selected chips display at `scaleEffect(1.05)` with the selected visual style; deselected chips return to `scaleEffect(1.0)`; multiple simultaneous selections across categories are permitted
  - Verify: the selection toggle uses `.spring(response: 0.3, dampingFraction: 0.6)` animation; selected and unselected chips have visually distinct appearances using Wishie accent colors

### AC 5: Save Enabled with Zero Selections

- [ ] **Scenario: Save button is always enabled regardless of selection count**
  - Given: `InterestsSelectionView` is open for user `user-ac5-empty` with no hobbies selected
  - When: the user inspects the "Save & Continue" / save button without tapping any chip
  - Then: the save button is active and tappable with zero hobbies selected
  - Verify: the button does not appear disabled or grayed out; tapping it initiates a Firestore write with an empty interests array

### AC 6: Save Button Bottom Padding

- [ ] **Scenario: Save button has bottom padding and does not stick to the screen edge**
  - Given: `InterestsSelectionView` is displayed on a device with a home indicator or any screen size
  - When: the user scrolls to the bottom of the interests list
  - Then: the "Save & Continue" button has visible bottom padding that separates it from the screen's bottom edge
  - Verify: the button is not obscured by the home indicator or device safe area; there is a consistent spacing between the button's bottom edge and the screen boundary

### AC 7: Save Persists Interests to Firestore and Transitions to HomeView (Onboarding)

- [ ] **Scenario: Saving selected interests in onboarding context persists data and navigates to HomeView**
  - Given: `InterestsSelectionView` is open with `isOnboarding: true` for user `user-ac7-onboard` who has selected three hobbies across two categories
  - When: the user taps "Save & Continue"
  - Then: the selected interests array is written to Firestore under `users/user-ac7-onboard`; `hasCompletedInterestsSetup` is set to `true` in Firestore; the coordinator transitions to `AppState.authenticated`; HomeView is displayed
  - Verify: Firestore document for `user-ac7-onboard` contains the correct `interests` array and `hasCompletedInterestsSetup: true`; HomeView is rendered after the action completes

### AC 8: No Back Button or Swipe Dismiss in Onboarding Context

- [ ] **Scenario: Onboarding Interests screen cannot be dismissed without tapping Save & Continue**
  - Given: `InterestsSelectionView` is displayed with `isOnboarding: true` for user `user-ac8-nodismiss`
  - When: the user attempts to swipe the view down to dismiss it, or looks for a back navigation button
  - Then: no back button is visible in the TopAppBar left slot; swipe-to-dismiss gesture is disabled; the only available exit is the "Save & Continue" button
  - Verify: the view remains on screen after a swipe gesture; no navigation controls other than "Save & Continue" are tappable

### AC 9: Edit Mode Accessible from Profile Screen

- [ ] **Scenario: User opens Interests edit mode from the Profile screen**
  - Given: user `user-ac9-profile` is authenticated, `hasCompletedInterestsSetup` is `true`, and they are on the Profile screen
  - When: the user taps the "Interests" row in ProfileView
  - Then: `InterestsSelectionView` opens with `isOnboarding: false` via the Profile `NavigationStack`; a back button is visible in the TopAppBar left slot
  - Verify: the `Route` enum resolves `.interests`; the view is pushed onto the Profile navigation stack; `isOnboarding` flag is `false`

### AC 10: Pre-population of Previously Saved Interests in Edit Mode

- [ ] **Scenario: Previously saved interests are pre-selected when edit mode opens**
  - Given: user `user-ac10-prepopulate` has previously saved interests including "🏋️ Gym & Fitness" and "🎨 Drawing & Painting" in Firestore
  - When: the user opens `InterestsSelectionView` in edit mode from Profile
  - Then: the chips for "🏋️ Gym & Fitness" and "🎨 Drawing & Painting" render in the selected visual state immediately on load; all other chips render as unselected
  - Verify: the view model loads `interests` from the current `UserModel` and initializes chip selection state before the view is interactable

### AC 11: Edit Mode Save Dismisses Without Coordinator State Transition

- [ ] **Scenario: Saving interests in edit mode dismisses the view without triggering onboarding routing**
  - Given: `InterestsSelectionView` is open with `isOnboarding: false` for user `user-ac11-edit` who modifies their selected hobbies
  - When: the user taps the save button
  - Then: the updated interests array and `hasCompletedInterestsSetup: true` are written to Firestore; `InterestsSelectionView` is dismissed; the user returns to ProfileView; `AppState` does NOT change
  - Verify: `RootNavigationCoordinator` state remains `AppState.authenticated`; no transition to HomeView occurs; ProfileView is visible after dismissal

### AC 12: Back Button in Edit Mode Dismisses Without Saving

- [ ] **Scenario: Tapping the back button in edit mode dismisses the view without persisting changes**
  - Given: `InterestsSelectionView` is open with `isOnboarding: false` for user `user-ac12-backdismiss` who has modified the chip selection
  - When: the user taps the back button in the TopAppBar left slot
  - Then: `InterestsSelectionView` is dismissed; no Firestore write is performed; the previously saved interests remain unchanged
  - Verify: Firestore document for `user-ac12-backdismiss` retains the original interests array; ProfileView is displayed after dismissal

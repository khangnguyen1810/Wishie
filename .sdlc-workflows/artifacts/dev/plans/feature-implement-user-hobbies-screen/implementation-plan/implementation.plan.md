create-user-interests-selection-screen

# Requirement Context

## Current State

`UserModel` does not contain any interests or hobbies field. There is no interests selection screen in the app. User profile data is stored in Firestore under `users/{userId}` and updated via `AuthenticateService.updateUserInfo`. Navigation between profile-related screens is handled through the `Route` enum and `NavigationStack` in `ProfileView`.

## Goals

- Introduce a dedicated screen where users can select multiple interests grouped by category.
- Persist the selected interests to the user's Firestore document.
- Deliver the requested Gen Z-oriented visual direction with emoji chips and explicit interaction rules: selected chips scale to `1.05`, use `.spring(response: 0.3, dampingFraction: 0.6)`, and render category sections using the existing Wishie typography and colors.
- Integrate the screen into the existing navigation architecture without breaking current flows.
- Enable users to re-edit their selected interests from the Profile screen after initial setup via a new "Interests" row.

## Risk & Mitigation

- **Firestore schema change**: Adding `interests` and `hasCompletedInterestsSetup` to an existing user document is backward-compatible via optional decoding; existing users without the new fields will default to `[]` and `false`, which intentionally routes incomplete users to the interests setup screen.
- **Chip layout performance**: A large number of selectable chips in a `ScrollView` with a custom flow layout may cause jank on older devices. Mitigation: use lazy flow layout or a fixed grid instead of `FlowLayout`.

# Technical Specification Context

## Functional Requirements:

- System MUST display all 6 categories (Active & Sports, Creative, Entertainment & Tech, Food & Drink, Travel & Outdoor, Self-care & Lifestyle) with their respective hobbies.
- System MUST allow the user to select and deselect individual hobbies, with multiple simultaneous selections permitted across categories.
- System MUST provide distinct visual states for selected vs. unselected hobby chips.
- System MUST persist the selected interests to Firestore under the authenticated user's document when the user confirms.
- System MUST pre-populate the chip selection state from the user's previously saved interests when the screen is opened.
- System MUST expose a save/confirm action that triggers the Firestore update and dismisses or navigates away from the screen.
- System MUST handle and surface Firestore write errors to the user without crashing.
- System MUST be displayed as a mandatory post-signup onboarding step; after a new user signs up, `RootNavigationCoordinator` routes to `AppState.interestsSetup` before `AppState.authenticated`.
- System MUST route existing logged-in users whose `hasCompletedInterestsSetup` is `false` — including legacy users whose Firestore document lacks the field (defaulting to `false`) — to `AppState.interestsSetup` on app open, identical to new users.
- System MUST NOT display a back button or swipe-dismiss control on the Interests Setup screen when shown in the post-signup onboarding context; the only exit is the "Save & Continue" button.
- System MUST persist a profile-level completion flag `hasCompletedInterestsSetup` in Firestore and set it to `true` on successful save, even when the selected interests array is empty.
- System MUST read `hasCompletedInterestsSetup` during session restore and use that value to derive routing state without bypassing setup for users whose flag is `false`.
- System MUST, when `checkToken()` cannot fetch `hasCompletedInterestsSetup` from Firestore due to a network failure, default to `false` and route the user to `interestsSetup`.
- System MUST enable the save action with zero or more interests selected (no minimum required).
- System MUST transition the app to `AppState.authenticated` (HomeView) after the save action completes successfully during the post-signup flow.
- System MUST display an "Interests" row in `ProfileView` that opens `InterestsSelectionView` in edit mode (`isOnboarding: false`) via the Profile `NavigationStack`.
- System MUST, when `InterestsSelectionView` is opened in edit mode from Profile, display a back button in the `TopAppBar` left slot that dismisses the view without saving, and on successful save, dismiss the view without triggering coordinator state transitions.

## Non-Functional Requirements:

- System MUST render chip selection state changes using `.spring(response: 0.3, dampingFraction: 0.6)` with selected chips at `scaleEffect(1.05)` and unselected chips at `scaleEffect(1.0)`.
- System MUST use the established Wishie design system: `WorkSans` font, `.lightYellow1` background, `.wishiePink` / `.lightYellow` accent colors, and `WishieButton` for the primary action.
- System MUST not introduce any `print` or `console.log` debug statements in the final implementation.
- System MUST apply the same `InterestsSelectionView` visual design in both onboarding and edit contexts; the only structural difference is the TopAppBar left slot and the on-save navigation behaviour.

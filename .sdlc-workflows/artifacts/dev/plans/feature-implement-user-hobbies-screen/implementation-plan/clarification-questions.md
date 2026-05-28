# Clarification Questions Template

## Purpose

Record questions raised during planning and their confirmed answers to resolve ambiguities in task requirements, ensuring the implementation plan reflects verified decisions.

# Guide:

- NEVER add question's options into this file, keep context small.
- ONLY add questions and it's answer following the template below.

# Template

```
- [the question]:
[the answer and its brief reasoning]
```

# Clarification Questions:

- Where should the Interests Selection screen be accessible from?
  Post-signup onboarding step (mandatory, before reaching HomeView) and from the Profile screen (edit mode). A new `AppState.interestsSetup` case and a `hasCompletedInterestsSetup` AppStorage flag will be added to `RootNavigationCoordinator`. Existing users whose flag is `false` (including legacy users whose Firestore document lacks the field) are routed to `interestsSetup` on app open — identical to new users.

- Is a minimum number of selected interests required before the Save button is enabled?
  No minimum — save is always enabled regardless of how many (or how few) hobbies are selected.

- Should each hobby chip display an emoji alongside its label?
  Yes — each chip shows emoji + text (e.g., 🏋️ Gym & Fitness). The `HobbyItem` model will carry an `emoji: String` field alongside `name: String`.

- After saving interests, what should happen?
  Dismiss the screen. In the post-signup onboarding context this means the coordinator transitions forward to `AppState.authenticated`, routing the user into HomeView. In edit mode (opened from Profile), saving persists interests and dismisses the view without triggering coordinator state transitions.

- When an existing logged-in user opens the app and `hasCompletedInterestsSetup` is `false`, should the app force them through interests setup?
  Yes — existing users with `hasCompletedInterestsSetup = false` are routed to `interestsSetup` identically to new users. The flag is derived from the Firestore user document; a missing field defaults to `false`, so all users without a saved flag are sent to setup.

- Can the user dismiss or navigate back from the Interests Setup screen without tapping "Save & Continue"?
  No — in the onboarding context there is no back button or swipe-dismiss gesture; the only exit is "Save & Continue" (works with zero selections, acting as an implicit skip). In edit mode opened from Profile, the TopAppBar left slot shows a back button that calls `dismiss()` without saving.

- After completing initial interests setup, can users re-edit their interests from the Profile screen?
  Yes — a new "Interests" row is added to `ProfileView` that opens `InterestsSelectionView` in edit mode (`isOnboarding: false`). A `case interests` is added to the `Route` enum.

- If fetching `hasCompletedInterestsSetup` from Firestore fails during `checkToken()` (e.g., network unavailable), what should the app do?
  Conservative fallback — default to `false` and route to `interestsSetup`. The `UserModel` default of `false` handles this naturally; on failure, `getUserInfo()` resolves with the default model, which the coordinator reads as needing setup.

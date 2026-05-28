# AC 10: Pre-population of Previously Saved Interests in Edit Mode

- [x] **Scenario: Previously saved interests are pre-selected when edit mode opens**
  - Given: user `user-ac10-prepopulate` has previously saved interests including "🏋️ Gym & Fitness" and "🎨 Drawing & Painting" in Firestore
  - When: the user opens `InterestsSelectionView` in edit mode from Profile
  - Then: the chips for "🏋️ Gym & Fitness" and "🎨 Drawing & Painting" render in the selected visual state immediately on load; all other chips render as unselected
  - Verify: the view model loads `interests` from the current `UserModel` and initializes chip selection state before the view is interactable


# EC 8: Pre-Population of Previously Saved Interests in Edit Mode

- [x] **Scenario: Edit Mode Opens with Chips Pre-Selected Matching Saved Interests**
  - Given: User `"user-ec8-prepopulate"` has `interests: ["Gym & Fitness", "Painting", "Coffee & Cafes"]` saved in Firestore
  - When: The user opens `InterestsSelectionView` from `ProfileView` in edit mode (`isOnboarding: false`)
  - Then: The chips for "Gym & Fitness", "Painting", and "Coffee & Cafes" are rendered in their selected visual state (scaled to `1.05`, accent color applied); all other chips are unselected
  - Verify: Exactly three chips are in the selected state on screen load; no unintended chips are pre-selected; the selection reflects the Firestore data for `"user-ec8-prepopulate"`

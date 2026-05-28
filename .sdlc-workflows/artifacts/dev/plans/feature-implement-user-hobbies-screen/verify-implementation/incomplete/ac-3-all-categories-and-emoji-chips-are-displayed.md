# AC 3: All Categories and Emoji Chips Are Displayed

- [x] **Scenario: All 6 hobby categories and their emoji chips are rendered on the screen**
  - Given: `InterestsSelectionView` is opened (either onboarding or edit mode) for user `user-ac3-display`
  - When: the view finishes loading
  - Then: all 6 categories (Active & Sports, Creative, Entertainment & Tech, Food & Drink, Travel & Outdoor, Self-care & Lifestyle) are visible with their section headers, and each hobby chip displays an emoji followed by its label (e.g., 🏋️ Gym & Fitness)
  - Verify: no category is missing; no chip renders only text without an emoji; chip layout does not overflow horizontally

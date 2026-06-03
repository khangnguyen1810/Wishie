# EC 12: Navigation Behavior Preservation — swipeActions After Redesign

- [x] **Scenario: Swipe-to-delete and swipe actions remain functional on redesigned gradient cards**
  - Given: `HomeView` has at least one wishlist rendered using the redesigned `HomeItemViewCell` with gradient background
  - When: The user performs a trailing swipe gesture on a wishlist card
  - Then: The swipe action buttons (e.g., delete, leave) appear as expected; the swipe gesture is not blocked by any overlay, `ZStack` layer, or gesture recognizer added during the redesign; the action executes and the list updates correctly
  - Verify: `.swipeActions` modifier is still applied at the correct level in the `List` or `ForEach`; no new gesture modifiers on the card interfere with the system swipe

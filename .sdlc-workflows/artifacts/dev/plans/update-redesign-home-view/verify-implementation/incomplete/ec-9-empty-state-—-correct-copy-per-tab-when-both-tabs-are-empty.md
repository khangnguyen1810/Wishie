# EC 9: Empty State — Correct Copy Per Tab When Both Tabs Are Empty

- [x] **Scenario: Empty state renders tab-specific copy when switching between two empty tabs**
  - Given: Both `myWishlists` and `myFriendWishlists` state arrays are empty (`[]`) in `HomeViewModel`
  - When: The user is on the "My list" tab (empty state visible), then taps to switch to the "Friend's list" tab
  - Then: The "My list" empty state shows copy specific to creating one's own wishlist (e.g., "No wishlists yet"); the "Friend's list" empty state shows copy specific to joining or being invited to a friend's list — neither tab reuses the other tab's messaging
  - Verify: `gift_img` asset is displayed in both empty states; the `WishieButton` CTA label is contextually appropriate per tab

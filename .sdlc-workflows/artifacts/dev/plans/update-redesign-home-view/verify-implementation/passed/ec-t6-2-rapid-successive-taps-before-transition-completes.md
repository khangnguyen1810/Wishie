# EC-T6-2: Rapid Successive Taps Before Transition Completes

- [x] **Scenario: Double-tapping a wishlist card before the zoom animation finishes does not push duplicate detail screens**
  - Given: `homeViewModel.myWishlists` contains at least one entry ('wishlist-t6ec2-double-tap') and the zoom transition animation duration is approximately 0.35 s
  - When: The user taps the card twice in rapid succession (< 200 ms apart) before `WishlistDetailScreen` has finished appearing
  - Then: Only one `WishlistDetailScreen` instance is pushed onto the `NavigationStack`; the `NavigationPath` does not contain two identical destinations; the second tap is ignored or de-bounced by SwiftUI's navigation lock
  - Verify: After the transition completes, pressing back returns to `HomeView` in a single pop; the navigation stack depth is exactly 1 above home


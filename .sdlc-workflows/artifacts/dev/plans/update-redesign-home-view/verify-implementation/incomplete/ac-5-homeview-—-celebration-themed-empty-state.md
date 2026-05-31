# AC 5: HomeView — Celebration-Themed Empty State

- [ ] **Scenario: Empty state renders gift image asset instead of system tray icon**
  - Given: `HomeView` is loaded for user `"user-ac5-empty"` whose `myWishlists` array is empty and the `"My List"` tab is active
  - When: `contentUnavailable(msg:buttonTitle:action:)` is built
  - Then: `Image("gift_img")` is displayed at 90×90 with `scaledToFit`; the subtitle `"Your wishlist is waiting..."` is visible in italic 15pt `.wishiePink`; the CTA `WishieButton` has fill color `Color(hex: "#F1D790")`
  - Verify: `Image(systemName: "tray.fill")` is absent; `gift_img` scales correctly within 90×90; subtitle only appears when `selectedTab == .myList`

- [ ] **Scenario: Empty state subtitle is hidden on Friend's List tab**
  - Given: `HomeView` is loaded for user `"user-ac5-friendstab"` and the `"Friend's List"` tab is active with zero friend wishlists
  - When: `contentUnavailable(msg:buttonTitle:action:)` is built
  - Then: the `"Your wishlist is waiting..."` subtitle is NOT displayed; the `gift_img` image and the contextual `msg` text are still visible
  - Verify: subtitle visibility is conditional on `selectedTab == .myList`; no layout gap where the subtitle would appear


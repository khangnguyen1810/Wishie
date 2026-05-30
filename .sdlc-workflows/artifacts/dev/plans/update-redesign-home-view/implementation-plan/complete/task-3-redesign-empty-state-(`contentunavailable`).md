# Task 3: Redesign Empty State (`contentUnavailable`)

- [ ] 3.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE `contentUnavailable(msg:buttonTitle:action:)`:
  - Replace `Image(systemName: "tray.fill")` with `Image("gift_img").resizable().scaledToFit().frame(width: 90, height: 90)`.
  - Add a `Text` subtitle above the message using `"Your wishlist is waiting..."` with `.wishies(.italic, 15)` and `.wishiePink` — visible only when `selectedTab == .myList` (pass `selectedTab` as a parameter or capture it via closure).
  - Keep `WishieButton` CTA and the `"Refresh"` tappable text unchanged; update `WishieButton` fill color to `filColor: Color(hex: "#F1D790")`.
  - Wrap the whole `VStack` in a `VStack(spacing: 16)` with `.padding(40)` for better vertical rhythm.

---


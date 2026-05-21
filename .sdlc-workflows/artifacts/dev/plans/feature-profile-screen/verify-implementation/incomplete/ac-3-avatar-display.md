# AC 3: Avatar Display

- [x] **Scenario: User avatar placeholder is prominently centered below the top bar**
  - Given: `ProfileView` is presented for user `user-ac3-avatar`
  - When: The screen content area is rendered
  - Then: A circular avatar (`Image("user")` inside a `lightYellow` circle, 100×100 pt) appears centered at the top of the scrollable content with visible padding from the top bar
  - Verify: The avatar is horizontally centered; there is at least 20 pt top padding; no real user photo is shown (placeholder only)

# AC 2: Top App Bar Layout

- [x] **Scenario: Back button and title are correctly rendered in ProfileView's top bar**
  - Given: `ProfileView` is presented for user `user-ac2-topbar`
  - When: The screen finishes loading
  - Then: A back button (`back_icon` image inside a `lightYellow` circle) appears on the leading side of the top bar, and the title "Profile" is centered
  - Verify: Tapping the back button dismisses `ProfileView` and returns to the previous screen; the back button style matches other back buttons in the project


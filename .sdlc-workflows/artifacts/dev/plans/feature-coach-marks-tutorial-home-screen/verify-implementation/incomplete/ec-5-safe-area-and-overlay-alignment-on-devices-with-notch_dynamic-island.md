# EC 5: Safe Area and Overlay Alignment on Devices with Notch/Dynamic Island

- [x] **Scenario: Spotlight cutout aligns correctly with the add button on a device with Dynamic Island**
  - Given: User 'user-ec5-notch' is on an iPhone 15 Pro (Dynamic Island) launching the tutorial for the first time
  - When: Step 1 renders and spotlights the add (+) button in the top navigation bar
  - Then: The spotlight cutout precisely frames the add button without being offset by the safe area inset; no part of the dim overlay bleeds into the cutout area
  - Verify: Confirm `HomeTutorialOverlayView` uses `.ignoresSafeArea()` on the overlay container; confirm the `Anchor<CGRect>` resolved rect matches the visual button position on-screen

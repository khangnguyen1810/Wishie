# AC 6: HomeView — Cohesive Celebration Bottom Sheet

- [ ] **Scenario: Bottom sheet renders gradient background and header label**
  - Given: a user `"user-ac6-bottomsheet"` long-presses a wishlist card to trigger the bottom sheet
  - When: `bottomSheet(type:)` is built and presented
  - Then: the background is a `LinearGradient` from `Color(hex: "#FEF9EC")` (top) to `Color(hex: "#FEF3D7")` (bottom) with `ignoresSafeArea()`; a header `Text("What would you like to do?")` is displayed in bold 16pt `.darkGrey` above the action options
  - Verify: `Color.lightYellow1` flat background is absent; header label is padded with `.padding(.top, 8)` and visually separates from the options

- [ ] **Scenario: Bottom sheet option rows render with themed white card and gradient icon container**
  - Given: the bottom sheet `"bottomsheet-ac6-options"` is presented showing edit and delete options
  - When: `bottomSheetOption(image:title:)` renders each row
  - Then: each row card uses `RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.6))` with a `stroke` of `Color(hex: "#F1D790")` at 1pt lineWidth; the icon is inside a 40×40 `RoundedRectangle(cornerRadius: 10)` filled with a gradient from `Color(hex: "#F1D790")` (top-leading) to `Color(hex: "#FEF3D7")` (bottom-trailing); title text uses `.wishies(.bold, 17)` with `.black` foreground
  - Verify: old `RoundedRectangle.fill(.lightYellow)` row backgrounds are absent; gradient icon container matches the gold palette; title font weight is bold at 17pt


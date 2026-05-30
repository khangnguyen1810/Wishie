# AC 4: HomeView — Pill-Capsule Tab Selector

- [x] **Scenario: Tab selector renders as a pill capsule with gradient selected indicator**
  - Given: `HomeView` is displayed and the `"My List"` tab `"tab-ac4-selector"` is selected
  - When: `typeSegmentItem(title:tab:)` renders both tabs
  - Then: the outer container uses `Capsule().fill(Color(hex: "#FEF3D7").opacity(0.3))`; the selected tab `"My List"` is highlighted with a `Capsule` filled by a `LinearGradient` from `Color(hex: "#F1D790")` (leading) to `Color(hex: "#FEF3D7")` (trailing)
  - Verify: old `RoundedRectangle` tab backgrounds are absent; unselected tab text uses `.darkGrey` (not `.lightGrey`); selected indicator uses `matchedGeometryEffect(id: "TAB", ...)` with spring animation

- [x] **Scenario: Tab selector transitions smoothly when switching tabs**
  - Given: `HomeView` is rendered with `"My List"` selected as `"tab-ac4-transition"`
  - When: the user taps `"Friend's List"`
  - Then: the gradient capsule indicator animates from `"My List"` to `"Friend's List"` using a spring animation with `response: 0.25` and `dampingFraction: 0.8`
  - Verify: the navigation and wishlist data update to reflect the newly selected tab; animation is not instant or jarring; no layout shift occurs


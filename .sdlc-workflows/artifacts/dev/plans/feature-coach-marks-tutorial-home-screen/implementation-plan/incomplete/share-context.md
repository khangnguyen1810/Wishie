# Share Context

## Important Instructions for Implementation

- Use `overlayPreferenceValue(key: CoachMarkBoundsKey.self)` instead of `.overlay` in `HomeView` to gain access to element anchor bounds; this modifier is always active so conditional rendering is done inside the closure
- Resolve `Anchor<CGRect>` to `CGRect` inside `HomeTutorialOverlayView` using its own `GeometryReader` — never pass `GeometryProxy` across view boundaries
- The spotlight cutout uses SwiftUI `Path` with `FillStyle(eoFill: true)` — the outer rect and inner rounded rect together create a transparent hole via the even-odd rule
- Step 3 has `anchorID: nil` — render a centered tooltip with no spotlight cutout and no arrow
- Do NOT change `WishieConstants.hasSeenHomeTutorial` or its `AppStorage` usage in `HomeView`
- Step transition animation (`.easeInOut(duration: 0.25)`) is applied when advancing `currentStep` inside `HomeTutorialOverlayView`

## Reused Existing Functions/Utilities

- `WishieConstants.hasSeenHomeTutorial`: `AppStorage` key for tutorial completion persistence — `Wishie/Constants/WishieConstants.swift`
- `Color(hex:)`: hex-string color initializer — `Wishie/Helper/ColorExtension.swift`
- `.font(.wishies(_:_:))`: custom font modifier — `Wishie/Resources/WishieCustomFont.swift`

## Shared Contracts

### Entities

- `CoachMarkStep`: Represents one tutorial step. Properties: `anchorID: String?` (nil = no spotlight), `title: String`, `message: String`, `arrowDirection: CoachMarkArrowDirection`
- `CoachMarkArrowDirection`: Enum indicating tooltip arrow direction. Cases: `up` (arrow points upward toward element above tooltip), `down` (arrow points downward toward element below tooltip), `none` (no arrow, used when anchorID is nil)

### Interfaces

None

### DTOs

None

---


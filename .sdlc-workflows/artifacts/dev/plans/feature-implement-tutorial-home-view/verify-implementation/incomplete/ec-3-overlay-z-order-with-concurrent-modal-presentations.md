# EC 3: Overlay Z-Order with Concurrent Modal Presentations

- [ ] **Scenario: Tutorial overlay does not block or interfere with an open sheet or dialog** ❌ FAILED
  - Given: User `user-ec3-modal` is on `HomeView` with `hasSeenHomeTutorial = false` and a sheet or dialog is simultaneously presented (e.g., an edit dialog)
  - When: `HomeView` renders with both the tutorial overlay and a modal active
  - Then: The modal/sheet remains interactive and dismissible; the tutorial overlay does not cover or capture gestures from the modal
  - Verify: Confirm the overlay is applied at the `NavigationStack` level, beneath modal presentations; confirm the sheet/dialog receives tap and drag gestures independently of the overlay
  - **Failure**: The tutorial overlay renders on top of all custom dialog overlays (`showDialogIfNeeded`, `showFullScreenDialog`), covering them and preventing user interaction with dialog buttons when both are simultaneously active.
  - **Root Cause**: `showDialogIfNeeded` and `showFullScreenDialog` are both implemented as view-level `.overlay` modifiers on `NavigationStack` (not system-level modal presentations). In SwiftUI, each successive `.overlay` modifier renders above the previous one. The tutorial overlay is applied last in the modifier chain — after `.showFullScreenDialog` — making it the topmost view-level layer (overlay 5). When `hasSeenHomeTutorial = false` and any custom dialog overlay is simultaneously active (e.g., `homeViewModel.isGettingList = true` on first launch triggering `showFullScreenDialog`, or an auth error triggering `isShowError`), the tutorial overlay covers the dialog entirely. Only `.sheet` and `.fullScreenCover` — which use UIKit's system presentation stack (a separate window layer above all SwiftUI content) — are unaffected by the tutorial overlay's Z-position.
  - **Affected Files**:
    - `Wishie/Screens/Home/HomeView.swift` lines 215–256: Modifier chain where `.showDialogIfNeeded` (×3), `.showFullScreenDialog`, and `.overlay { HomeTutorialOverlayView }` are applied sequentially — tutorial overlay is last and therefore topmost.
    - `Wishie/CustomView/DialogView.swift` lines 116–140: Both `showDialogIfNeeded` and `showFullScreenDialog` extension methods are implemented as `self.overlay { ... }`, confirming they are view-level overlays subject to SwiftUI Z-order stacking, not system modal presentations.

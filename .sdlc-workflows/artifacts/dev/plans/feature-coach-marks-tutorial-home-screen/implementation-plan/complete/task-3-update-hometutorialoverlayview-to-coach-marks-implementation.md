# Task 3: Update HomeTutorialOverlayView to Coach Marks Implementation

- [ ] 3.1: In `Wishie/CustomView/HomeTutorialOverlayView.swift` UPDATE (replace entire file content):
  - Import `SwiftUI`
  - Define `struct HomeTutorialOverlayView: View` with:
    - `let anchors: [String: Anchor<CGRect>]` (anchors dictionary from `CoachMarkBoundsKey`, provided by `HomeView`)
    - `let onComplete: () -> Void`
    - `@State private var currentStep: Int = 0`
  - Define `private let steps: [CoachMarkStep]` as a stored constant (uses `CoachMarkStep` from task 1.1):
    ```
    CoachMarkStep(anchorID: "homeAddButton", title: "Create or Join", message: "Tap + to create a new wishlist or scan a QR code to join a friend's list", arrowDirection: .up)
    CoachMarkStep(anchorID: "homeTabSelector", title: "Your Lists", message: "Switch between your own wishlists and the wishlists you have joined", arrowDirection: .up)
    CoachMarkStep(anchorID: nil, title: "Swipe to Manage", message: "Swipe left on any wishlist to quickly delete it or leave a friend's list", arrowDirection: .none)
    ```
  - `body`:
    - `GeometryReader { proxy in ... }.ignoresSafeArea()`
    - Inside `GeometryReader`: resolve `highlightRect: CGRect?` by checking `steps[currentStep].anchorID`, looking it up in `anchors`, and calling `proxy[anchor]` — assign `nil` if `anchorID` is `nil` or key is absent
    - Render `CoachMarkOverlayView` (from task 2.1) passing: `highlightRect: highlightRect`, `step: steps[currentStep]`, `stepIndex: currentStep`, `totalSteps: steps.count`, `onNext: { withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 } }`, `onDone: onComplete`


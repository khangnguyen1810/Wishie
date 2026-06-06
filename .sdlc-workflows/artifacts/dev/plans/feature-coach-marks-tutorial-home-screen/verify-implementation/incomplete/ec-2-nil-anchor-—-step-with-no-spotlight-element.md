# EC 2: Nil Anchor — Step With No Spotlight Element

- [x] **Scenario: Step 3 renders centered tooltip without a spotlight cutout**
  - Given: User 'user-ec2-step3' has the tutorial active and `currentStep` is at index 2 (swipe gesture hint, `anchorID: nil`)
  - When: The coach mark overlay renders step 3
  - Then: No spotlight hole is punched through the dim overlay; the dim layer covers the entire screen uniformly; the tooltip is centered on screen without crashing
  - Verify: Confirm `CoachMarkOverlayView` does not attempt to resolve `Anchor<CGRect>` when `anchorID` is nil; confirm no runtime crash or out-of-bounds access occurs

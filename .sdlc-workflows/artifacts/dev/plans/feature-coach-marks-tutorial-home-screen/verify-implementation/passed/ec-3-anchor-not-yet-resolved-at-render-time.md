# EC 3: Anchor Not Yet Resolved at Render Time

- [x] **Scenario: Overlay renders safely when PreferenceKey anchor has not propagated yet**
  - Given: User 'user-ec3-timing' has the tutorial triggered immediately on first launch before the view layout pass completes and `CoachMarkBoundsKey` has not yet emitted a value for the add-button anchor
  - When: `HomeTutorialOverlayView` attempts to read the anchor for step 1 from the `GeometryProxy`
  - Then: The overlay renders in a safe fallback state (e.g., no spotlight or full-screen dim) without crashing; the spotlight does not appear in an incorrect screen position
  - Verify: Confirm the `bounds[anchorID]` optional lookup returns nil gracefully; confirm the app does not crash with a force-unwrap or index error

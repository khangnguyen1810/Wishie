# AC 7: Dim Overlay Applied on Spotlight Steps

- [x] **Scenario: Non-spotlighted UI is visually dimmed when a spotlight step is active**
  - Given: The coach marks tutorial is active at step 1 or step 2 for user `user-ac7-dim`
  - When: The spotlight step renders
  - Then: A dim layer covers the entire screen; only the spotlighted element is visually clear through the even-odd fill cutout
  - Verify: The `Path` with `FillStyle(eoFill: true)` produces a visible hole at the spotlighted element's `CGRect`; all surrounding UI is obscured by the overlay

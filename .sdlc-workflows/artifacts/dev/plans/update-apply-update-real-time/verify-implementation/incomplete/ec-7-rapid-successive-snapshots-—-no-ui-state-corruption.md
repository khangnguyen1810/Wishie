# EC 7: Rapid Successive Snapshots — No UI State Corruption

- [x] **Scenario: Multiple rapid Firestore snapshots arrive within the same render cycle**
  - Given: `WishlistDetailViewController 'detail-ec7-rapid'` has an active listener and is observing wishlist `"wl-ec7"`
  - When: Three Firestore snapshots fire in quick succession (e.g., item picked, then unpicked, then picked again within 500 ms)
  - Then: Each snapshot is processed sequentially; `wishlistInfo` reflects the state from the final snapshot; no intermediate states cause index-out-of-bounds or list corruption
  - Verify: Confirm the view model applies each update without crashing; confirm the final displayed state matches the last snapshot received

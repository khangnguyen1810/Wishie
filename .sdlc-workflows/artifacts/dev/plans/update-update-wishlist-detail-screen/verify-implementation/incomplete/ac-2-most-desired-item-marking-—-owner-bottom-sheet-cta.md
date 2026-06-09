# AC 2: Most Desired Item Marking — Owner Bottom Sheet CTA

- [x] **Scenario: "Mark as Most Desired" CTA appears for an unmarked item in the owner's bottom sheet**
  - Given: A wishlist `wishlist-ac2-markdesired` is owned by the logged-in user and contains item `item-ac2-unmarked` with `isMostDesired = false`
  - When: The owner taps on `item-ac2-unmarked` to open the bottom sheet
  - Then: A "Mark as Most Desired" button is visible in the bottom sheet
  - Verify: The CTA is tappable; no star badge is shown on the item row before tapping; the button label matches the specified text

- [x] **Scenario: "Mark as Most Desired" CTA is absent when the item is already marked**
  - Given: A wishlist `wishlist-ac2-alreadydesired` is owned by the logged-in user and contains item `item-ac2-marked` with `isMostDesired = true`
  - When: The owner taps on `item-ac2-marked` to open the bottom sheet
  - Then: The "Mark as Most Desired" CTA is not shown in the bottom sheet
  - Verify: The bottom sheet renders without the CTA; other CTAs (Edit, Delete) are unaffected

- [x] **Scenario: Marking an item as most desired persists and does not affect other items**
  - Given: A wishlist `wishlist-ac2-multidesired` is owned by the logged-in user and contains `item-ac2-a` (`isMostDesired = false`) and `item-ac2-b` (`isMostDesired = false`)
  - When: The owner marks `item-ac2-a` as most desired via the bottom sheet
  - Then: `item-ac2-a` shows a star badge; `item-ac2-b` remains unchanged with no star badge; the change persists to Firestore
  - Verify: Both items are visible in the list; only `item-ac2-a` has the star badge; re-opening the screen still reflects the updated state

---

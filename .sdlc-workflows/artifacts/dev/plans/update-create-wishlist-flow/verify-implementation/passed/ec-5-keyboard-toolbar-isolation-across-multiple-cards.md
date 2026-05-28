# EC 5: Keyboard Toolbar Isolation Across Multiple Cards

- [x] **Scenario: Done toolbar button on card 2 does not affect cards 1 and 3** ✅ RESOLVED
  - Given: Wishlist 'wishlist-ec5-multi' contains exactly 3 WishlistItemCards; the `name` field of card 2 is currently focused
  - When: The user taps the "Done" button on the keyboard toolbar
  - Then: Only card 2's keyboard dismisses; cards 1 and 3 remain unaffected; no duplicate toolbar items appear; no other card gains focus
  - Verify: Inspect the toolbar item count — only one "Done" button should be visible; confirm cards 1 and 3 have no active first responder
  - **Failure**: The keyboard toolbar shows 3 "Done" buttons (one per rendered card) instead of exactly 1; the scenario requires "only one 'Done' button should be visible"
  - **Root Cause**: `.toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer() Button("Done") { ... } } }` is placed unconditionally on each `WishlistItemCard` body (lines 143–150). SwiftUI aggregates `.keyboard` placement toolbar items from **all rendered views** in the hierarchy — not just the focused view's subtree. With 3 `WishlistItemCard` instances simultaneously rendered inside the `ForEach` of `CreateWishlistPage2`'s `List`, all 3 register their keyboard toolbar items, causing 3 "Done" buttons to appear. There is no conditional or focus-gating mechanism to suppress toolbar items from unfocused cards.
  - **Affected Files**: [Wishie/Screens/CreateList/CreateWishlistPage2.swift](Wishie/Screens/CreateList/CreateWishlistPage2.swift#L143-L150)
  - **Code Snippet**:
    ```swift
    // Lines 143–150 inside WishlistItemCard.body — applied to EVERY card instance
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                focusedField = nil
            }
        }
    }
    ```
  - **Resolution**: Wrapped `ToolbarItemGroup(placement: .keyboard)` in an `if focusedField != nil` condition inside the `.toolbar` modifier. SwiftUI's `ToolbarContentBuilder` supports conditional content — when a card's `focusedField` is `nil` (unfocused), no toolbar item is registered; only the card with an active focus state contributes the "Done" button, ensuring exactly one button appears at all times.


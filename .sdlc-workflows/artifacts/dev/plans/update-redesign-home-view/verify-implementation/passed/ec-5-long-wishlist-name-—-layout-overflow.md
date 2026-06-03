# EC 5: Long Wishlist Name — Layout Overflow

- [x] **Scenario: Wishlist card truncates an excessively long name without breaking the owner row** ✅ RESOLVED
  - Given: A `WishlistModel` ('wishlist-ec5-long-name') has `name` set to an 80-character string (e.g., `"Birthday Celebration For My Dearest Friend Who Loves Collecting Rare Vintage Items"`)
  - When: `HomeItemViewCell` renders the `HStack` containing the name `Text` and the owner row
  - Then: The name text truncates with `.tail` truncation; the owner name and avatar circle remain fully visible and do not get pushed off-screen; the card maintains its standard height
  - Verify: The name `Text` does not overlap the owner `HStack`; the card horizontal padding is preserved
  - **Failure**: The name `Text` wraps to multiple lines instead of truncating with `.tail`. The card height grows beyond its standard size for long names.
  - **Root Cause**: `Text(item.0.name)` at line 16 in `HomeItemViewCell.swift` has no `.lineLimit(1)` modifier. Without a line limit, SwiftUI wraps the text to as many lines as needed rather than truncating. The `.truncationMode(.tail)` is only effective when a `lineLimit` is also applied. As a result, an 80-character name expands the card's `VStack` vertically, breaking both the truncation requirement and the standard card height guarantee.
  - **Affected Files**: `Wishie/Screens/Home/HomeItemViewCell.swift` — lines 16–19 (`Text(item.0.name)` modifier chain missing `.lineLimit(1)`)
  - **Resolution**: Added `.lineLimit(1)` and `.truncationMode(.tail)` modifiers to `Text(item.0.name)` in `HomeItemViewCell.swift`. SwiftUI now enforces a single-line constraint so tail truncation activates for names exceeding available width, preserving standard card height and keeping the owner row fully visible.

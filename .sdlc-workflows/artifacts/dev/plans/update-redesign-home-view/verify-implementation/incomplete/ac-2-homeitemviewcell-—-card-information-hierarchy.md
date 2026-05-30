# AC 2: HomeItemViewCell — Card Information Hierarchy

- [x] **Scenario: Top row displays wishlist name and owner full name with avatar**
  - Given: a `WishlistModel` named `"wishlist-ac2-toprow"` with `name = "Birthday Wishes"` and an owner `UserModel` with `firstName = "Jane"` and `lastName = "Doe"`
  - When: `HomeItemViewCell` renders with this data
  - Then: the top row shows `"Birthday Wishes"` in bold 18pt on the left, and `"Jane Doe"` in regular 13pt with a 28×28 circular `lightYellow` avatar placeholder on the right
  - Verify: wishlist name uses `.wishies(.bold, 18)` with `.black` foreground; owner name uses `.wishies(.regular, 13)` with `.darkGrey` foreground; avatar circle is 28×28 with `lightYellow` fill and an overlaid `Image("user")` at 16×16

- [x] **Scenario: Middle row displays description, gift progress ring, and item count**
  - Given: a `WishlistModel` named `"wishlist-ac2-middle"` with `description = "Celebrating 30 years"`, 5 total items, and 2 items marked as picked
  - When: `HomeItemViewCell` renders with this model
  - Then: the middle row shows the description text limited to 2 lines on the left, a `GiftProgressView` in a 72×72 frame on the right, and `"2/5 gifts"` label below the progress ring in regular 12pt `.darkGrey`
  - Verify: description uses `.wishies(.italic, 14)` at `.black.opacity(0.75)`; `lineLimit(2)` truncates longer text; item count format is `"\(picked)/\(total) gifts"`

- [x] **Scenario: Bottom row displays a pill-shaped date badge with calendar icon**
  - Given: a `WishlistModel` named `"wishlist-ac2-date"` with `dueDate` set to `2026-12-25`
  - When: `HomeItemViewCell` renders with this model
  - Then: the bottom row shows a pill-shaped badge containing a `calendar` SF symbol in `.wishiePink` at 12pt alongside the formatted date string, all on a `Capsule` background of `Color.white.opacity(0.55)`
  - Verify: date text uses `.wishies(.regular, 12)` with `.black` foreground; badge has `.padding(.horizontal, 8).padding(.vertical, 4)`; no raw `ISO8601` string is displayed

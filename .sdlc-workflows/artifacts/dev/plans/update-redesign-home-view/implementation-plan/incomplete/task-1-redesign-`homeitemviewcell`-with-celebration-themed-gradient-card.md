# Task 1: Redesign `HomeItemViewCell` with Celebration-Themed Gradient Card

- [ ] 1.1: In `Wishie/Screens/Home/HomeItemViewCell.swift` UPDATE:
  - Replace the flat `.sunset.opacity(0.5)` `RoundedRectangle` background with a `LinearGradient` using `Color(hex: item.0.theme.primary)` (top) → `Color(hex: item.0.theme.secondary)` (bottom) on a `RoundedRectangle(cornerRadius: 16)`.
  - Add a `.shadow(color: Color(hex: item.0.theme.secondary).opacity(0.4), radius: 8, x: 0, y: 4)` to the card container.
  - Restructure the card `VStack` layout:
    - **Top row** (`HStack`): Wishlist name (`Text(item.0.name)`, `.wishies(.bold, 18)`, `.black`) on the left; owner full name (`Text("\(item.1.firstName) \(item.1.lastName)")`, `.wishies(.regular, 13)`, `.darkGrey`) with a `Circle` avatar placeholder (28×28, `lightYellow` fill, overlaid with `Image("user")` at 16×16) on the right.
    - **Middle row** (`HStack(alignment: .top)`): Description text (`Text(item.0.description)`, `.wishies(.italic, 14)`, `.black.opacity(0.75)`, `lineLimit(2)`) filling remaining space; `GiftProgressView(progress:)` in a fixed 72×72 frame with a gift count label below (`Text("\(itemPicked.count)/\(item.0.items.count) gifts")` or `"0 gifts"`, `.wishies(.regular, 12)`, `.darkGrey`).
    - **Bottom row** (`HStack`): A pill-shaped date badge — `HStack` containing `Image(systemName: "calendar")` (12pt, `.wishiePink`) and `Text("item.0.dueDate.toShortDateString()")` (`.wishies(.regular, 12)`, `.black`) — wrapped in a `Capsule` background of `Color.white.opacity(0.55)` with `.padding(.horizontal, 8).padding(.vertical, 4)`.
  - Remove the old `wishListItem` internal method (it already lives in `HomeView`; the cell is self-contained).
  - Set overall card `VStack` padding to `.padding(14)`.

---


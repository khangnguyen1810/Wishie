# Task 5: Implement User Avatar in `HomeItemViewCell`

- [ ] 5.1: In `Wishie/Screens/Home/HomeItemViewCell.swift` UPDATE `headerRow`:
  - Replace the static `Image("user")` avatar placeholder inside the avatar `ZStack` with a conditional block that checks `item.1.avatarUrl`:
    - When `item.1.avatarUrl` is non-nil and non-empty: render `WishieWebImage(url: avatarUrl)` inside a `Circle` clip shape at 38×38, retaining the existing `Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5)` overlay border and the `Color.white.opacity(0.55)` fill background.
    - When `item.1.avatarUrl` is nil or empty: retain the existing `Image("user").resizable().scaledToFit().frame(width: 21, height: 21)` fallback inside the same `ZStack`.
  - Extract a private computed property `private var avatarView: some View` in `HomeItemViewCell` that encapsulates the conditional avatar rendering, keeping `headerRow` readable.
  - The `ZStack` container remains `Circle().fill(Color.white.opacity(0.55)).frame(width: 38, height: 38).overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5))`; only the inner content changes.
  - The `Text(item.1.firstName.isEmpty ? "—" : item.1.firstName)` label below the avatar remains unchanged.

# Task 3: Polish "Add New Item" Button

- [ ] 3.1: In `Wishie/Screens/CreateList/CreateWishlistPage2.swift` UPDATE `CreateWishlistPage2`:
  - Replace the `Text("+ add new item")` plain text inside the `List` with a styled `HStack(spacing: 8)` containing:
    - `Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.wishiePink)`
    - `Text("Add new item").font(.wishies(.bold, 15)).foregroundStyle(.wishiePink)`
  - Apply `.frame(maxWidth: .infinity, alignment: .center)` to the `HStack`
  - Retain `.listRowSeparator(.hidden)`, `.listRowBackground(Color.lightYellow1)`, `.onTapGesture`, and `.padding(.bottom, 100)` modifiers

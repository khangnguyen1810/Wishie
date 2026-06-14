# Task 4: Create AddItemOptionSheet view

- [ ] 4.1: In `Wishie/Screens/CreateList/AddItemOptionSheet.swift` CREATE:
  - Define `struct AddItemOptionSheet: View`.
  - Accept two action closures via `let onPasteLink: () -> Void` and `let onManual: () -> Void`.
  - Body: a `VStack(spacing: 16)` with:
    - A drag handle `Capsule().fill(.gray.opacity(0.3)).frame(width: 40, height: 4)` at the top.
    - A title `Text("Add a gift idea")` styled `Font.wishies(.bold, 20)`.
    - An option card for "Paste a product link" using a `HStack` with `Image(systemName: "link")` icon (`.wishiePink` tint) and text labels: primary `Text("Paste a product link")` `.wishies(.bold, 16)` and secondary `Text("Auto-fill name, image & price from any site")` `.wishies(.regular, 13)` `.gray`. Background: `RoundedRectangle(cornerRadius: 16).fill(.white)` with a `.wishiePink.opacity(0.15)` border stroke, `lineWidth: 1.5`. `onTapGesture` calls `onPasteLink()`.
    - An option card for "Fill in manually" using the same structure with `Image(systemName: "pencil")` icon (`.black` tint) and labels: primary `Text("Fill in manually")` and secondary `Text("Add item details yourself")`. Background: `RoundedRectangle(cornerRadius: 16).fill(.white)` with `.black.opacity(0.08)` border. `onTapGesture` calls `onManual()`.
    - `.padding(.horizontal, 20).padding(.bottom, 32)`.
  - The sheet content sits inside a `VStack` with `.presentationDetents([.height(280)])` applied via `.presentationDetents` on the wrapping sheet call site (not in this view itself).

---


# Item Detail Themed Shadow + Focus Border Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In the Add/Edit item sheet (`WishItemDetailView`), give the image box a soft theme-colored glow shadow, and give each of the 4 `TextField`s a theme-colored border that fades in while focused.

**Architecture:** All changes live inside `Wishie/Screens/Detail/WishItemDetailView.swift` — no new files, no view model changes. A new private `ViewModifier` (`FocusableFieldBackground`) replaces the repeated `.background(secondaryColor).clipShape(...)` tail on all 4 `TextField`s, driven by a new `@FocusState` enum. A `.shadow(...)` modifier is added to the image box in both of its existing branches, using the wishlist's `secondary` theme color.

**Tech Stack:** SwiftUI, existing `Color(hex:)` helper (`Wishie/Helper/ColorExtension.swift`), `GradientTheme` (`Wishie/Models/GradientWishlishTheme.swift`).

## Global Constraints

- No new automated tests: this file has zero unit-testable logic changes (pure SwiftUI view/style code — no view-model or service changes). Verification is a manual/simulated pass on the simulator, per this project's established convention for UI-only screens (see `docs/superpowers/plans/2026-07-15-wishlist-detail-bottom-sheet.md`'s Global Constraints).
- `GradientTheme` (`Wishie/Models/GradientWishlishTheme.swift`) only has `primary`, `secondary`, `imageName` — do not invent new theme fields.
- Image shadow uses `secondaryColor.opacity(0.4)`, `radius: 30`, `x: 0`, `y: 10` (soft glow, per approved spec).
- Focus border uses `primaryColor` for the stroke (`lineWidth: 2`), `secondaryColor` stays the field's fill — applied identically to all 4 fields (name, description, price, link), animated with `.easeInOut(duration: 0.2)`.
- Build/verify command: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'` (run from `/Users/nguyenkhanghuu/Wishie`).

---

### Task 1: Themed focus border on the 4 text fields

**Files:**
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:1-19` (add `FocusableFieldBackground` modifier + `DetailField` enum + `@FocusState`)
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:69-108` (the 4 `TextField`s)

**Interfaces:**
- Produces: `private enum DetailField: Hashable { case name, description, price, link }`, `@FocusState private var focusedField: DetailField?`, `private struct FocusableFieldBackground: ViewModifier`, `View.focusableFieldBackground(fillColor:borderColor:isFocused:cornerRadius:) -> some View` — used only within this file.
- Consumes: nothing from other tasks (Task 2 is independent).

- [ ] **Step 1: Add the focus enum, `@FocusState`, and the `FocusableFieldBackground` modifier**

In `Wishie/Screens/Detail/WishItemDetailView.swift`, add this right after the `import` statements (before `struct WishItemDetailView: View {` on line 4):

```swift
private enum DetailField: Hashable {
    case name, description, price, link
}

private struct FocusableFieldBackground: ViewModifier {
    let fillColor: Color
    let borderColor: Color
    let isFocused: Bool
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
                    .opacity(isFocused ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

private extension View {
    func focusableFieldBackground(fillColor: Color, borderColor: Color, isFocused: Bool) -> some View {
        modifier(FocusableFieldBackground(fillColor: fillColor, borderColor: borderColor, isFocused: isFocused))
    }
}
```

Then add the `@FocusState` property inside `WishItemDetailView`, right after `@State private var keyboardHeight: CGFloat = 0` (line 8):

```swift
    @FocusState private var focusedField: DetailField?
```

- [ ] **Step 2: Replace the name field's background/clipShape with the focus modifier**

Change (`WishItemDetailView.swift:69-76`):

```swift
                TextField("Item name", text: $viewModel.newItemName)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(secondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

to:

```swift
                TextField("Item name", text: $viewModel.newItemName)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .name)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .name)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

- [ ] **Step 3: Replace the description field's background/clipShape with the focus modifier**

Change (`WishItemDetailView.swift:78-87`):

```swift
                TextField("About this item...", text: $viewModel.newItemDescription, axis: .vertical)
                    .font(.wishies(.italic, 14))
                    .lineLimit(2...4)
                    .frame(height: 74, alignment: .topLeading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(secondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

to:

```swift
                TextField("About this item...", text: $viewModel.newItemDescription, axis: .vertical)
                    .font(.wishies(.italic, 14))
                    .lineLimit(2...4)
                    .frame(height: 74, alignment: .topLeading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .description)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .description)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

- [ ] **Step 4: Replace the price field's background/clipShape with the focus modifier**

Change (`WishItemDetailView.swift:89-96`):

```swift
                TextField("Item's price", text: $viewModel.newItemPrice)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(secondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

to:

```swift
                TextField("Item's price", text: $viewModel.newItemPrice)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .price)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .price)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

- [ ] **Step 5: Replace the link field's background/clipShape with the focus modifier**

Change (`WishItemDetailView.swift:98-108`):

```swift
                TextField("Paste product link", text: $viewModel.newItemLink)
                    .font(.wishies(.regular, 15))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(secondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

to:

```swift
                TextField("Paste product link", text: $viewModel.newItemLink)
                    .font(.wishies(.regular, 15))
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .link)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .link)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

- [ ] **Step 6: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Manual check**

Run the app on the iPhone 16 Pro simulator, open the Add/Edit item sheet for any wishlist item. Tap into the "Item name" field: confirm a themed (primary-color) border fades in smoothly around just that field. Tap into "About this item...", then "Item's price", then "Paste product link" in turn: confirm the border fades out of the previous field and fades into the newly-focused one each time, with no border visible on unfocused fields. Tap outside all fields to dismiss the keyboard: confirm no field shows a border.

- [ ] **Step 8: Commit**

```bash
git add Wishie/Screens/Detail/WishItemDetailView.swift
git commit -m "Add themed focus border to item detail text fields"
```

---

### Task 2: Themed glow shadow behind the image box

**Files:**
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:37-68` (both image-box branches)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Add the shadow to the remote-image branch**

Change (`WishItemDetailView.swift:37-41`):

```swift
                if isEdit && viewModel.itemSelected.localImage == nil {
                    WishieWebImage(url: viewModel.newItemRemoteImageUrl ?? "", contentMode: .fit)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.bottom, 20)
```

to:

```swift
                if isEdit && viewModel.itemSelected.localImage == nil {
                    WishieWebImage(url: viewModel.newItemRemoteImageUrl ?? "", contentMode: .fit)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: secondaryColor.opacity(0.4), radius: 30, x: 0, y: 10)
                        .padding(.bottom, 20)
```

- [ ] **Step 2: Add the shadow to the `ImagePickerBox` branch**

Change (`WishItemDetailView.swift:43-68`):

```swift
                } else {
                    ImagePickerBox(height: 160, selectedImage: $viewModel.newItemImage) {
                        ZStack {
                            if let image = viewModel.newItemImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                VStack(spacing: 8) {
                                    Image("upload")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                    Text("Add photo")
                                        .font(.wishies(.regular, 14))
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(Color.wishiePink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
```

to:

```swift
                } else {
                    ImagePickerBox(height: 160, selectedImage: $viewModel.newItemImage) {
                        ZStack {
                            if let image = viewModel.newItemImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                VStack(spacing: 8) {
                                    Image("upload")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 32, height: 32)
                                    Text("Add photo")
                                        .font(.wishies(.regular, 14))
                                        .foregroundStyle(.black)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .background(Color.wishiePink)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: secondaryColor.opacity(0.4), radius: 30, x: 0, y: 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
```

- [ ] **Step 3: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Manual check**

Open the Add item sheet (empty state, `ImagePickerBox` branch): confirm a soft theme-colored glow appears behind the image placeholder box. Open the Edit item sheet for an item with an existing remote image: confirm the same soft glow appears behind the loaded image. Pick a local photo via the picker: confirm the glow still shows behind the newly-picked image. Switch to a wishlist with a different theme (if available) and reopen the sheet: confirm the glow color changes to match that wishlist's `secondary` theme color.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/Detail/WishItemDetailView.swift
git commit -m "Add themed glow shadow behind item detail image box"
```

---

### Task 3: Full manual verification pass

**Files:** none (verification only).

- [ ] **Step 1: Build for the simulator**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Install and launch on the simulator, then walk through every state**

Using the already-booted "iPhone 16 Pro" simulator (or boot it via `xcrun simctl boot "iPhone 16 Pro"` if needed), install and launch the app, sign in, and open a wishlist, then confirm:

- Tap "+" to add a new item: image picker box shows a themed glow shadow; tapping into each of the 4 fields (name, description, price, link) shows a themed border fading in/out as focus moves between fields.
- Fill in a name and save: item is added successfully (Save button behavior unchanged).
- Edit an existing item with a remote image: the loaded image shows the themed glow shadow; editing text fields shows the same focus-border behavior; Save persists the changes (existing behavior unchanged).
- Dismiss the keyboard by tapping outside the fields: keyboard dismisses (existing `.onTapGesture { hideKeyboard() }` behavior unchanged) and no field shows a border.
- Switch between two wishlists with different themes and open each one's Add/Edit item sheet: confirm both the glow shadow and the focus border colors change accordingly, tracking `secondary`/`primary` per wishlist.

- [ ] **Step 3: Confirm no leftover unstyled background calls remain**

Run: `grep -n "background(secondaryColor)" Wishie/Screens/Detail/WishItemDetailView.swift`
Expected: no output (all 4 fields now use `.focusableFieldBackground(...)` instead of a bare `.background(secondaryColor)`).

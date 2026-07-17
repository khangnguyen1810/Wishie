# Item Detail Field Labels + Shadow Contrast Tuning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In `WishItemDetailView`, make the image glow shadow (added in a prior plan) visible against every theme's `primaryColor` background, and add a small caption label (`TITLE`/`DESCRIPTION`/`PRICE`/`LINK`) above each of the 4 fields, matching the original mockup.

**Architecture:** Both changes live entirely inside `Wishie/Screens/Detail/WishItemDetailView.swift` — no new files, no view model changes. Task 1 tunes an existing `.shadow(...)` value already shipped in commit `68eb004`. Task 2 adds one static `Text` caption directly above each `TextField`, reusing the existing `#8C7A5A` brown accent already present in `Wishie/Screens/Detail/WishlistDetailScreen.swift`.

**Tech Stack:** SwiftUI, existing `Color(hex:)` helper (`Wishie/Helper/ColorExtension.swift`), `Font.wishies` (`Wishie/Resources/WishieCustomFont.swift`).

## Global Constraints

- Shadow color/radius/offset stay `secondaryColor` / `radius: 30` / `x: 0` / `y: 10` — only the opacity value changes, from `0.4` to `0.65`, in both image-box branches.
- Caption labels are fixed-color, theme-independent: `Color(hex: "#8C7A5A")` (already used in `Wishie/Screens/Detail/WishlistDetailScreen.swift:419,527` — reuse the same literal, don't invent a new hex or a named `Color` extension for it).
- Caption label text is exactly `"TITLE"`, `"DESCRIPTION"`, `"PRICE"`, `"LINK"` (literal capitalized strings, no `.textCase(.uppercase)` — this codebase has no `.textCase` precedent).
- Caption label font is `.wishies(.bold, 12)`.
- No new theme fields — `GradientTheme` (`Wishie/Models/GradientWishlishTheme.swift`) still only has `primary`, `secondary`, `imageName`.
- No unit tests: pure SwiftUI view/style code, no logic changes. This environment cannot launch the iOS Simulator interactively (sandbox restriction) — implementers verify via `xcodebuild build` success only; visual/simulator confirmation is deferred to the user.
- Build/verify command: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'` (run from `/Users/nguyenkhanghuu/Wishie`).

---

### Task 1: Increase image shadow opacity for contrast

**Files:**
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:71` (remote-image branch shadow)
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:96` (`ImagePickerBox` branch shadow)

**Interfaces:**
- Consumes: nothing from other tasks (Task 2 is independent — different lines).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Bump the remote-image branch's shadow opacity**

Change (`WishItemDetailView.swift:71`):

```swift
                        .shadow(color: secondaryColor.opacity(0.4), radius: 30, x: 0, y: 10)
```

to:

```swift
                        .shadow(color: secondaryColor.opacity(0.65), radius: 30, x: 0, y: 10)
```

(This line sits inside the `if isEdit && viewModel.itemSelected.localImage == nil { WishieWebImage(...) ... }` branch.)

- [ ] **Step 2: Bump the `ImagePickerBox` branch's shadow opacity**

Change (`WishItemDetailView.swift:96`):

```swift
                        .shadow(color: secondaryColor.opacity(0.4), radius: 30, x: 0, y: 10)
```

to:

```swift
                        .shadow(color: secondaryColor.opacity(0.65), radius: 30, x: 0, y: 10)
```

(This line sits inside the `ImagePickerBox { ... }` trailing closure, right after `.clipShape(RoundedRectangle(cornerRadius: 12))`.)

- [ ] **Step 3: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Manual check**

Open the Add/Edit item sheet on a wishlist using the `purpleDream` theme: confirm the glow behind the image box now reads as a visibly distinct purple ring against the lighter `primaryColor` sheet background, not a barely-visible smudge. Check one other theme (e.g. `sunset` or `ocean`) too: confirm the glow is still soft/appropriate, not overpowering.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/Detail/WishItemDetailView.swift
git commit -m "Increase item detail image shadow opacity for contrast"
```

---

### Task 2: Add TITLE/DESCRIPTION/PRICE/LINK caption labels

**Files:**
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:101` (before the name field)
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:110` (before the description field, line number shifts after Step 1 of this task — see below)
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:121` (before the price field, shifts further)
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:130` (before the link field, shifts further)

**Interfaces:**
- Consumes: nothing from Task 1 (different, non-overlapping lines — Task 1 touches lines 71/96, this task touches lines 101-140, no shared lines).
- Produces: nothing consumed by later tasks.

Apply the 4 edits in file order (top to bottom) so each edit's line numbers are still valid when you reach it — each inserted label shifts every following line down by a fixed number of lines, so re-locate each block by its surrounding code (shown below) rather than by absolute line number if in doubt.

- [ ] **Step 1: Add the `TITLE` label above the name field**

Change (`WishItemDetailView.swift:101-108`):

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

to:

```swift
                Text("TITLE")
                    .font(.wishies(.bold, 12))
                    .foregroundStyle(Color(hex: "#8C7A5A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                TextField("Item name", text: $viewModel.newItemName)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .name)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .name)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

- [ ] **Step 2: Add the `DESCRIPTION` label above the description field**

Change:

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

to:

```swift
                Text("DESCRIPTION")
                    .font(.wishies(.bold, 12))
                    .foregroundStyle(Color(hex: "#8C7A5A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
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

- [ ] **Step 3: Add the `PRICE` label above the price field**

Change:

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

to:

```swift
                Text("PRICE")
                    .font(.wishies(.bold, 12))
                    .foregroundStyle(Color(hex: "#8C7A5A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
                TextField("Item's price", text: $viewModel.newItemPrice)
                    .font(.wishies(.bold, 17))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .focused($focusedField, equals: .price)
                    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .price)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
```

- [ ] **Step 4: Add the `LINK` label above the link field**

Change:

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

to:

```swift
                Text("LINK")
                    .font(.wishies(.bold, 12))
                    .foregroundStyle(Color(hex: "#8C7A5A"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 6)
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

- [ ] **Step 5: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Manual check**

Open the Add/Edit item sheet: confirm `TITLE`, `DESCRIPTION`, `PRICE`, `LINK` each appear as a small bold brown caption directly above their respective field, left-aligned with the field's edge, in that top-to-bottom order. Confirm the labels look the same regardless of which wishlist theme is active (they're a fixed color, not theme-driven). Confirm no field's focus border or background styling (from the prior plan) changed — labels are purely additive, positioned above each field, not overlapping it.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/Detail/WishItemDetailView.swift
git commit -m "Add TITLE/DESCRIPTION/PRICE/LINK caption labels to item detail fields"
```

---

### Task 3: Full manual verification pass

**Files:** none (verification only).

- [ ] **Step 1: Build for the simulator**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Install and launch on the simulator, then walk through every state**

Using the already-booted "iPhone 16 Pro" simulator (or boot it via `xcrun simctl boot "iPhone 16 Pro"` if needed), install and launch the app, sign in, and open a wishlist on the `purpleDream` theme, then confirm:

- Tap "+" to add a new item: image picker box shows a clearly visible themed glow shadow (not blended into the sheet background); each of the 4 fields shows its `TITLE`/`DESCRIPTION`/`PRICE`/`LINK` caption above it; tapping into each field still shows the themed focus border fading in/out correctly (from the prior plan, unaffected by this one).
- Edit an existing item with a remote image: the loaded image shows the same visible glow; captions and focus borders behave the same as the Add flow.
- Switch to a wishlist on a different theme (e.g. `sunset`): confirm the shadow is still clearly visible and the captions are unchanged (fixed brown, not theme-tinted).
- Fill in a name and Save / edit and Save: existing save behavior is unaffected (this plan only touches visual styling).

- [ ] **Step 3: Confirm the shadow opacity value landed correctly everywhere**

Run: `grep -n "secondaryColor.opacity" Wishie/Screens/Detail/WishItemDetailView.swift`
Expected: both matches show `secondaryColor.opacity(0.65)` — no leftover `0.4`.

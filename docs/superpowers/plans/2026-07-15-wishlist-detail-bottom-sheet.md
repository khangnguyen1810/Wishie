# Wishlist Detail Bottom Sheet Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the item bottom sheet in `WishlistDetailScreen` (white shell with drag handle + close button, restyled item row with a "picked" status pill, a circular icon action row replacing the stacked text-pill buttons, and a full-width capsule CTA for Delete/Reserve), and give the "Most Desired" action a custom star icon.

**Architecture:** All changes live inside `Wishie/Screens/Detail/WishlistDetailScreen.swift` — no new files, no view model or service changes. The existing `@ViewBuilder` button functions (`editButton`, `markDesireButton`, `linkButton`, `reserveButton`, `deleteButton`, `bottomSheetButton`) are replaced by new `@ViewBuilder` functions (`itemContentRow`, `pickedStatusPill`, `ownerActionsRow`, `nonOwnerActionsRow`, `iconActionButton`, `deleteCTAButton`, `reserveCTAButton`) called from a restyled `bottomSheet()`. A new `SheetHeightPreferenceKey` measures content height so `.presentationDetents` can size the sheet dynamically instead of the current fixed `.fraction(0.4)`. One new image asset (`most_desired_icon`, imported from the user's `star_icon.pdf`) is added following the exact pattern of the existing `edit_icon`/`back_icon` template-rendered PDF/SVG assets.

**Tech Stack:** SwiftUI, SDWebImageSwiftUI (`WebImage`), DotLottie, existing `Font.wishies`/`Color(hex:)`/`.lightened(by:)` helpers.

## Global Constraints

- No new automated tests: this file has zero unit-testable logic changes (the "picked by you" check is a one-line comparison of existing `WishlistItem.pickedUserId` against the current user id, already covered by the model — nothing new to unit-test). Verification is a manual/simulated pass on the simulator, per this project's established convention for UI-only screens (see `docs/superpowers/plans/2026-07-13-home-card-actions.md`'s Global Constraints).
- `WishieFont` (in `Wishie/Resources/WishieCustomFont.swift`) only has `.regular`, `.medium`, `.bold`, `.light`, `.italic` — there is no `.semibold`. Use `.medium` wherever the design calls for a mid-weight label.
- Current-user id is read via `UserDefaults.standard.string(forKey: WishieConstants.userIdKey)` (`WishieConstants.userIdKey == "userid"`) — the same lookup `WishlistModel.isOwner()`/`isUserJoined()` already use. Do not introduce a different mechanism.
- All existing tap behaviors (edit, mark/unmark most desired incl. the replace-confirmation path, open link, delete incl. disabled-when-picked, reserve incl. disabled-when-picked) must call the exact same `viewModel` methods with the exact same guards as today — this is a visual restyle, not a behavior change.
- Build/verify command: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'` (run from `/Users/nguyenkhanghuu/Wishie`).

---

### Task 1: Add the "Most Desired" star icon asset

**Files:**
- Create: `Wishie/Resources/Assets.xcassets/most_desired_icon.imageset/Contents.json`
- Create: `Wishie/Resources/Assets.xcassets/most_desired_icon.imageset/most_desired_icon.pdf` (copy of `/Users/nguyenkhanghuu/Downloads/star_icon.pdf`)

**Interfaces:**
- Produces: `Image("most_desired_icon")` — a template-rendered (tintable) image asset usable anywhere in the app, same as `Image("edit_icon")` today.

- [ ] **Step 1: Create the imageset directory and copy the PDF**

```bash
mkdir -p "Wishie/Resources/Assets.xcassets/most_desired_icon.imageset"
cp "/Users/nguyenkhanghuu/Downloads/star_icon.pdf" "Wishie/Resources/Assets.xcassets/most_desired_icon.imageset/most_desired_icon.pdf"
```

- [ ] **Step 2: Write `Contents.json`**

Create `Wishie/Resources/Assets.xcassets/most_desired_icon.imageset/Contents.json` with exactly the same shape as the existing `back_icon.imageset/Contents.json` (single universal PDF entry, template rendering intent):

```json
{
  "images" : [
    {
      "filename" : "most_desired_icon.pdf",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
```

- [ ] **Step 3: Build to confirm the asset compiles**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **` (asset catalogs are validated as part of the build; a malformed `Contents.json` fails here with an `actool` error).

- [ ] **Step 4: Commit**

```bash
git add "Wishie/Resources/Assets.xcassets/most_desired_icon.imageset"
git commit -m "Add most_desired_icon template asset from star_icon.pdf"
```

---

### Task 2: Restyle the sheet shell (background, drag handle, close button, dynamic height)

**Files:**
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift:101-105` (the `.sheet(isPresented: $viewModel.showBottomSheet)` modifier)
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift:17` (`sheetHeight` state default)
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift:436-523` (`bottomSheet()` — shell only in this task; item content/buttons keep their current implementation for now, just moved inside the new shell)

**Interfaces:**
- Produces: file-scope `SheetHeightPreferenceKey: PreferenceKey` (`defaultValue: CGFloat = 0`), used by later tasks too.
- Consumes: nothing new from other tasks.

- [ ] **Step 1: Add the preference key**

In `Wishie/Screens/Detail/WishlistDetailScreen.swift`, add this right before `struct WishlistDetailScreen: View {` (after the imports, before line 12):

```swift
private struct SheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
```

- [ ] **Step 2: Give `sheetHeight` a sane initial value**

Change line 17 from:

```swift
    @State private var sheetHeight: CGFloat = .zero
```

to:

```swift
    @State private var sheetHeight: CGFloat = 480
```

(480 is a reasonable first-paint guess for this sheet's content so there's no zero-height flash before `GeometryReader` reports the real measured height.)

- [ ] **Step 3: Wire dynamic height + hidden system drag indicator into the `.sheet` modifier**

Change lines 101-105 from:

```swift
        .sheet(isPresented: $viewModel.showBottomSheet) {
            bottomSheet()
                .presentationDetents([.fraction(0.4)])
                .presentationDragIndicator(.visible)
        }
```

to:

```swift
        .sheet(isPresented: $viewModel.showBottomSheet) {
            bottomSheet()
                .onPreferenceChange(SheetHeightPreferenceKey.self) { height in
                    sheetHeight = height
                }
                .presentationDetents([.height(sheetHeight)])
                .presentationDragIndicator(.hidden)
        }
```

- [ ] **Step 4: Restyle `bottomSheet()`'s shell**

Replace the whole `bottomSheet()` function (lines 436-523) with (item content/buttons unchanged from today for this task — only the outer shell/background/handle/close button change; the inner `VStack(spacing: 15) { ... }` block keeps exactly the same children it has today, just re-indented one level under the new shell):

```swift
    @ViewBuilder
    func bottomSheet() -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(hex: "#E9DCC0"))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            HStack {
                Spacer()
                Button {
                    viewModel.showBottomSheet = false
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#F7F1E3"))
                            .frame(width: 30, height: 30)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#8C7A5A"))
                    }
                }
            }
            .padding(.top, 6)

            VStack(spacing: 15) {
                HStack {
                    ZStack {
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            WebImage(url: URL(string: viewModel.itemSelected.image ?? ""), content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            }, placeholder: {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        Color(hex: viewModel.wishlistInfo.theme.secondary)
                                    )
                                    .frame(
                                        width: UIScreen.main.bounds.width/4,
                                        height:  UIScreen.main.bounds.width/4
                                    )
                                    .overlay {
                                        DotLottieAnimation(
                                            fileName: "giftloading",
                                            config: AnimationConfig(autoplay: true, loop: true)
                                        )
                                        .view()
                                        .frame(width: 40)
                                    }
                            })
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                        }
                    }
                    VStack {
                        Text(viewModel.itemSelected.name)
                            .font(.wishies(.bold, 15))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(viewModel.itemSelected.description)
                            .font(.wishies(.regular, 15))
                            .foregroundStyle(.darkGrey)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("Price")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(.black)
                    Spacer()
                    if let price = viewModel.itemSelected.price, !price.isEmpty {
                        Text(price)
                            .font(.wishies(.bold, 15))
                            .foregroundStyle(.darkGrey)
                    }
                }
                Spacer()
                if wishlist?.isOwner() == true {
                    VStack {
                        HStack {
                            editButton()
                            markDesireButton()
                        }
                        linkButton()
                        deleteButton()
                    }
                } else {
                    VStack {
                        linkButton()
                        reserveButton()
                    }
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: SheetHeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .background(Color.white)
    }
```

- [ ] **Step 5: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Manual check**

Run the app on the iPhone 16 Pro simulator, open a wishlist you own, tap any item to open the bottom sheet. Confirm: sheet background is white (not theme-tinted), a small tan drag handle bar sits at the top, a light circular X button sits top-right and tapping it dismisses the sheet, and the sheet height fits the (still old-styled) content without visible clipping or excess empty space. Existing Edit/Mark Desired/Link/Delete (or Link/Reserve) buttons still work exactly as before.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/Detail/WishlistDetailScreen.swift
git commit -m "Restyle wishlist item bottom sheet shell: white background, drag handle, close button, dynamic height"
```

---

### Task 3: Restyle the item content row and add the "picked" status pill

**Files:**
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift` (inside `bottomSheet()`, the image/name/description/price block added in Task 2; add a new `currentUserId` computed property and a new `itemContentRow()` / `pickedStatusPill()` pair of `@ViewBuilder` functions)

**Interfaces:**
- Consumes: `SheetHeightPreferenceKey` (Task 2, unchanged usage).
- Produces: `itemContentRow() -> some View`, `pickedStatusPill() -> some View`, `currentUserId: String?` — used only within this file for now.

- [ ] **Step 1: Add `currentUserId`**

Add this computed property next to the existing `qrImage` computed property (after line 39, before `var wishlistId: String?`):

```swift
    var currentUserId: String? {
        UserDefaults.standard.string(forKey: WishieConstants.userIdKey)
    }
```

- [ ] **Step 2: Add `itemContentRow()` and `pickedStatusPill()`**

Add these two new `@ViewBuilder` functions right after `bottomSheet()`:

```swift
    @ViewBuilder
    func itemContentRow() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 84, height: 84)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        WebImage(url: URL(string: viewModel.itemSelected.image ?? ""), content: { image in
                            image
                                .resizable()
                                .scaledToFill()
                        }, placeholder: {
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(hex: viewModel.wishlistInfo.theme.secondary))
                                .frame(width: 84, height: 84)
                                .overlay {
                                    DotLottieAnimation(
                                        fileName: "giftloading",
                                        config: AnimationConfig(autoplay: true, loop: true)
                                    )
                                    .view()
                                    .frame(width: 40)
                                }
                        })
                        .frame(width: 84, height: 84)
                        .clipped()
                        .cornerRadius(18)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.itemSelected.name)
                        .font(.wishies(.bold, 19))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if let price = viewModel.itemSelected.price, !price.isEmpty {
                        Text(price)
                            .font(.wishies(.bold, 14))
                            .foregroundStyle(Color(hex: viewModel.wishlistInfo.theme.secondary))
                    }
                    if viewModel.itemSelected.isPicked {
                        pickedStatusPill()
                    }
                }
            }
            Text(viewModel.itemSelected.description)
                .font(.wishies(.regular, 13.5))
                .foregroundStyle(Color(hex: "#5B4A32"))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func pickedStatusPill() -> some View {
        let isPickedByMe = viewModel.itemSelected.pickedUserId == currentUserId
        let textColor = isPickedByMe ? Color(hex: "#1F8F89") : Color(hex: viewModel.wishlistInfo.theme.secondary)
        let backgroundColor = isPickedByMe ? Color(hex: "#EAFBF8") : Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.7)
        HStack(spacing: 6) {
            Text("🎁")
                .font(.system(size: 11))
            Text(isPickedByMe ? "Picked by you" : "Picked")
                .font(.wishies(.bold, 11.5))
                .foregroundStyle(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Capsule().fill(backgroundColor))
    }
```

- [ ] **Step 3: Swap the old image/name/description/price block for `itemContentRow()`**

Inside `bottomSheet()`, replace this whole block (added in Task 2 — the `HStack { ZStack { ... } VStack { Text(name)... Text(description)... } }.frame(maxWidth: .infinity, alignment: .leading)` followed by the `HStack { Text("Price")... }` block):

```swift
                HStack {
                    ZStack {
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            WebImage(url: URL(string: viewModel.itemSelected.image ?? ""), content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            }, placeholder: {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(
                                        Color(hex: viewModel.wishlistInfo.theme.secondary)
                                    )
                                    .frame(
                                        width: UIScreen.main.bounds.width/4,
                                        height:  UIScreen.main.bounds.width/4
                                    )
                                    .overlay {
                                        DotLottieAnimation(
                                            fileName: "giftloading",
                                            config: AnimationConfig(autoplay: true, loop: true)
                                        )
                                        .view()
                                        .frame(width: 40)
                                    }
                            })
                            .frame(width: 80, height: 80)
                            .clipped()
                            .cornerRadius(10)
                        }
                    }
                    VStack {
                        Text(viewModel.itemSelected.name)
                            .font(.wishies(.bold, 15))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(viewModel.itemSelected.description)
                            .font(.wishies(.regular, 15))
                            .foregroundStyle(.darkGrey)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)

                    }

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    Text("Price")
                        .font(.wishies(.bold, 15))
                        .foregroundStyle(.black)
                    Spacer()
                    if let price = viewModel.itemSelected.price, !price.isEmpty {
                        Text(price)
                            .font(.wishies(.bold, 15))
                            .foregroundStyle(.darkGrey)
                    }
                }
                Spacer()
```

with:

```swift
                itemContentRow()
                Rectangle()
                    .fill(Color(hex: "#EFE4C8"))
                    .frame(height: 1)
```

(The old standalone "Price" row is gone — price now lives inside `itemContentRow()` next to the name, matching the design. The old trailing `Spacer()` is replaced by the new divider, since the sheet is no longer a fixed-fraction height that needs a spacer to push buttons to the bottom.)

- [ ] **Step 4: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Manual check**

Open the bottom sheet for an unpicked item: confirm 84×84 image, bold name, price next to it (in the wishlist's accent color), description below, then a thin divider — and no status pill. Open it for an item you've picked yourself (as a non-owner joined member): confirm a teal "🎁 Picked by you" pill appears under the price. Open it for an item picked by someone else: confirm a themed "🎁 Picked" pill (not "by you").

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/Detail/WishlistDetailScreen.swift
git commit -m "Restyle bottom sheet item row with picked-status pill"
```

---

### Task 4: Replace the stacked buttons with the circular icon action row

**Files:**
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift` (remove `editButton()`, `markDesireButton()`, `linkButton()`; add `iconActionButton(...)`, `ownerActionsRow()`, `nonOwnerActionsRow()`; update the `if wishlist?.isOwner() == true { ... } else { ... }` block inside `bottomSheet()`)

**Interfaces:**
- Consumes: `itemContentRow()`/divider from Task 3 (unchanged).
- Produces: `iconActionButton(icon:isSystemIcon:label:isActive:action:) -> some View`, `ownerActionsRow() -> some View`, `nonOwnerActionsRow() -> some View` — `ownerActionsRow`/`nonOwnerActionsRow` are consumed by Task 5's edit to the owner/non-owner branch (this task already places them there).
- `reserveButton()` and `deleteButton()` are left in place for now (removed in Task 5) since the owner/non-owner branch still calls them.

- [ ] **Step 1: Add `iconActionButton`, `ownerActionsRow`, `nonOwnerActionsRow`**

Add these three new `@ViewBuilder` functions right after `pickedStatusPill()`:

```swift
    @ViewBuilder
    func iconActionButton(
        icon: String,
        isSystemIcon: Bool,
        label: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        isActive
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color(hex: "#FFD66B"), Color(hex: "#F3B23A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            : AnyShapeStyle(Color(hex: "#F7F1E3"))
                    )
                    .frame(width: 48, height: 48)
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "#5B4A32"))
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color(hex: "#5B4A32"))
                }
            }
            Text(label)
                .font(.wishies(.medium, 11.5))
                .foregroundStyle(Color(hex: "#5B4A32"))
        }
        .onTapGesture {
            action()
        }
    }

    @ViewBuilder
    func ownerActionsRow() -> some View {
        HStack {
            iconActionButton(
                icon: "most_desired_icon",
                isSystemIcon: false,
                label: "Most Desired",
                isActive: viewModel.itemSelected.isMostDesired
            ) {
                if viewModel.wouldReplaceMostDesired {
                    viewModel.showBottomSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showReplaceMostDesiredConfirmation = true
                    }
                    return
                }
                Task {
                    await viewModel.setDesired(
                        wishlistId: viewModel.wishlistInfo.id,
                        isDesired: !viewModel.itemSelected.isMostDesired
                    )
                    viewModel.showBottomSheet = false
                }
            }
            Spacer()
            iconActionButton(
                icon: "pencil",
                isSystemIcon: true,
                label: "Edit",
                isActive: false
            ) {
                let itemSelected = viewModel.itemSelected
                viewModel.newItemName = itemSelected.name
                viewModel.newItemRemoteImageUrl = itemSelected.image
                viewModel.newItemLink = itemSelected.itemLink
                viewModel.newItemDescription = itemSelected.description
                viewModel.newItemPrice = itemSelected.price ?? ""
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showEditItemSheet = true
                }
            }
            Spacer()
            iconActionButton(
                icon: "link",
                isSystemIcon: true,
                label: "Link",
                isActive: false
            ) {
                viewModel.openProductLink()
            }
        }
    }

    @ViewBuilder
    func nonOwnerActionsRow() -> some View {
        HStack {
            Spacer()
            iconActionButton(
                icon: "link",
                isSystemIcon: true,
                label: "Link",
                isActive: false
            ) {
                viewModel.openProductLink()
            }
            Spacer()
        }
    }
```

- [ ] **Step 2: Swap the owner/non-owner button stacks for the new action rows**

Inside `bottomSheet()`, replace:

```swift
                if wishlist?.isOwner() == true {
                    VStack {
                        HStack {
                            editButton()
                            markDesireButton()
                        }
                        linkButton()
                        deleteButton()
                    }
                } else {
                    VStack {
                        linkButton()
                        reserveButton()
                    }
                }
```

with:

```swift
                if wishlist?.isOwner() == true {
                    ownerActionsRow()
                    deleteButton()
                } else {
                    nonOwnerActionsRow()
                    reserveButton()
                }
```

- [ ] **Step 3: Remove `editButton()`, `markDesireButton()`, `linkButton()`**

Delete these three now-unused functions entirely (they're fully superseded by `ownerActionsRow()`/`nonOwnerActionsRow()`/`iconActionButton()`):

```swift
    @ViewBuilder
    func linkButton() -> some View {
        bottomSheetButton(
            title: "Link",
            fill: Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4),
            action:  {
                viewModel.openProductLink()
            }
        )
    }
```

```swift
    @ViewBuilder
    func markDesireButton() -> some View {
        bottomSheetButton(
            title: viewModel.itemSelected.isMostDesired ? "Remove most desired" : "Mark as Most Desired",
            fill: Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4)
        ) {
            if viewModel.wouldReplaceMostDesired {
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showReplaceMostDesiredConfirmation = true
                }
                return
            }
            Task {
                await viewModel.setDesired(
                    wishlistId: viewModel.wishlistInfo.id,
                    isDesired: !viewModel.itemSelected.isMostDesired
                )
                viewModel.showBottomSheet = false
            }
        }
    }
```

```swift
    @ViewBuilder
    func editButton() -> some View {
        Button {
            let itemSelected = viewModel.itemSelected
            viewModel.newItemName = itemSelected.name
            viewModel.newItemRemoteImageUrl = itemSelected.image
            viewModel.newItemLink = itemSelected.itemLink
            viewModel.newItemDescription = itemSelected.description
            viewModel.newItemPrice = itemSelected.price ?? ""
            viewModel.showBottomSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.showEditItemSheet = true
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: viewModel.wishlistInfo.theme.secondary).lightened(by: 0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                Text("Edit this item")
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
```

- [ ] **Step 4: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **` (note: `reserveButton()`/`deleteButton()`/`bottomSheetButton()` still exist and are still used here, so no dangling references yet — Task 5 removes them.)

- [ ] **Step 5: Manual check**

Owner view: confirm three circular icon buttons (Most Desired / Edit / Link) with labels underneath, Most Desired shows a gold circle when the item is already most-desired and a neutral beige circle otherwise, tapping Edit opens the edit sheet pre-filled, tapping Link opens the product URL, tapping Most Desired toggles it (and shows the replace-confirmation dialog when another item is already most-desired). Non-owner view: confirm a single centered Link icon button that opens the product URL.

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/Detail/WishlistDetailScreen.swift
git commit -m "Replace bottom sheet text-pill buttons with circular icon action row"
```

---

### Task 5: Replace Delete/Reserve with the full-width capsule CTA

**Files:**
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift` (remove `reserveButton()`, `deleteButton()`, `bottomSheetButton(title:fill:action:)`; add `deleteCTAButton()`, `reserveCTAButton()`; update the two call sites from Task 4)

**Interfaces:**
- Consumes: `ownerActionsRow()`/`nonOwnerActionsRow()` call sites from Task 4.
- Produces: `deleteCTAButton() -> some View`, `reserveCTAButton() -> some View`.

- [ ] **Step 1: Add `deleteCTAButton()` and `reserveCTAButton()`**

Add these two new `@ViewBuilder` functions right after `nonOwnerActionsRow()`:

```swift
    @ViewBuilder
    func deleteCTAButton() -> some View {
        let isDisabled = viewModel.itemSelected.isPicked
        HStack(spacing: 8) {
            Image(systemName: "trash")
                .font(.system(size: 15, weight: .semibold))
            Text("Delete item")
                .font(.wishies(.bold, 14.5))
        }
        .foregroundStyle(isDisabled ? Color.darkGrey : Color(hex: "#D9375A"))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .background(
            Capsule().fill(isDisabled ? Color.lightGrey : Color(hex: "#FFECEF"))
        )
        .onTapGesture {
            guard !isDisabled else { return }
            viewModel.showBottomSheet = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.showDeleteConfirmation = true
            }
        }
    }

    @ViewBuilder
    func reserveCTAButton() -> some View {
        let isDisabled = viewModel.itemSelected.isPicked
        Text("Reserve")
            .font(.wishies(.bold, 14.5))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                Capsule().fill(isDisabled ? Color.lightGrey : Color.wishiePink)
            )
            .onTapGesture {
                guard !isDisabled else { return }
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showReserveConfirmation = true
                }
            }
    }
```

- [ ] **Step 2: Swap the call sites**

Inside `bottomSheet()`, replace:

```swift
                if wishlist?.isOwner() == true {
                    ownerActionsRow()
                    deleteButton()
                } else {
                    nonOwnerActionsRow()
                    reserveButton()
                }
```

with:

```swift
                if wishlist?.isOwner() == true {
                    ownerActionsRow()
                    deleteCTAButton()
                } else {
                    nonOwnerActionsRow()
                    reserveCTAButton()
                }
```

- [ ] **Step 3: Remove `reserveButton()`, `deleteButton()`, `bottomSheetButton(title:fill:action:)`**

Delete these three now-fully-unused functions:

```swift
    @ViewBuilder
    func reserveButton() -> some View {
        bottomSheetButton(
            title: "Reserve",
            fill: viewModel.itemSelected.isPicked ? .lightGrey : .wishiePink
        ) {
            if !viewModel.itemSelected.isPicked {
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showReserveConfirmation = true
                }
            }
        }
    }
```

```swift
    @ViewBuilder
    func deleteButton() -> some View {
        bottomSheetButton(
            title: "Delete",
            fill: viewModel.itemSelected.isPicked ? .lightGrey : .wishiePink
        ) {
            if !viewModel.itemSelected.isPicked {
                viewModel.showBottomSheet = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    viewModel.showDeleteConfirmation = true
                }
            }
        }
        .disabled(viewModel.itemSelected.isPicked)
    }
```

```swift
    @ViewBuilder
    func bottomSheetButton(
        title: String,
        fill: Color,
        action: @escaping () -> Void
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(fill)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
            Text(title)
                .font(.wishies(.bold, 15))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onTapGesture {
            action()
        }
    }
```

- [ ] **Step 4: Build**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Manual check**

Owner view, unpicked item: confirm a full-width light-red "Delete item" capsule with a trash icon; tapping it closes the sheet and opens the delete confirmation dialog; confirming deletes the item. Owner view, picked item: confirm the capsule is greyed out and tapping it does nothing. Non-owner view, unreserved item: confirm a full-width pink "Reserve" capsule; tapping it closes the sheet and opens the reserve confirmation dialog; confirming reserves the item. Non-owner view, already-picked item: confirm the capsule is greyed out and tapping it does nothing.

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/Detail/WishlistDetailScreen.swift
git commit -m "Replace bottom sheet Delete/Reserve buttons with full-width capsule CTA"
```

---

### Task 6: Full manual verification pass

**Files:** none (verification only).

- [ ] **Step 1: Build for the simulator**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 2: Install and launch on the simulator, then walk through every state**

Using the already-booted "iPhone 16 Pro" simulator (or boot it via `xcrun simctl boot "iPhone 16 Pro"` if needed), install and launch the app, sign in, and open a wishlist you own with at least one unpicked and one picked item (pick one item from a second test account, or use existing seed data), then confirm:

- Owner view, unpicked item: icon row shows Most Desired (neutral beige) / Edit / Link; "Delete item" capsule is enabled (red).
- Owner view, picked-by-someone-else item: status pill reads "Picked", not "Picked by you"; "Delete item" capsule is disabled (grey) and tapping it does nothing.
- Tapping Most Desired on an item that isn't currently most-desired, when another item already is: shows the "Replace most desired?" confirmation dialog; confirming swaps which item shows the gold Most Desired circle.
- Tapping Most Desired when no other item is most-desired: toggles directly, no confirmation dialog.
- Tapping Edit: opens the edit sheet pre-filled with the item's current name/description/price/link/image.
- Tapping Link on an item with a valid URL: opens it in Safari/in-app browser. On an item with no/invalid link: closes the sheet and shows the "Not have a link" dialog.
- Non-owner view (join a wishlist with a second account, or a test wishlist where you're a member, not owner), unreserved item: icon row shows only a centered Link button; "Reserve" capsule is enabled (pink).
- Non-owner view, an item you reserved yourself: status pill reads "Picked by you"; "Reserve" capsule is disabled (grey).
- Non-owner view, an item reserved by someone else: status pill reads "Picked"; "Reserve" capsule is disabled (grey).
- Tapping Reserve: shows the "Reserve this gift?" confirmation dialog; confirming marks the item picked.
- The close (X) button dismisses the sheet; swiping down also still dismisses it.
- Open an item with a long description (several lines): confirm the sheet grows to fit it with no clipped/cut-off text, and no excessive empty space on short descriptions.

- [ ] **Step 3: Confirm no dead code remains**

Run: `grep -n "bottomSheetButton\|func editButton\|func markDesireButton\|func linkButton\b" Wishie/Screens/Detail/WishlistDetailScreen.swift`
Expected: no output (all four old helpers were removed in Tasks 4–5).

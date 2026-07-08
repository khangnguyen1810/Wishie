# Fredoka Font Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace WorkSans with Fredoka as the app's font family.

**Architecture:** The app funnels all custom-font usage through one enum
(`WishieFont`) and one helper (`Font.wishies(_:_:)`) in
`Wishie/Resources/WishieCustomFont.swift`. Swapping the enum's raw values
from WorkSans to Fredoka PostScript names, plus updating the `UIAppFonts`
list in `Info.plist`, repoints every one of the app's 153 call sites at
Fredoka with zero per-call-site changes — except the 5 sites using the
`.italic` case, which must be migrated since Fredoka has no italic variant.

**Tech Stack:** SwiftUI, Xcode 16 (file-system-synchronized project groups —
files placed in `Wishie/Resources/Fonts/` are automatically part of the
build target; no `.pbxproj` edits needed to add or remove font files).

## Global Constraints

- The `WishieFont` enum must expose exactly these 4 cases, mapped to these
  exact PostScript names (verified from each `.ttf`'s internal `name`
  table): `regular` → `"Fredoka-Regular"`, `medium` → `"Fredoka-Medium"`,
  `bold` → `"Fredoka-Bold"`, `light` → `"Fredoka-Light"`.
- No `.italic` case. Italic call sites use `.wishies(.regular, size).italic()`
  (SwiftUI synthetic slant) instead.
- The `Font.wishies(_:_:)` function signature does not change.
- `Info.plist`'s `UIAppFonts` array must list exactly the 4 Fredoka
  filenames, nothing else.
- No visual/size changes beyond the typeface swap — don't touch font sizes
  or which weight is used at any call site other than the 5 italic sites.
- Old WorkSans `.ttf` files must be deleted once nothing references them.

---

### Task 1: Swap the font enum, Info.plist registration, and migrate italic call sites

**Files:**
- Modify: `Wishie/Resources/WishieCustomFont.swift`
- Modify: `Wishie/Info.plist`
- Modify: `Wishie/Screens/Auth/LoginView.swift:115`
- Modify: `Wishie/Screens/Auth/SignUpView.swift:146`
- Modify: `Wishie/Screens/Home/HomeItemViewCell.swift:92`
- Modify: `Wishie/Screens/CreateList/CreateWishlistPage2.swift:138`
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:79`
- Track (already on disk, untracked by git): `Wishie/Resources/Fonts/Fredoka-Regular.ttf`,
  `Wishie/Resources/Fonts/Fredoka-Medium.ttf`, `Wishie/Resources/Fonts/Fredoka-Bold.ttf`,
  `Wishie/Resources/Fonts/Fredoka-Light.ttf`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `enum WishieFont: String { case regular, medium, bold, light }`
  and `static func Font.wishies(_ weight: WishieFont, _ size: CGFloat) -> Font`,
  used by all subsequent tasks and by the 148 untouched call sites elsewhere
  in the app.

This task must be done as one unit: removing the `.italic` case from the
enum and fixing its 5 call sites in the same commit keeps the build green at
every commit (removing `.italic` without fixing the call sites would not
compile).

- [ ] **Step 1: Update the font enum**

Replace the full contents of `Wishie/Resources/WishieCustomFont.swift`:

```swift
//
//  WishieCustomFont.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import Foundation
import SwiftUI
enum WishieFont: String {
    case regular = "Fredoka-Regular"
    case medium = "Fredoka-Medium"
    case bold = "Fredoka-Bold"
    case light = "Fredoka-Light"
}

extension Font {
    static func wishies(_ weight: WishieFont, _ size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}
```

- [ ] **Step 2: Update `Info.plist` font registration**

In `Wishie/Info.plist`, find the `UIAppFonts` array:

```xml
	<key>UIAppFonts</key>
	<array>
		<string>WorkSans-Regular.ttf</string>
		<string>WorkSans-Light.ttf</string>
		<string>WorkSans-Italic.ttf</string>
		<string>WorkSans-Bold.ttf</string>
	</array>
```

Replace it with:

```xml
	<key>UIAppFonts</key>
	<array>
		<string>Fredoka-Regular.ttf</string>
		<string>Fredoka-Medium.ttf</string>
		<string>Fredoka-Bold.ttf</string>
		<string>Fredoka-Light.ttf</string>
	</array>
```

- [ ] **Step 3: Migrate the 5 `.italic` call sites**

In `Wishie/Screens/Auth/LoginView.swift:115`, change:

```swift
                    .font(.wishies(.italic, 15))
```

to:

```swift
                    .font(.wishies(.regular, 15).italic())
```

In `Wishie/Screens/Auth/SignUpView.swift:146`, change:

```swift
                    .font(.wishies(.italic, 15))
```

to:

```swift
                    .font(.wishies(.regular, 15).italic())
```

In `Wishie/Screens/Home/HomeItemViewCell.swift:92`, change:

```swift
                    .font(.wishies(.italic, 13))
```

to:

```swift
                    .font(.wishies(.regular, 13).italic())
```

In `Wishie/Screens/CreateList/CreateWishlistPage2.swift:138`, change:

```swift
                    .font(.wishies(.italic, 14))
```

to:

```swift
                    .font(.wishies(.regular, 14).italic())
```

In `Wishie/Screens/Detail/WishItemDetailView.swift:79`, change:

```swift
                    .font(.wishies(.italic, 14))
```

to:

```swift
                    .font(.wishies(.regular, 14).italic())
```

- [ ] **Step 4: Verify no other `.italic` references remain**

Run: `grep -rn "\.wishies(\.italic" --include="*.swift" Wishie/`
Expected: no output (empty result).

- [ ] **Step 5: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`, with no compiler errors referencing
`WishieFont` or `.italic`.

- [ ] **Step 6: Commit**

The four Fredoka `.ttf` files already sit in `Wishie/Resources/Fonts/` but
are untracked (`git status` shows them as untracked files) — stage them
alongside the code changes so the new font assets actually ship with the
commit:

```bash
git add Wishie/Resources/WishieCustomFont.swift Wishie/Info.plist \
  Wishie/Resources/Fonts/Fredoka-Regular.ttf \
  Wishie/Resources/Fonts/Fredoka-Medium.ttf \
  Wishie/Resources/Fonts/Fredoka-Bold.ttf \
  Wishie/Resources/Fonts/Fredoka-Light.ttf \
  Wishie/Screens/Auth/LoginView.swift Wishie/Screens/Auth/SignUpView.swift \
  Wishie/Screens/Home/HomeItemViewCell.swift \
  Wishie/Screens/CreateList/CreateWishlistPage2.swift \
  Wishie/Screens/Detail/WishItemDetailView.swift
git commit -m "feat: swap WorkSans for Fredoka font family"
```

---

### Task 2: Remove the old WorkSans font files

**Files:**
- Delete: `Wishie/Resources/Fonts/WorkSans-Regular.ttf`
- Delete: `Wishie/Resources/Fonts/WorkSans-Light.ttf`
- Delete: `Wishie/Resources/Fonts/WorkSans-Italic.ttf`
- Delete: `Wishie/Resources/Fonts/WorkSans-Bold.ttf`

**Interfaces:**
- Consumes: nothing from Task 1's code changes directly, but must run
  after Task 1 since that's what removes the last references to WorkSans.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Confirm nothing references WorkSans anymore**

Run: `grep -rln "WorkSans" --include="*.swift" --include="*.plist" Wishie/`
Expected: no output (empty result). If anything shows up, stop — Task 1 was
incomplete.

- [ ] **Step 2: Delete the WorkSans font files**

```bash
git rm Wishie/Resources/Fonts/WorkSans-Regular.ttf \
  Wishie/Resources/Fonts/WorkSans-Light.ttf \
  Wishie/Resources/Fonts/WorkSans-Italic.ttf \
  Wishie/Resources/Fonts/WorkSans-Bold.ttf
```

- [ ] **Step 3: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`. Since the project uses file-system
synchronized groups, deleting the files is enough — there's no stale
`.pbxproj` reference to clean up.

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove unused WorkSans font files"
```

---

### Task 3: Manual verification on simulator

**Files:** none (verification only).

**Interfaces:**
- Consumes: the fully built app from Tasks 1–2.
- Produces: nothing (terminal task).

- [ ] **Step 1: Boot the simulator and install the app**

```bash
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null || true
xcodebuild -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -derivedDataPath /tmp/wishie-build build 2>&1 | tail -20
open -a Simulator
xcrun simctl install "iPhone 16 Pro" \
  /tmp/wishie-build/Build/Products/Debug-iphonesimulator/Wishie.app
xcrun simctl launch "iPhone 16 Pro" $(defaults read \
  /tmp/wishie-build/Build/Products/Debug-iphonesimulator/Wishie.app/Info.plist \
  CFBundleIdentifier)
```

- [ ] **Step 2: Check console for missing-font warnings**

Run: `xcrun simctl spawn "iPhone 16 Pro" log stream --level debug --predicate 'processImagePath contains "Wishie"' &`
then watch for ~10 seconds while the app is running, then stop it (Ctrl-C).
Expected: no messages containing `CTFontManager` font-registration errors or
warnings about failing to load a font named `Fredoka-*`.

- [ ] **Step 3: Visually spot-check screens**

In the running simulator, navigate to: Welcome screen, Home screen,
Login screen (check the italic subtitle at `LoginView.swift:115` renders
slanted), Sign Up screen, and a Wish Item Detail screen. Confirm all visible
text renders in Fredoka (rounded, geometric letterforms) rather than
falling back to the system font (San Francisco).

Expected: all text uses Fredoka; the migrated italic sites show a visible
slant.

- [ ] **Step 4: Report result**

If everything renders correctly, this task is done — no commit needed (no
files changed in this task).

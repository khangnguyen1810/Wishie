# Nunito Font Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Fredoka with Nunito as the app's font family, restoring a real `.italic` case backed by `Nunito-Italic.ttf`.

**Architecture:** All custom-font usage funnels through one enum (`WishieFont`) and one helper (`Font.wishies(_:_:)`) in `Wishie/Resources/WishieCustomFont.swift`. Swapping the enum's raw values from Fredoka to Nunito PostScript names, adding back an `.italic` case, and updating `Info.plist`'s `UIAppFonts` list repoints every call site at Nunito. Only the 5 call sites that got a synthetic-italic workaround during the Fredoka migration need editing — everything else (148 sites) needs zero changes.

**Tech Stack:** SwiftUI, Xcode 16 (file-system-synchronized project groups — files placed in `Wishie/Resources/Fonts/` are automatically part of the build target; no `.pbxproj` edits needed to add or remove font files).

## Global Constraints

- The `WishieFont` enum must expose exactly these 5 cases, mapped to these
  exact PostScript names (verified from each `.ttf`'s internal `name`
  table): `regular` → `"Nunito-Regular"`, `medium` → `"Nunito-Medium"`,
  `bold` → `"Nunito-Bold"`, `light` → `"Nunito-Light"`, `italic` →
  `"Nunito-Italic"`.
- The 5 sites currently using `.wishies(.regular, size).italic()` (from the
  Fredoka migration) must revert to `.wishies(.italic, size)`.
- The `Font.wishies(_:_:)` function signature does not change.
- `Info.plist`'s `UIAppFonts` array must list exactly the 5 Nunito
  filenames, nothing else.
- No visual/size changes beyond the typeface swap — don't touch font sizes
  or which weight is used at any call site other than the 5 italic sites.
- Old Fredoka `.ttf` files must be deleted once nothing references them.
- This lands as new commits on top of the existing `update/change-font`
  branch (amending PR #22) — no history rewrite of the Fredoka commits.

---

### Task 1: Swap the font enum, Info.plist, and revert the 5 sites to real italic

**Files:**
- Modify: `Wishie/Resources/WishieCustomFont.swift`
- Modify: `Wishie/Info.plist`
- Modify: `Wishie/Screens/Auth/LoginView.swift:115`
- Modify: `Wishie/Screens/Auth/SignUpView.swift:146`
- Modify: `Wishie/Screens/Home/HomeItemViewCell.swift:92`
- Modify: `Wishie/Screens/CreateList/CreateWishlistPage2.swift:138`
- Modify: `Wishie/Screens/Detail/WishItemDetailView.swift:79`
- Track (already on disk, untracked by git): `Wishie/Resources/Fonts/Nunito-Regular.ttf`,
  `Wishie/Resources/Fonts/Nunito-Medium.ttf`, `Wishie/Resources/Fonts/Nunito-Bold.ttf`,
  `Wishie/Resources/Fonts/Nunito-Light.ttf`, `Wishie/Resources/Fonts/Nunito-Italic.ttf`
- Commit (already modified in the working tree, unstaged): `Wishie/Resources/Fonts/OFL.txt`
  (its copyright line was already hand-edited to Nunito's — `Copyright 2014 The Nunito
  Project Authors` — verify this with `git diff Wishie/Resources/Fonts/OFL.txt` before
  staging; do not re-edit its contents)

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `enum WishieFont: String { case regular, medium, bold, light, italic }`
  and `static func Font.wishies(_ weight: WishieFont, _ size: CGFloat) -> Font`,
  used by all subsequent tasks and by the 148 untouched call sites elsewhere
  in the app.

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
    case regular = "Nunito-Regular"
    case medium = "Nunito-Medium"
    case bold = "Nunito-Bold"
    case light = "Nunito-Light"
    case italic = "Nunito-Italic"
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
		<string>Fredoka-Regular.ttf</string>
		<string>Fredoka-Medium.ttf</string>
		<string>Fredoka-Bold.ttf</string>
		<string>Fredoka-Light.ttf</string>
	</array>
```

Replace it with:

```xml
	<key>UIAppFonts</key>
	<array>
		<string>Nunito-Regular.ttf</string>
		<string>Nunito-Medium.ttf</string>
		<string>Nunito-Bold.ttf</string>
		<string>Nunito-Light.ttf</string>
		<string>Nunito-Italic.ttf</string>
	</array>
```

- [ ] **Step 3: Revert the 5 synthetic-italic call sites to real italic**

In `Wishie/Screens/Auth/LoginView.swift:115`, change:

```swift
                    .font(.wishies(.regular, 15).italic())
```

to:

```swift
                    .font(.wishies(.italic, 15))
```

In `Wishie/Screens/Auth/SignUpView.swift:146`, change:

```swift
                    .font(.wishies(.regular, 15).italic())
```

to:

```swift
                    .font(.wishies(.italic, 15))
```

In `Wishie/Screens/Home/HomeItemViewCell.swift:92`, change:

```swift
                    .font(.wishies(.regular, 13).italic())
```

to:

```swift
                    .font(.wishies(.italic, 13))
```

In `Wishie/Screens/CreateList/CreateWishlistPage2.swift:138`, change:

```swift
                    .font(.wishies(.regular, 14).italic())
```

to:

```swift
                    .font(.wishies(.italic, 14))
```

In `Wishie/Screens/Detail/WishItemDetailView.swift:79`, change:

```swift
                    .font(.wishies(.regular, 14).italic())
```

to:

```swift
                    .font(.wishies(.italic, 14))
```

- [ ] **Step 4: Verify no synthetic-italic pattern remains**

Run: `grep -rn "\.wishies(\.regular.*\.italic()" --include="*.swift" Wishie/`
Expected: no output (empty result).

- [ ] **Step 5: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`, with no compiler errors referencing
`WishieFont`.

- [ ] **Step 6: Commit**

The five Nunito `.ttf` files already sit in `Wishie/Resources/Fonts/` but
are untracked, and `Wishie/Resources/Fonts/OFL.txt` already has an unstaged
modification (its copyright line was hand-edited to Nunito's) — stage all
of it alongside the code changes:

```bash
git add Wishie/Resources/WishieCustomFont.swift Wishie/Info.plist \
  Wishie/Resources/Fonts/Nunito-Regular.ttf \
  Wishie/Resources/Fonts/Nunito-Medium.ttf \
  Wishie/Resources/Fonts/Nunito-Bold.ttf \
  Wishie/Resources/Fonts/Nunito-Light.ttf \
  Wishie/Resources/Fonts/Nunito-Italic.ttf \
  Wishie/Resources/Fonts/OFL.txt \
  Wishie/Screens/Auth/LoginView.swift Wishie/Screens/Auth/SignUpView.swift \
  Wishie/Screens/Home/HomeItemViewCell.swift \
  Wishie/Screens/CreateList/CreateWishlistPage2.swift \
  Wishie/Screens/Detail/WishItemDetailView.swift
git commit -m "feat: swap Fredoka for Nunito font family with real italic"
```

---

### Task 2: Remove the old Fredoka font files

**Files:**
- Delete: `Wishie/Resources/Fonts/Fredoka-Regular.ttf`
- Delete: `Wishie/Resources/Fonts/Fredoka-Medium.ttf`
- Delete: `Wishie/Resources/Fonts/Fredoka-Bold.ttf`
- Delete: `Wishie/Resources/Fonts/Fredoka-Light.ttf`

**Interfaces:**
- Consumes: nothing from Task 1's code changes directly, but must run
  after Task 1 since that's what removes the last references to Fredoka.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Confirm nothing references Fredoka anymore**

Run: `grep -rln "Fredoka" --include="*.swift" --include="*.plist" Wishie/`
Expected: no output (empty result). If anything shows up, stop — Task 1 was
incomplete.

- [ ] **Step 2: Delete the Fredoka font files**

```bash
git rm Wishie/Resources/Fonts/Fredoka-Regular.ttf \
  Wishie/Resources/Fonts/Fredoka-Medium.ttf \
  Wishie/Resources/Fonts/Fredoka-Bold.ttf \
  Wishie/Resources/Fonts/Fredoka-Light.ttf
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
git commit -m "chore: remove unused Fredoka font files"
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
warnings about failing to load a font named `Nunito-*`.

- [ ] **Step 3: Visually spot-check screens**

In the running simulator, navigate to: Welcome screen, Home screen, and
Login screen (check the italic subtitle at `LoginView.swift:115` renders
with Nunito's true italic design, not a slanted upright face). Confirm all
visible text renders in Nunito rather than falling back to the system font
(San Francisco) or showing leftover Fredoka.

Expected: all text uses Nunito; the reverted italic site shows a true
italic design.

- [ ] **Step 4: Report result**

If everything renders correctly, this task is done — no commit needed (no
files changed in this task).

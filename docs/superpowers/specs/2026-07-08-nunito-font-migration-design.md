# Nunito Font Migration

## Context

PR #22 (`update/change-font`, still open/unmerged) swapped the app's font
from WorkSans to Fredoka, funnelled through the `WishieFont` enum and
`Font.wishies(_:_:)` helper in `Wishie/Resources/WishieCustomFont.swift`.
Fredoka shipped no italic variant, so the 5 call sites that previously used
`.wishies(.italic, size)` were migrated to
`.wishies(.regular, size).italic()` (SwiftUI synthetic slant).

The user has now decided to use Nunito instead of Fredoka, and has already
added the Nunito `.ttf` files (Regular, Medium, Bold, Light, Italic) to
`Wishie/Resources/Fonts/` and updated `OFL.txt`'s copyright line to Nunito's
(`Copyright 2014 The Nunito Project Authors`).

Each file's internal PostScript name (verified from the `name` table) matches
its filename exactly: `Nunito-Regular`, `Nunito-Medium`, `Nunito-Bold`,
`Nunito-Light`, `Nunito-Italic`.

Unlike Fredoka, Nunito ships a real italic style.

This migration lands as additional commits on top of `update/change-font`,
amending PR #22 in place rather than opening a new branch/PR — no history
rewrite, the Fredoka commits stay as-is and new commits supersede them.

## Goal

Replace Fredoka with Nunito as the app's font family, restoring a real
`.italic` case backed by `Nunito-Italic.ttf` instead of the synthetic slant
used for Fredoka, and remove the Fredoka files once nothing references them.

## Design

### 1. `WishieCustomFont.swift`

```swift
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

`Font.wishies(_:_:)`'s signature is unchanged.

### 2. `Info.plist`

`UIAppFonts` becomes:

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

### 3. Call-site migration

- `.wishies(.regular, …)`, `.wishies(.bold, …)`, `.wishies(.light, …)` (148
  sites) — unchanged.
- The 5 sites currently using `.wishies(.regular, size).italic()` (added
  during the Fredoka migration) revert to `.wishies(.italic, size)`, now
  backed by the real `Nunito-Italic.ttf`:
  - `Wishie/Screens/Auth/LoginView.swift:115`
  - `Wishie/Screens/Auth/SignUpView.swift:146`
  - `Wishie/Screens/Home/HomeItemViewCell.swift:92`
  - `Wishie/Screens/CreateList/CreateWishlistPage2.swift:138`
  - `Wishie/Screens/Detail/WishItemDetailView.swift:79`

### 4. Font files

- The 5 Nunito `.ttf` files are already on disk (untracked) and get added
  to git.
- The 4 Fredoka `.ttf` files (`Fredoka-Regular.ttf`, `Fredoka-Medium.ttf`,
  `Fredoka-Bold.ttf`, `Fredoka-Light.ttf`) get removed via `git rm` once no
  code references them.
- `OFL.txt` is already updated with Nunito's copyright line — no further
  change needed.

## Out of scope

- No changes to font sizes, weights-per-screen, or visual design beyond the
  typeface swap.
- No changes to Dynamic Type / accessibility scaling behavior.
- No rewrite of the existing Fredoka commits on `update/change-font` — this
  lands as new commits on top.

## Testing

- Build the app and confirm no missing-font console warnings.
- Verify no `Fredoka` or `WorkSans` references remain in `*.swift`/`*.plist`
  after the migration.
- Visually spot-check the Welcome, Home, Login/SignUp, and Wish Item Detail
  screens to confirm Nunito renders, and that the 5 reverted sites show a
  true italic (not the synthetic slant).

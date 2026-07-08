# Fredoka Font Migration

## Context

The app currently uses WorkSans as its custom font, wired through a small
`WishieFont` enum in `Wishie/Resources/WishieCustomFont.swift` and exposed via
`Font.wishies(_:_:)`. WorkSans ships four static files (Regular, Light,
Italic, Bold), registered in `Wishie/Info.plist` under `UIAppFonts`.

The Fredoka `.ttf` files (Regular, Medium, Bold, Light) have already been
added to `Wishie/Resources/Fonts/`. The Xcode project uses file-system
synchronized groups, so any file placed in that folder is automatically part
of the build target — no `.pbxproj` edits are required to add or remove font
files.

There are 153 call sites across the app using `.wishies(weight, size)`:
81 `.bold`, 65 `.regular`, 5 `.italic`, 2 `.light`. No call site currently
uses a "medium" weight.

Fredoka has no italic/oblique static file, unlike WorkSans.

## Goal

Replace WorkSans with Fredoka as the app's font family, with minimal changes
to call sites, and remove the old WorkSans files once nothing references
them.

## Design

### 1. `WishieCustomFont.swift`

Update the `WishieFont` enum's raw values to point at the Fredoka
PostScript names (verified from each file's internal `name` table — they
match the filenames exactly: `Fredoka-Regular`, `Fredoka-Medium`,
`Fredoka-Bold`, `Fredoka-Light`). Add a new `.medium` case (unused today,
available going forward) and drop `.italic`, since Fredoka has no italic
variant.

```swift
enum WishieFont: String {
    case regular = "Fredoka-Regular"
    case medium  = "Fredoka-Medium"
    case bold    = "Fredoka-Bold"
    case light   = "Fredoka-Light"
}

extension Font {
    static func wishies(_ weight: WishieFont, _ size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}
```

The `Font.wishies(_:_:)` function signature is unchanged, so no call site
needs to change its call shape — only the `.italic` sites need remapping
(see below).

### 2. `Info.plist`

Swap the `UIAppFonts` array from the four WorkSans filenames to the four
Fredoka filenames:

```xml
<key>UIAppFonts</key>
<array>
    <string>Fredoka-Regular.ttf</string>
    <string>Fredoka-Medium.ttf</string>
    <string>Fredoka-Bold.ttf</string>
    <string>Fredoka-Light.ttf</string>
</array>
```

### 3. Call-site migration

- `.wishies(.regular, …)`, `.wishies(.bold, …)`, `.wishies(.light, …)` —
  unchanged. Same case names now resolve to Fredoka files.
- `.wishies(.italic, size)` (5 sites: `LoginView.swift`, `SignUpView.swift`,
  `HomeItemViewCell.swift`, `CreateWishlistPage2.swift`,
  `WishItemDetailView.swift`) — replaced with
  `.wishies(.regular, size).italic()`, applying SwiftUI's synthetic italic
  slant on top of Fredoka Regular so the app stays 100% Fredoka.

### 4. Remove WorkSans files

Delete `WorkSans-Regular.ttf`, `WorkSans-Bold.ttf`, `WorkSans-Light.ttf`, and
`WorkSans-Italic.ttf` from `Wishie/Resources/Fonts/` once no code references
them. Because the group is
file-system synchronized, deleting the files from disk is sufficient — no
project file cleanup needed.

## Out of scope

- No new `.medium` call sites are being introduced; the case is added purely
  so it's available for future use.
- No changes to font sizes, weights-per-screen, or visual design beyond the
  typeface swap itself.
- No changes to Dynamic Type / accessibility scaling behavior.

## Testing

- Build the app and confirm no missing-font console warnings
  (`CTFontManager` logs an error if a `UIAppFonts` filename doesn't match an
  embedded resource, and `.custom(name:)` silently falls back to system font
  if the PostScript name is wrong).
- Visually spot-check a handful of screens (Welcome, Home, Login/SignUp,
  Wish Item Detail) to confirm Fredoka renders and the 5 synthetic-italic
  sites still read as italic.

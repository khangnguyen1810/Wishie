# Share Context

## Important Instructions for Implementation

- Do NOT modify any `HomeViewModel` logic, service calls, or data-fetching behavior.
- Do NOT modify navigation routing (`NavigationLink`, `.navigationDestination`, `Route` enum, zoom transitions).
- Do NOT add comments, `console.log`-style prints, or TODO notes to any file.
- All text must use `Font.wishies(_:_:)` — no system fonts.
- All colors must come from the existing asset catalog or be derived via `Color(hex:)` using `GradientTheme` hex values.
- `HomeItemViewCell` must remain a standalone struct in `Wishie/Screens/Home/HomeItemViewCell.swift`.
- All layout changes are purely visual (SwiftUI modifiers, colors, shapes) — no structural changes to `HomeViewModel` or `WishlistServiceProtocol`.

## Reused Existing Functions/Utilities

- `GiftProgressView(progress:)`: Renders a gift image filled to a progress ratio. Located at `Wishie/CustomView/GiftProgressView.swift`.
- `WishieButton(title:enabled:filColor:titleColor:width:height:action:)`: Branded CTA button. Located at `Wishie/CustomView/WishieButton.swift`.
- `Font.wishies(_:_:)`: Custom font accessor using `WishieFont` enum values `.bold`, `.regular`, `.italic`, `.light`. Located at `Wishie/Resources/WishieCustomFont.swift`.
- `Color(hex:)`: Hex-string to `Color` initializer. Located at `Wishie/Helper/ColorExtension.swift`.
- `DateExtension.toShortDateString()`: Formats a `Date` to a short display string. Located at `Wishie/Utils/DateExtension.swift`.
- `BaseWishieScreen(topBar:content:)`: Base screen wrapper providing `lightYellow1` background and horizontal padding. Located at `Wishie/Screens/BaseWishieScreen.swift`.
- `TopAppBar(leading:center:trailing:)`: Horizontal app bar layout. Located at `Wishie/Screens/BaseWishieScreen.swift`.

## Shared Contracts

### Entities

- `WishlistModel`: Represents a wishlist. Attributes: `id: String`, `name: String`, `description: String`, `dueDate: Date`, `items: [WishlistItem]`, `themeColor: String?`, `userCreateId: String`, `members: [String: WishlistRole]`. Computed: `theme: GradientTheme` (derived from `themeColor` raw value, defaults to `.sunset`).
- `UserModel`: Represents a user. Attributes: `firstName: String`, `lastName: String`, `avatarUrl: String?`.
- `GradientTheme`: Enum with cases `.sunset`, `.ocean`, `.forest`, `.purpleDream`. Each case provides `primary: String` (light hex), `secondary: String` (saturated hex), `imageName: String` (asset name). Located at `Wishie/Models/GradientWishlishTheme.swift`.
- `WishlistItem`: `id: String`, `isPicked: Bool`. Used to compute gift progress ratio.

---


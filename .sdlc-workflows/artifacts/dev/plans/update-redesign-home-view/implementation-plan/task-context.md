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

# Task 1: Redesign `HomeItemViewCell` with Celebration-Themed Gradient Card

- [ ] 1.1: In `Wishie/Screens/Home/HomeItemViewCell.swift` UPDATE:
  - Replace the flat `.sunset.opacity(0.5)` `RoundedRectangle` background with a `LinearGradient` using `Color(hex: item.0.theme.primary)` (top) → `Color(hex: item.0.theme.secondary)` (bottom) on a `RoundedRectangle(cornerRadius: 16)`.
  - Add a `.shadow(color: Color(hex: item.0.theme.secondary).opacity(0.4), radius: 8, x: 0, y: 4)` to the card container.
  - Restructure the card `VStack` layout:
    - **Top row** (`HStack`): Wishlist name (`Text(item.0.name)`, `.wishies(.bold, 18)`, `.black`) on the left; owner full name (`Text("\(item.1.firstName) \(item.1.lastName)")`, `.wishies(.regular, 13)`, `.darkGrey`) with a `Circle` avatar placeholder (28×28, `lightYellow` fill, overlaid with `Image("user")` at 16×16) on the right.
    - **Middle row** (`HStack(alignment: .top)`): Description text (`Text(item.0.description)`, `.wishies(.italic, 14)`, `.black.opacity(0.75)`, `lineLimit(2)`) filling remaining space; `GiftProgressView(progress:)` in a fixed 72×72 frame with a gift count label below (`Text("\(itemPicked.count)/\(item.0.items.count) gifts")` or `"0 gifts"`, `.wishies(.regular, 12)`, `.darkGrey`).
    - **Bottom row** (`HStack`): A pill-shaped date badge — `HStack` containing `Image(systemName: "calendar")` (12pt, `.wishiePink`) and `Text("item.0.dueDate.toShortDateString()")` (`.wishies(.regular, 12)`, `.black`) — wrapped in a `Capsule` background of `Color.white.opacity(0.55)` with `.padding(.horizontal, 8).padding(.vertical, 4)`.
  - Remove the old `wishListItem` internal method (it already lives in `HomeView`; the cell is self-contained).
  - Set overall card `VStack` padding to `.padding(14)`.

---

# Task 2: Redesign `HomeView` Top Bar and Tab Selector

- [ ] 2.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE `topAppBar()`:
  - Change greeting `Text` from `"Are you gud? \(authViewModel.userInfo.firstName)"` to `"Hey, \(authViewModel.userInfo.firstName)! 🎁"` using `.wishies(.bold, 22)` and `.black` foreground.
  - Wrap the greeting `Text` in a `VStack(alignment: .leading, spacing: 2)` with a subtitle `Text("What are you wishing for?")` using `.wishies(.regular, 13)` and `.darkGrey`.
  - Redesign the trailing `add` action button: replace `Circle().fill(.lightYellow)` with a `ZStack` containing a `Circle` filled with a `LinearGradient(colors: [Color(hex: "#F1D790"), Color(hex: "#FEF3D7")], startPoint: .topLeading, endPoint: .bottomTrailing)` at 42×42, overlaying `Image("add")` at 20×20.
  - Redesign the trailing profile button identically: same gradient `Circle` at 42×42 overlaying `Image("user")` at 20×20.

- [ ] 2.2: In `Wishie/Screens/Home/HomeView.swift` UPDATE `typeSegmentItem(title:tab:)`:
  - Replace `RoundedRectangle.fill(.lightYellow.opacity(0.2))` container background with `Capsule().fill(Color(hex: "#FEF3D7").opacity(0.3))` on the outer `HStack` container.
  - Change the selected indicator from `RoundedRectangle(cornerRadius: 20).fill(.lightYellow)` to `Capsule().fill(LinearGradient(colors: [Color(hex: "#F1D790"), Color(hex: "#FEF3D7")], startPoint: .leading, endPoint: .trailing))`.
  - Update unselected text color from `.lightGrey` to `.darkGrey`.
  - Keep the `.matchedGeometryEffect(id: "TAB", in: animation)` and `.animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)` unchanged.

---

# Task 3: Redesign Empty State (`contentUnavailable`)

- [ ] 3.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE `contentUnavailable(msg:buttonTitle:action:)`:
  - Replace `Image(systemName: "tray.fill")` with `Image("gift_img").resizable().scaledToFit().frame(width: 90, height: 90)`.
  - Add a `Text` subtitle above the message using `"Your wishlist is waiting..."` with `.wishies(.italic, 15)` and `.wishiePink` — visible only when `selectedTab == .myList` (pass `selectedTab` as a parameter or capture it via closure).
  - Keep `WishieButton` CTA and the `"Refresh"` tappable text unchanged; update `WishieButton` fill color to `filColor: Color(hex: "#F1D790")`.
  - Wrap the whole `VStack` in a `VStack(spacing: 16)` with `.padding(40)` for better vertical rhythm.

---

# Task 4: Redesign Bottom Sheet (`bottomSheet`, `bottomSheetOption`)

- [ ] 4.1: In `Wishie/Screens/Home/HomeView.swift` UPDATE `bottomSheet(type:)`:
  - Change `Color.lightYellow1.ignoresSafeArea()` background to a `LinearGradient(colors: [Color(hex: "#FEF9EC"), Color(hex: "#FEF3D7")], startPoint: .top, endPoint: .bottom).ignoresSafeArea()`.
  - Add a `Text("What would you like to do?")` header label above the options `VStack`, using `.wishies(.bold, 16)` and `.darkGrey`, padded `.padding(.top, 8)`.

- [ ] 4.2: In `Wishie/Screens/Home/HomeView.swift` UPDATE `bottomSheetOption(image:title:)`:
  - Replace `RoundedRectangle.fill(.lightYellow)` background with a `RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.6)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "#F1D790"), lineWidth: 1))`.
  - Change icon container from a plain `Image` to a `ZStack`: `RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [Color(hex: "#F1D790"), Color(hex: "#FEF3D7")], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 40, height: 40)` with `Image(image).resizable().aspectRatio(contentMode: .fit).frame(width: 24).padding(.leading, 8)` overlaid.
  - Update title font to `.wishies(.bold, 17)` and color to `.black`.

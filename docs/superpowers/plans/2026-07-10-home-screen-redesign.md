# Home Screen Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reskin the Home screen (`Wishie/Screens/Home/HomeView.swift` + `HomeItemViewCell.swift`) to match the imported "celebration sticker" design — rotated wishlist cards with corner status badges, a new Baloo 2 display font, a vivid app-wide color re-tint, and a staggered fade/rotate-in entrance animation — while preserving all existing behavior (real-time observing, swipe-to-delete/leave, coach-mark tutorial, zoom transition, empty state).

**Architecture:** Visual-only changes layered onto the existing structure. `GradientTheme` gets new hex values (already the single source of truth for card colors everywhere in the app). `BaseWishieScreen` gains an optional `background` parameter (default preserves current behavior; only `HomeView` — its sole caller — will use the new value). `WishieCustomFont.swift` gains a second font family (`WishieDisplayFont`/`Font.wishiesDisplay`) alongside the existing Nunito one, never replacing it. `HomeItemViewCell` and `HomeView`'s header/list are rewritten section by section; a single `@State private var homeAppeared` drives per-element staggered entrance animation via individual `.animation(_:value:)` delays.

**Tech Stack:** SwiftUI, Xcode 16 (file-system-synchronized project groups — files placed under `Wishie/Resources/Fonts/` are automatically part of the build target; no `.pbxproj` edits needed). Swift Testing (`import Testing`, `@Test`, `#expect`) for the one automatable check (font registration); everything else in this plan is UI styling verified by build success + visual/manual check, matching this repo's existing convention (see `docs/superpowers/plans/2026-07-08-nunito-font-migration.md`, which has no SwiftUI view unit tests either).

## Global Constraints

- `GradientTheme`'s 4 cases (`sunset`, `ocean`, `forest`, `purpleDream`) must use exactly these hex pairs (primary → secondary): sunset `#FF9A76`→`#F4667A`, ocean `#6FE3D0`→`#38B7B0`, purpleDream `#B79CF2`→`#9C7BE0`, forest `#8DE0A0`→`#3FAE72` (forest is extrapolated — not in the source mockup).
- New display font is `Baloo 2`, weights SemiBold(600)/Bold(700)/ExtraBold(800) only, PostScript names `Baloo2-SemiBold`, `Baloo2-Bold`, `Baloo2-ExtraBold` (verified from the generated `.ttf`'s own `name` table — see Task 1). Exposed via a **new** enum `WishieDisplayFont` and `Font.wishiesDisplay(_:_:)`, without touching the existing `WishieFont`/`Font.wishies(_:_:)`.
- Baloo 2 has no italic face — italic text (wishlist description) keeps using `.wishies(.italic, _)` (real `Nunito-Italic.ttf`), never `.wishiesDisplay` + synthetic `.italic()`.
- `BaseWishieScreen`'s `background` parameter must default to `Color.lightYellow1` so its behavior is unchanged if omitted (it currently has exactly one caller, `HomeView`, which this plan updates to pass the new background explicitly).
- Card/list container stays `List` (not `ScrollView`) — it's the only way to keep `.swipeActions`, `.refreshable`, and the `anchorPreference`/`CoachMarkBoundsKey` calls the coach-mark tutorial depends on, without reimplementing them.
- The entrance animation is driven by one `@State private var homeAppeared: Bool` toggled in `.onAppear`/`.onDisappear` on the `NavigationStack`; each element applies its own `.animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(x), value: homeAppeared)` — never a single shared animation modifier, since delays differ per element.
- Card/tile rotation (`.rotationEffect`) is a **static**, always-applied transform — it is not part of the animated-in effect (matches the source mockup's CSS keyframes, where `rotate(var(--rot))` is identical in the `from` and `to` states).
- The coach-mark tutorial's example row (`exampleWishlistForTutorial`, shown when `!hasSeenHomeTutorial`) is NOT rotated and NOT part of the staggered entrance — only real wishlist rows in the `ForEach` get both, to avoid any risk of the `CoachMarkBoundsKey` anchor misaligning with a rotated view.
- `daysRemaining`/`isUrgent`/`isOverDue` (already in `HomeItemViewCell`) are reused as-is to drive the new corner badge — no new date logic.

---

### Task 1: Add Baloo 2 as a new bundled font family

**Files:**
- Create: `Wishie/Resources/Fonts/Baloo2-SemiBold.ttf`
- Create: `Wishie/Resources/Fonts/Baloo2-Bold.ttf`
- Create: `Wishie/Resources/Fonts/Baloo2-ExtraBold.ttf`
- Create: `Wishie/Resources/Fonts/Baloo2-OFL.txt`
- Modify: `Wishie/Resources/WishieCustomFont.swift`
- Modify: `Wishie/Info.plist`
- Create: `WishieTests/WishieDisplayFontTests.swift`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `enum WishieDisplayFont: String { case semiBold, bold, extraBold }` and
  `static func Font.wishiesDisplay(_ weight: WishieDisplayFont, _ size: CGFloat) -> Font`,
  consumed by every later task that touches Home screen text.

- [ ] **Step 1: Write the failing test**

Create `WishieTests/WishieDisplayFontTests.swift`:

```swift
//
//  WishieDisplayFontTests.swift
//  WishieTests
//

import Testing
import UIKit

struct WishieDisplayFontTests {
    @Test func baloo2SemiBoldIsRegistered() {
        #expect(UIFont(name: "Baloo2-SemiBold", size: 12) != nil)
    }

    @Test func baloo2BoldIsRegistered() {
        #expect(UIFont(name: "Baloo2-Bold", size: 12) != nil)
    }

    @Test func baloo2ExtraBoldIsRegistered() {
        #expect(UIFont(name: "Baloo2-ExtraBold", size: 12) != nil)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:
```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:WishieTests/WishieDisplayFontTests 2>&1 | tail -40
```
Expected: all 3 tests **FAIL** (`UIFont(name:...) != nil` is false — the font isn't bundled/registered yet).

- [ ] **Step 3: Generate the static Baloo 2 weights from Google Fonts' variable font**

Baloo 2 ships from Google Fonts only as a single variable font (`Baloo2[wght].ttf`), not as separate static files per weight — unlike the Nunito files already in this repo. Use `fonttools` to pin the 3 needed weights into static `.ttf`s with correct internal names, matching the pattern of every other font file already bundled in this project:

```bash
mkdir -p /tmp/baloo2-src && cd /tmp/baloo2-src
pip3 install --quiet fonttools
curl -sL -o Baloo2Variable.ttf "https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/Baloo2%5Bwght%5D.ttf"
curl -sL -o OFL.txt "https://raw.githubusercontent.com/google/fonts/main/ofl/baloo2/OFL.txt"
python3 -m fontTools.varLib.instancer -q --update-name-table -o Baloo2-SemiBold.ttf Baloo2Variable.ttf wght=600
python3 -m fontTools.varLib.instancer -q --update-name-table -o Baloo2-Bold.ttf Baloo2Variable.ttf wght=700
python3 -m fontTools.varLib.instancer -q --update-name-table -o Baloo2-ExtraBold.ttf Baloo2Variable.ttf wght=800
```

Verify the internal PostScript names before copying anything into the project:

```bash
python3 - <<'EOF'
from fontTools.ttLib import TTFont
for fn in ["Baloo2-SemiBold.ttf", "Baloo2-Bold.ttf", "Baloo2-ExtraBold.ttf"]:
    f = TTFont(fn)
    print(fn, "->", f['name'].getDebugName(6))
EOF
```
Expected output:
```
Baloo2-SemiBold.ttf -> Baloo2-SemiBold
Baloo2-Bold.ttf -> Baloo2-Bold
Baloo2-ExtraBold.ttf -> Baloo2-ExtraBold
```

Copy the 3 static fonts and the license into the project (run from the repo root):

```bash
cp /tmp/baloo2-src/Baloo2-SemiBold.ttf /tmp/baloo2-src/Baloo2-Bold.ttf /tmp/baloo2-src/Baloo2-ExtraBold.ttf \
  Wishie/Resources/Fonts/
cp /tmp/baloo2-src/OFL.txt Wishie/Resources/Fonts/Baloo2-OFL.txt
```

Note: `Wishie/Resources/Fonts/OFL.txt` (Nunito's license) is untouched — Baloo 2 gets its own license file since it's an independently-licensed second font family, not a replacement.

- [ ] **Step 4: Add the `WishieDisplayFont` enum and `Font.wishiesDisplay` helper**

Append to the end of `Wishie/Resources/WishieCustomFont.swift` (do not modify the existing `WishieFont` enum or `Font.wishies` helper above it):

```swift

enum WishieDisplayFont: String {
    case semiBold = "Baloo2-SemiBold"
    case bold = "Baloo2-Bold"
    case extraBold = "Baloo2-ExtraBold"
}

extension Font {
    static func wishiesDisplay(_ weight: WishieDisplayFont, _ size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}
```

- [ ] **Step 5: Register the 3 new fonts in `Info.plist`**

In `Wishie/Info.plist`, find:

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

Replace with:

```xml
	<key>UIAppFonts</key>
	<array>
		<string>Nunito-Regular.ttf</string>
		<string>Nunito-Medium.ttf</string>
		<string>Nunito-Bold.ttf</string>
		<string>Nunito-Light.ttf</string>
		<string>Nunito-Italic.ttf</string>
		<string>Baloo2-SemiBold.ttf</string>
		<string>Baloo2-Bold.ttf</string>
		<string>Baloo2-ExtraBold.ttf</string>
	</array>
```

- [ ] **Step 6: Run the test to verify it passes**

Run:
```bash
xcodebuild test -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:WishieTests/WishieDisplayFontTests 2>&1 | tail -40
```
Expected: all 3 tests **PASS**.

- [ ] **Step 7: Build the full project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 8: Commit**

```bash
git add Wishie/Resources/WishieCustomFont.swift Wishie/Info.plist \
  Wishie/Resources/Fonts/Baloo2-SemiBold.ttf Wishie/Resources/Fonts/Baloo2-Bold.ttf \
  Wishie/Resources/Fonts/Baloo2-ExtraBold.ttf Wishie/Resources/Fonts/Baloo2-OFL.txt \
  WishieTests/WishieDisplayFontTests.swift
git commit -m "feat: add Baloo 2 display font family alongside Nunito"
```

---

### Task 2: Re-tint `GradientTheme` app-wide and fix the theme picker swatches

**Files:**
- Modify: `Wishie/Models/GradientWishlishTheme.swift`
- Modify: `Wishie/Screens/CreateList/CreateWishlistPage3.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `GradientTheme.primary`/`.secondary` now return the vivid hex values — consumed automatically by `HomeItemViewCell`, `WishlistDetailScreen`, `WishItemDetailView` (no changes needed in those files, they already read through `GradientTheme`).

- [ ] **Step 1: Replace the theme color values**

Replace the full contents of `Wishie/Models/GradientWishlishTheme.swift`:

```swift
//
//  GradientWishlishTheme.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 21/12/25.
//
import SwiftUI
enum GradientTheme: String, CaseIterable {
    case sunset
    case ocean
    case forest
    case purpleDream

    var primary: String {
        switch self {
        case .sunset:
            return "#FF9A76"
        case .ocean:
            return "#6FE3D0"
        case .forest:
            return "#8DE0A0"
        case .purpleDream:
            return "#B79CF2"
        }
    }
    var secondary: String {
        switch self {
        case .sunset:
            return "#F4667A"
        case .ocean:
            return "#38B7B0"
        case .forest:
            return "#3FAE72"
        case .purpleDream:
            return "#9C7BE0"
        }
    }
    var imageName: String {
        switch self {
        case .sunset:
            return "sunset"
        case .ocean:
            return "ocean"
        case .forest:
            return "forest"
        case .purpleDream:
            return "purpleDream"
        }
    }
}
```

- [ ] **Step 2: Replace the static bitmap theme swatches with code-rendered gradients**

`Image(theme.imageName)` renders a static, pre-baked bitmap asset that cannot reflect the new hex values above. In `Wishie/Screens/CreateList/CreateWishlistPage3.swift`, replace:

```swift
                    ForEach(GradientTheme.allCases, id: \.self) { theme in
                        Image(theme.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .lightYellow ,radius: 1, x: -5, y: 5)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        createWishlistViewModel.selectedTheme == theme ? .wishiePink : .clear,
                                        lineWidth: 3
                                    )
                            }
                            .onTapGesture {
                                createWishlistViewModel.selectedTheme = theme
                            }
                    }
```

with:

```swift
                    ForEach(GradientTheme.allCases, id: \.self) { theme in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: theme.primary), Color(hex: theme.secondary)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .aspectRatio(1, contentMode: .fit)
                            .shadow(color: .lightYellow, radius: 1, x: -5, y: 5)
                            .overlay {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        createWishlistViewModel.selectedTheme == theme ? .wishiePink : .clear,
                                        lineWidth: 3
                                    )
                            }
                            .onTapGesture {
                                createWishlistViewModel.selectedTheme = theme
                            }
                    }
```

(`theme.imageName` stays on the enum — it's still used as the `WishlistModel`'s theme identifier elsewhere — only its bitmap rendering here is removed. The now-unreferenced `.imageset` assets are left in place; deleting unrelated assets is out of scope.)

- [ ] **Step 3: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Wishie/Models/GradientWishlishTheme.swift Wishie/Screens/CreateList/CreateWishlistPage3.swift
git commit -m "feat: re-tint GradientTheme to a vivid sticker palette app-wide"
```

---

### Task 3: Home-only gradient background with confetti decoration

**Files:**
- Modify: `Wishie/Screens/BaseWishieScreen.swift`
- Modify: `Wishie/Screens/Home/HomeView.swift`

**Interfaces:**
- Consumes: nothing.
- Produces: `BaseWishieScreen`'s new optional `background` parameter (default `{ Color.lightYellow1 }`), consumed only by `HomeView` in this task. `@State private var celebrationFloat` and the `.onAppear { celebrationFloat = true }` block on `HomeView`'s `NavigationStack`, extended by Task 5 to also drive `homeAppeared`.

- [ ] **Step 1: Add an optional `background` parameter to `BaseWishieScreen`**

Replace the full contents of `Wishie/Screens/BaseWishieScreen.swift`:

```swift
//
//  BaseWishieScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 13/12/25.
//

import SwiftUI

struct BaseWishieScreen<
    Background: View,
    TopBar: View,
    Content: View
>: View {

    let background: Background
    let topBar: TopBar
    let content: Content

    init(
        @ViewBuilder background: () -> Background = { Color.lightYellow1 },
        @ViewBuilder topBar: () -> TopBar,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background()
        self.topBar = topBar()
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()
            VStack {
                topBar
                content
                    .ignoresSafeArea()
            }
            .padding(.horizontal, 15)
        }
        .navigationBarBackButtonHidden()
    }
}
struct TopAppBar<
    Leading: View,
    Center: View,
    Trailing: View
>: View {
    
    let leading: Leading
    let center: Center
    let trailing: Trailing
    
    init(
        @ViewBuilder leading: () -> Leading = { EmptyView()},
        @ViewBuilder center: () -> Center = { EmptyView()},
        @ViewBuilder trailing: () -> Trailing = { EmptyView()}
    ) {
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }
    
    var body: some View {
        ZStack {
            HStack {
                leading
                Spacer()
                trailing
            }
            center
                .frame(maxWidth: .infinity/2)
        }
    }
}
```

(Only the `BaseWishieScreen` struct changed; `TopAppBar` is copied through unmodified.)

- [ ] **Step 2: Add `celebrationFloat` state to `HomeView`**

In `Wishie/Screens/Home/HomeView.swift`, find:

```swift
    @AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false
```

and add immediately after it:

```swift
    @AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false
    @State private var celebrationFloat: Bool = false
```

- [ ] **Step 3: Add the gradient + confetti background view**

In `Wishie/Screens/Home/HomeView.swift`, add this new computed property right before `private var tabSelector: some View {`:

```swift
    @ViewBuilder
    private var homeBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#FFF8E8"), Color(hex: "#FBEACB")],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#D4AF6A").opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 85
                    )
                )
                .frame(width: 170, height: 170)
                .offset(x: 100, y: -340)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "#6FE3D0").opacity(0.8))
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(20))
                .offset(x: -140, y: -300)
            Circle()
                .fill(Color(hex: "#F4667A").opacity(0.7))
                .frame(width: 8, height: 8)
                .offset(x: 140, y: -270)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#B79CF2").opacity(0.75))
                .frame(width: 9, height: 9)
                .rotationEffect(.degrees(-15))
                .offset(x: 95, y: -330)
            Circle()
                .fill(Color(hex: "#E7B65A").opacity(0.7))
                .frame(width: 7, height: 7)
                .offset(x: -120, y: -200)
                .offset(y: celebrationFloat ? -6 : 0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: celebrationFloat)
        }
        .allowsHitTesting(false)
    }
```

- [ ] **Step 4: Wire the new background into `BaseWishieScreen` and start the float loop**

In `Wishie/Screens/Home/HomeView.swift`, find:

```swift
        NavigationStack(path: $path) {
            BaseWishieScreen(
                topBar: {
                    topAppBar()
                },
```

Replace with:

```swift
        NavigationStack(path: $path) {
            BaseWishieScreen(
                background: {
                    homeBackground
                },
                topBar: {
                    topAppBar()
                },
```

Then find:

```swift
            .task {
                await authViewModel.getUserInfo()
                homeViewModel.startObservingWishlists()
            }
        }
```

Replace with:

```swift
            .task {
                await authViewModel.getUserInfo()
                homeViewModel.startObservingWishlists()
            }
            .onAppear {
                celebrationFloat = true
            }
        }
```

- [ ] **Step 5: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 6: Visually verify**

Run the app in the Simulator (see Task 9 for the boot/install commands) and confirm the Home screen shows a cream-to-gold vertical gradient background with faint confetti dots near the top and one dot gently floating, instead of the flat `lightYellow1` background. Confirm every other screen using `BaseWishieScreen` transitively through the same struct (there are currently none besides Home) is unaffected — not applicable today, but note it for future callers.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/BaseWishieScreen.swift Wishie/Screens/Home/HomeView.swift
git commit -m "feat: add Home-only gradient background with confetti decoration"
```

---

### Task 4: Redesign `HomeItemViewCell` — corner sticker badge and linear progress footer

**Files:**
- Modify: `Wishie/Screens/Home/HomeItemViewCell.swift`

**Interfaces:**
- Consumes: `Font.wishiesDisplay(_:_:)` from Task 1, `GradientTheme` vivid colors from Task 2 (automatic).
- Produces: `HomeItemViewCell(item:)` — same init signature as before, consumed by `HomeView`'s `ForEach` (Task 7 adds rotation/animation around this same call, doesn't change the call itself).

- [ ] **Step 1: Replace the full file**

Replace the full contents of `Wishie/Screens/Home/HomeItemViewCell.swift`:

```swift
import SwiftUI

struct HomeItemViewCell: View {
    var item: (WishlistModel, UserModel)

    private var itemPicked: [WishlistItem] {
        item.0.items.filter { $0.isPicked }
    }

    private var progress: Double {
        item.0.items.count > 0 ? Double(itemPicked.count) / Double(item.0.items.count) : 0.0
    }

    private var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: item.0.dueDate)
        return max(-1, calendar.dateComponents([.day], from: today, to: due).day ?? 0)
    }

    private var isUrgent: Bool {
        daysRemaining <= 7 && daysRemaining >= 0
    }

    private var isOverDue: Bool {
        daysRemaining < 0
    }

    private var avatarView: some View {
        Group {
            if let avatarUrl = item.1.avatarUrl, !avatarUrl.isEmpty {
                WishieWebImage(url: avatarUrl)
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
            } else {
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
            }
        }
    }

    var body: some View {
        ZStack {
            themeBackground
            decorativeOverlay
            contentLayer
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(hex: item.0.theme.secondary).opacity(0.45), radius: 12, x: 0, y: 6)
        .overlay(alignment: .topTrailing) {
            statusBadge
                .offset(x: -14, y: -14)
        }
    }

    @ViewBuilder
    private var themeBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: item.0.theme.primary),
                Color(hex: item.0.theme.secondary)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var decorativeOverlay: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 120, height: 120)
                .offset(x: geo.size.width - 55, y: -55)
            Circle()
                .fill(Color.white.opacity(0.09))
                .frame(width: 72, height: 72)
                .offset(x: geo.size.width - 85, y: 32)
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 48, height: 48)
                .offset(x: -18, y: geo.size.height - 18)
        }
        .clipped()
    }

    @ViewBuilder
    private var statusBadge: some View {
        if daysRemaining == 0 {
            badgeLabel(
                text: "🎉 TODAY",
                background: Color(hex: "#FFE9A8"),
                foreground: Color(hex: "#8C5A17"),
                rotation: 8,
                hasBorder: true
            )
        } else if isOverDue {
            badgeLabel(
                text: "⏰ OVERDUE",
                background: .white,
                foreground: Color(hex: "#B85C3E"),
                rotation: -6,
                hasBorder: false
            )
        } else {
            badgeLabel(
                text: "\(daysRemaining)d left",
                background: .white,
                foreground: isUrgent ? Color.wishiePink : Color(hex: item.0.theme.secondary),
                rotation: 6,
                hasBorder: false
            )
        }
    }

    @ViewBuilder
    private func badgeLabel(text: String, background: Color, foreground: Color, rotation: Double, hasBorder: Bool) -> some View {
        Text(text)
            .font(.wishiesDisplay(.extraBold, 12))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(background)
                    .overlay(
                        Capsule().stroke(Color.white, lineWidth: hasBorder ? 2 : 0)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
            .rotationEffect(.degrees(rotation))
    }

    @ViewBuilder
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            if !item.0.description.isEmpty {
                Text(item.0.description)
                    .font(.wishies(.italic, 13))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            footerRow
        }
        .padding(16)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.0.name)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.wishiesDisplay(.extraBold, 19))
                HStack(spacing: 4) {
                    Text("📅")
                        .font(.system(size: 11))
                    Text(item.0.dueDate.toShortDateString())
                        .font(.wishiesDisplay(.semiBold, 13))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            }
            Spacer()
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    avatarView
                }
                Text(item.1.firstName.isEmpty ? "—" : item.1.firstName)
                    .font(.wishiesDisplay(.bold, 10))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .frame(maxWidth: 48)
            }
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.3))
            GeometryReader { geo in
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 10)
    }

    @ViewBuilder
    private var footerRow: some View {
        HStack(alignment: .center, spacing: 10) {
            progressBar
            HStack(spacing: 5) {
                Text("🎁")
                    .font(.system(size: 11))
                Text(item.0.items.count > 0 ? "\(itemPicked.count)/\(item.0.items.count)" : "No gifts yet")
                    .font(.wishiesDisplay(.extraBold, 12))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.28)))
            .fixedSize()
        }
    }
}

#Preview {
    let item1 = WishlistItem(id: "1", name: "Leather journal", isPicked: true)
    let item2 = WishlistItem(id: "2", name: "Gold earrings")
    let item3 = WishlistItem(id: "3", name: "Scented candle set")
    let wishListModel = WishlistModel(
        id: "1",
        name: "Birthday Celebrations",
        description: "Things I'd love to receive for my special day!",
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        items: [item1, item2, item3],
        themeColor: "sunset",
        userCreateId: "1",
        members: [:]
    )
    let userModel = UserModel()
    HomeItemViewCell(item: (wishListModel, userModel))
        .padding()
}
```

- [ ] **Step 2: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Visually verify with the Xcode preview**

Open `Wishie/Screens/Home/HomeItemViewCell.swift` in Xcode and check the canvas preview (due date is 5 days out, so `isUrgent` is true): confirm a white "5d left" badge with pink text sits in the top-right corner, the linear progress bar shows 1/3 filled, and the "🎁 1/3" pill renders in Baloo 2.

- [ ] **Step 4: Commit**

```bash
git add Wishie/Screens/Home/HomeItemViewCell.swift
git commit -m "feat: redesign HomeItemViewCell with corner sticker badge and linear progress"
```

---

### Task 5: Redesign the Home top bar and tab selector, wire the entrance animation trigger

**Files:**
- Modify: `Wishie/Screens/Home/HomeView.swift`

**Interfaces:**
- Consumes: `Font.wishiesDisplay` (Task 1), `celebrationFloat` state (Task 3).
- Produces: `@State private var homeAppeared: Bool`, toggled `true` in `.onAppear` and `false` in `.onDisappear` on the `NavigationStack` — consumed by Tasks 6 and 7 for their own staggered-entrance modifiers.

- [ ] **Step 1: Add `homeAppeared` state**

In `Wishie/Screens/Home/HomeView.swift`, find:

```swift
    @AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false
    @State private var celebrationFloat: Bool = false
```

Replace with:

```swift
    @AppStorage(WishieConstants.hasSeenHomeTutorial) private var hasSeenHomeTutorial: Bool = false
    @State private var celebrationFloat: Bool = false
    @State private var homeAppeared: Bool = false
```

- [ ] **Step 2: Toggle `homeAppeared` alongside `celebrationFloat`**

Find:

```swift
            .onAppear {
                celebrationFloat = true
            }
        }
```

Replace with:

```swift
            .onAppear {
                celebrationFloat = true
                homeAppeared = true
            }
            .onDisappear {
                homeAppeared = false
            }
        }
```

- [ ] **Step 3: Redesign the greeting/subtitle and add/profile buttons**

Find the full `topAppBar()` function:

```swift
    @ViewBuilder
    func topAppBar() -> some View {
        TopAppBar {
            VStack(alignment: .leading, spacing: 3) {
                Text(authViewModel.userInfo.firstName.isEmpty
                     ? "Hey there! \u{1F381}"
                     : "Hey, \(authViewModel.userInfo.firstName)! \u{1F389}")
                    .font(.wishies(.bold, 22))
                    .foregroundColor(.black)
                Text("Your celebrations await \u{2728}")
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(Color.darkGrey)
            }
        } trailing: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#F1D790")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .shadow(color: Color(hex: "#F9C46B").opacity(0.45), radius: 6, x: 0, y: 3)
                    Image("add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeAddButton": $0] }
                .onTapGesture { activeSheet = .add }
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                        )
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .onTapGesture { isShowProfile = true }
            }
            .padding(.trailing, 4)
        }
    }
```

Replace with:

```swift
    @ViewBuilder
    func topAppBar() -> some View {
        TopAppBar {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(authViewModel.userInfo.firstName.isEmpty
                         ? "Hey there!"
                         : "Hey, \(authViewModel.userInfo.firstName)!")
                        .font(.wishiesDisplay(.extraBold, 28))
                        .foregroundColor(Color(hex: "#5B3F0F"))
                    Text("🎉")
                        .font(.system(size: 24))
                        .offset(y: celebrationFloat ? -6 : 0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: celebrationFloat)
                }
                .opacity(homeAppeared ? 1 : 0)
                .offset(y: homeAppeared ? 0 : 26)
                .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.05), value: homeAppeared)
                Text("Your celebrations await ✨")
                    .font(.wishies(.medium, 13))
                    .foregroundStyle(Color(hex: "#9A7A3E"))
                    .opacity(homeAppeared ? 1 : 0)
                    .offset(y: homeAppeared ? 0 : 26)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.12), value: homeAppeared)
            }
        } trailing: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(hex: "#F4667A").opacity(0.35), radius: 8, x: 0, y: 4)
                    Image("add")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .rotationEffect(.degrees(6))
                .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeAddButton": $0] }
                .onTapGesture { activeSheet = .add }
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        )
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .onTapGesture { isShowProfile = true }
            }
            .padding(.trailing, 4)
        }
    }
```

- [ ] **Step 4: Redesign the tab selector**

Find:

```swift
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabItem(title: "My list", tab: .myList)
            tabItem(title: "Friend's list", tab: .friendsList)
        }
        .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeTabSelector": $0] }
    }

    @ViewBuilder
    private func tabItem(title: String, tab: HomeTab) -> some View {
        ZStack {
            if selectedTab == tab {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
            Text(title)
                .font(.wishies(.bold, 15))
                .foregroundStyle(selectedTab == tab ? .black : Color.darkGrey)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        }
        .onTapGesture { selectedTab = tab }
    }
```

Replace with:

```swift
    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabItem(title: "My list", tab: .myList)
            tabItem(title: "Friend's list", tab: .friendsList)
        }
        .padding(5)
        .background {
            Capsule()
                .fill(Color.white)
                .overlay(
                    Capsule().stroke(Color(hex: "#E9D8AC"), lineWidth: 1)
                )
                .shadow(color: Color(hex: "#B48C3C").opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeTabSelector": $0] }
    }

    @ViewBuilder
    private func tabItem(title: String, tab: HomeTab) -> some View {
        ZStack {
            if selectedTab == tab {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "#F4667A").opacity(0.3), radius: 8, x: 0, y: 3)
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
            Text(title)
                .font(.wishiesDisplay(.bold, 15))
                .foregroundStyle(selectedTab == tab ? .white : Color(hex: "#A5875A"))
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
        }
        .onTapGesture { selectedTab = tab }
    }
```

- [ ] **Step 5: Update the tab selector's call site to drop the now-duplicated background and add entrance animation**

Find:

```swift
                content: {
                    tabSelector
                        .frame(height: 44)
                        .background {
                            Capsule()
                                .fill(Color.white.opacity(0.4))
                                .overlay(
                                    Capsule().stroke(Color(hex: "#F1D790").opacity(0.6), lineWidth: 1)
                                )
                        }
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                        .padding(.bottom, 14)
```

Replace with:

```swift
                content: {
                    tabSelector
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: selectedTab)
                        .opacity(homeAppeared ? 1 : 0)
                        .offset(y: homeAppeared ? 0 : 26)
                        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.18), value: homeAppeared)
                        .padding(.bottom, 14)
```

(The white capsule background moved inside `tabSelector` itself in Step 4, so the old outer `.background {}`/`.frame(height: 44)` are removed here to avoid a doubled/clipped capsule.)

- [ ] **Step 6: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Commit**

```bash
git add Wishie/Screens/Home/HomeView.swift
git commit -m "feat: redesign Home top bar and tab selector, wire entrance animation state"
```

---

### Task 6: Replace the summary bar with two rotated stat tiles

**Files:**
- Modify: `Wishie/Screens/Home/HomeView.swift`

**Interfaces:**
- Consumes: `homeAppeared` (Task 5), `Font.wishiesDisplay` (Task 1).
- Produces: nothing new consumed by later tasks.

- [ ] **Step 1: Replace `summaryCard`, `nearestEventSection`, and `summaryStatItem`**

Find:

```swift
    @ViewBuilder
    func summaryCard() -> some View {
        HStack(spacing: 0) {
            summaryStatItem(
                value: "\(currentWishlists.count)",
                label: selectedTab == .myList ? "Wishlists" : "Joined",
                icon: "list.star"
            )
            nearestEventSection()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7").opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        }
        .shadow(color: Color(hex: "#F1D790").opacity(0.3), radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private func nearestEventSection() -> some View {
        if let nearest = nearestDueDate {
            let days = max(0, Calendar.current.dateComponents(
                [.day],
                from: Calendar.current.startOfDay(for: Date()),
                to: Calendar.current.startOfDay(for: nearest)
            ).day ?? 0)
            Divider()
                .frame(height: 28)
                .background(Color(hex: "#F1D790").opacity(0.8))
            summaryStatItem(
                value: days == 0 ? "Today!" : "\(days)d",
                label: "Next Event",
                icon: "party.popper.fill"
            )
        }
    }

    @ViewBuilder
    private func summaryStatItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wishiePink)
                Text(value)
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(Color.black)
            }
            Text(label)
                .font(.wishies(.regular, 11))
                .foregroundStyle(Color.darkGrey)
        }
        .frame(maxWidth: .infinity)
    }
```

Replace with:

```swift
    @ViewBuilder
    func summaryCard() -> some View {
        HStack(spacing: 10) {
            statTile(
                value: "\(currentWishlists.count)",
                label: selectedTab == .myList ? "Wishlists" : "Joined",
                background: Color(hex: "#6FE3D0"),
                rotation: -2,
                delay: 0.24
            )
            if let nearest = nearestDueDate {
                let days = max(0, Calendar.current.dateComponents(
                    [.day],
                    from: Calendar.current.startOfDay(for: Date()),
                    to: Calendar.current.startOfDay(for: nearest)
                ).day ?? 0)
                statTile(
                    value: days == 0 ? "Today!" : "🎉 \(days)d",
                    label: "Next Event",
                    background: Color(hex: "#B79CF2"),
                    rotation: 2,
                    delay: 0.30
                )
            }
        }
    }

    @ViewBuilder
    private func statTile(value: String, label: String, background: Color, rotation: Double, delay: Double) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.wishiesDisplay(.extraBold, 22))
                .foregroundStyle(Color.white)
            Text(label)
                .font(.wishiesDisplay(.bold, 12))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(background)
                .shadow(color: background.opacity(0.35), radius: 10, x: 0, y: 5)
        )
        .rotationEffect(.degrees(rotation))
        .opacity(homeAppeared ? 1 : 0)
        .offset(y: homeAppeared ? 0 : 26)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(delay), value: homeAppeared)
    }
```

- [ ] **Step 2: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Commit**

```bash
git add Wishie/Screens/Home/HomeView.swift
git commit -m "feat: replace Home summary bar with two rotated stat tiles"
```

---

### Task 7: Rotate wishlist cards in the list, adjust row spacing, add per-card entrance animation

**Files:**
- Modify: `Wishie/Screens/Home/HomeView.swift`

**Interfaces:**
- Consumes: `homeAppeared` (Task 5), the redesigned `HomeItemViewCell` (Task 4).
- Produces: nothing new consumed by later tasks.

- [ ] **Step 1: Rewrite the `.myList` `ForEach`**

Find:

```swift
                                case .myList:
                                    ForEach(homeViewModel.myWishlists, id: \.self.0) { wishlist in
                                        ZStack {
                                            NavigationLink {
                                                WishlistDetailScreen(
                                                    navigationPath: $path,
                                                    wishlist: wishlist.0,
                                                    owner: wishlist.1
                                                )
                                                .navigationTransition(
                                                    .zoom(sourceID: wishlist.0.id, in: animation)
                                                )
                                            } label: {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                            HomeItemViewCell(item: wishlist)
                                        }
                                        .contentShape(Rectangle())
                                        .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .swipeActions {
                                            Button {
                                                selectedWishlist = wishlist
                                                showDeleteConfirm = true
                                            } label: {
                                                Label("Delete wishlist", systemImage: "trash")
                                            }
                                            .tint(.wishiePink)
                                        }
                                    }
```

Replace with:

```swift
                                case .myList:
                                    ForEach(Array(homeViewModel.myWishlists.enumerated()), id: \.element.0) { index, wishlist in
                                        ZStack {
                                            NavigationLink {
                                                WishlistDetailScreen(
                                                    navigationPath: $path,
                                                    wishlist: wishlist.0,
                                                    owner: wishlist.1
                                                )
                                                .navigationTransition(
                                                    .zoom(sourceID: wishlist.0.id, in: animation)
                                                )
                                            } label: {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                            HomeItemViewCell(item: wishlist)
                                                .rotationEffect(.degrees(index % 2 == 0 ? -1 : 1.5))
                                        }
                                        .opacity(homeAppeared ? 1 : 0)
                                        .offset(y: homeAppeared ? 0 : 26)
                                        .animation(
                                            .timingCurve(0.22, 1, 0.36, 1, duration: 0.5)
                                                .delay(0.36 + Double(min(index, 6)) * 0.08),
                                            value: homeAppeared
                                        )
                                        .contentShape(Rectangle())
                                        .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .swipeActions {
                                            Button {
                                                selectedWishlist = wishlist
                                                showDeleteConfirm = true
                                            } label: {
                                                Label("Delete wishlist", systemImage: "trash")
                                            }
                                            .tint(.wishiePink)
                                        }
                                    }
```

- [ ] **Step 2: Rewrite the `.friendsList` `ForEach`**

Find:

```swift
                                case .friendsList:
                                    ForEach(homeViewModel.myFriendWishlists, id: \.self.0) { wishlist in
                                        ZStack {
                                            NavigationLink {
                                                WishlistDetailScreen(
                                                    navigationPath: $path,
                                                    wishlist: wishlist.0,
                                                    owner: wishlist.1
                                                )
                                                .navigationTransition(
                                                    .zoom(sourceID: wishlist.0.id, in: animation)
                                                )
                                            } label: {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                            HomeItemViewCell(item: wishlist)
                                        }
                                        .contentShape(Rectangle())
                                        .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets())
                                        .listRowBackground(Color.clear)
                                        .swipeActions {
                                            Button {
                                                selectedWishlist = wishlist
                                                showLeaveConfirm = true
                                            } label: {
                                                Label("Leave Wishlist", systemImage: "trash")
                                            }
                                            .tint(.wishiePink)
                                        }
                                    }
```

Replace with:

```swift
                                case .friendsList:
                                    ForEach(Array(homeViewModel.myFriendWishlists.enumerated()), id: \.element.0) { index, wishlist in
                                        ZStack {
                                            NavigationLink {
                                                WishlistDetailScreen(
                                                    navigationPath: $path,
                                                    wishlist: wishlist.0,
                                                    owner: wishlist.1
                                                )
                                                .navigationTransition(
                                                    .zoom(sourceID: wishlist.0.id, in: animation)
                                                )
                                            } label: {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                            HomeItemViewCell(item: wishlist)
                                                .rotationEffect(.degrees(index % 2 == 0 ? -1 : 1.5))
                                        }
                                        .opacity(homeAppeared ? 1 : 0)
                                        .offset(y: homeAppeared ? 0 : 26)
                                        .animation(
                                            .timingCurve(0.22, 1, 0.36, 1, duration: 0.5)
                                                .delay(0.36 + Double(min(index, 6)) * 0.08),
                                            value: homeAppeared
                                        )
                                        .contentShape(Rectangle())
                                        .matchedTransitionSource(id: wishlist.0.id, in: animation)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(EdgeInsets(top: 14, leading: 0, bottom: 14, trailing: 0))
                                        .listRowBackground(Color.clear)
                                        .swipeActions {
                                            Button {
                                                selectedWishlist = wishlist
                                                showLeaveConfirm = true
                                            } label: {
                                                Label("Leave Wishlist", systemImage: "trash")
                                            }
                                            .tint(.wishiePink)
                                        }
                                    }
```

- [ ] **Step 3: Tighten `listRowSpacing` now that rows carry their own top/bottom insets**

Find:

```swift
                        .listRowSpacing(10)
                        .listStyle(.plain)
```

Replace with:

```swift
                        .listRowSpacing(6)
                        .listStyle(.plain)
```

- [ ] **Step 4: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/Home/HomeView.swift
git commit -m "feat: rotate Home wishlist cards and add staggered per-card entrance animation"
```

---

### Task 8: Restyle the empty state, add/scan bottom sheet to the new palette

**Files:**
- Modify: `Wishie/Screens/Home/HomeView.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing consumed by later tasks (last visual task).

- [ ] **Step 1: Restyle the empty-state icon circle and CTA button**

Find:

```swift
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FEF3D7"), Color(hex: "#F9C46B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                Image("gift_img")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
```

Replace with:

```swift
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                Image("gift_img")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
```

Find:

```swift
            WishieButton(
                title: buttonTitle,
                enabled: true,
                filColor: Color(hex: "#F1D790"),
                width: 220,
                height: 48
            ) {
                action()
            }
```

Replace with:

```swift
            WishieButton(
                title: buttonTitle,
                enabled: true,
                filColor: Color(hex: "#FF9A76"),
                width: 220,
                height: 48
            ) {
                action()
            }
```

- [ ] **Step 2: Restyle the bottom sheet option icon box and border**

Find:

```swift
    @ViewBuilder
    func bottomSheetOption(image: String, title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#FEF3D7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#F9C46B"), Color(hex: "#F1D790")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .padding(.leading, 8)
                }
                .padding(.leading, 12)
                Text(title)
                    .font(.wishies(.bold, 16))
                    .foregroundStyle(Color.black)
                    .padding(.leading, 10)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.darkGrey)
                    .padding(.trailing, 16)
            }
        }
    }
```

Replace with:

```swift
    @ViewBuilder
    func bottomSheetOption(image: String, title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#FF9A76"), Color(hex: "#FEF3D7")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .padding(.leading, 8)
                }
                .padding(.leading, 12)
                Text(title)
                    .font(.wishies(.bold, 16))
                    .foregroundStyle(Color.black)
                    .padding(.leading, 10)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.darkGrey)
                    .padding(.trailing, 16)
            }
        }
    }
```

- [ ] **Step 3: Build the project**

Run:
```bash
xcodebuild build -project Wishie.xcodeproj -scheme Wishie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' 2>&1 | tail -40
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add Wishie/Screens/Home/HomeView.swift
git commit -m "style: restyle Home empty state and bottom sheet to the new palette"
```

---

### Task 9: Manual verification on simulator

**Files:** none (verification only).

**Interfaces:**
- Consumes: the fully built app from Tasks 1–8.
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
Expected: no `CTFontManager` font-registration errors or warnings about a
font named `Baloo2-*` failing to load.

- [ ] **Step 3: Visual pass against the mockup, empty/populated states**

Log in and navigate to Home. Confirm: cream gradient background with confetti, Baloo 2 greeting with a floating 🎉, white capsule tab selector with an orange-red active pill, two rotated stat tiles, rotated wishlist cards each with a corner sticker badge (🎉 TODAY / ⏰ OVERDUE / "Nd left" matching each wishlist's actual due date), a linear progress bar + "🎁 N/M" pill in each card's footer. Switch to a state with 0 wishlists and confirm the empty state still renders with the new sunset-colored icon/button.

- [ ] **Step 4: Functional regression pass**

Confirm all of the following still work exactly as before the redesign:
- Swipe-to-delete on "My list" shows the delete confirmation dialog and removes the wishlist on confirm.
- Swipe-to-leave on "Friend's list" shows the leave confirmation dialog.
- Tapping the add button opens the bottom sheet; both "Scan QR code" and "Create new wishlist" navigate correctly.
- Tapping the profile icon opens `ProfileView`.
- Pull-to-refresh reloads the list.
- Tapping a wishlist card triggers the zoom transition into `WishlistDetailScreen` (confirm it animates smoothly from a *rotated* card, not just an unrotated one).
- For a fresh account (`hasSeenHomeTutorial == false`), the coach-mark tutorial appears and its highlight boxes still land on the tab selector, add button, and example card correctly (none of these three are rotated, so this should be unaffected, but confirm visually).

- [ ] **Step 5: Confirm the entrance animation replays**

From Home, tap into a wishlist's `WishlistDetailScreen`, then navigate back. Confirm the greeting/tab/stat-tiles/cards fade-and-slide-in animation plays again (not just on first launch). This is the one behavior in this plan that depends on `NavigationStack`'s actual `onAppear`/`onDisappear` timing rather than something verifiable from source alone — if it does **not** replay, `.onAppear`/`.onDisappear` are not firing on pop as expected, and `homeAppeared`'s reset needs to move to `.onDisappear` of the specific `WishlistDetailScreen` push path or be driven by `path` count changes instead (`.onChange(of: path)`).

- [ ] **Step 6: Confirm the theme picker and detail screen reflect the new palette**

Go through wishlist creation to the theme picker step and confirm all 4 swatches render as smooth gradients (not stretched/broken images) and match the new vivid colors. Pick each theme, finish creating a wishlist, and confirm `WishlistDetailScreen`/`WishItemDetailView` show the same vivid color for that theme.

- [ ] **Step 7: Report result**

If everything renders and behaves correctly, this task is done — no commit needed (no files changed in this task). If Step 5's animation replay doesn't work, fix it, verify again, and commit that fix separately before considering the plan complete.

# Home Screen Redesign (Celebration Sticker Theme)

## Context

The current Home screen (`Wishie/Screens/Home/HomeView.swift` +
`HomeItemViewCell.swift`) already carries a "celebration" gradient-card
theme from an earlier redesign pass (PR history: "Redesign Home View UI
with Celebration Theme", coach-mark tutorial, App Store-style zoom
transition). This spec replaces that visual language with a new, more
saturated "scrapbook / sticker" design imported from a Claude Design
project (`claude.ai/design/p/45500a5b-be49-4f28-aa0b-40288a4338b2`,
file `Home Screen Redesign.dc.html`).

The new design: rotated sticker-style wishlist cards, corner status
badges (TODAY / OVERDUE / "Nd left"), a two-tile rotated stat summary,
a white capsule tab selector with a vivid gradient active pill, confetti
decoration, and a staggered fade/rotate-in entrance animation using the
`Baloo 2` display font. The mockup's sample data (wishlist names "Lan's
Birthday", "Test", "Test wishlist") matches real data already in the
app's Firestore, and its card colors line up 1:1 with the existing
`GradientTheme` cases by hue (sunset↔orange-red, ocean↔teal,
purpleDream↔purple) — confirming the new palette is a re-tint of the
existing theme system, not a new independent color mechanism.

Decisions already confirmed with the user:
1. Add real `Baloo 2` as a new bundled font family (not an approximation
   using Nunito).
2. Re-tint `GradientTheme`'s hex values app-wide (Home, wishlist detail,
   theme picker), not just on Home.
3. Replace `HomeItemViewCell`'s circular progress ring + inline pills
   with the mockup's linear progress bar + corner sticker badge, exactly
   as designed.
4. The staggered entrance animation replays every time `HomeView`
   appears (not just once per session).

## Goal

Reskin the Home screen to match the imported design pixel-for-pixel
where specified, while preserving all existing behavior: real-time
wishlist observing, swipe-to-delete/leave, the add/scan bottom sheet,
profile navigation, the coach-mark tutorial overlay, the App Store-style
zoom transition into `WishlistDetailScreen`, and the empty state.

## Design

### 1. Typography — add Baloo 2

New file `Wishie/Resources/Fonts/`:
- `Baloo2-SemiBold.ttf` (600)
- `Baloo2-Bold.ttf` (700)
- `Baloo2-ExtraBold.ttf` (800)

Sourced from Google Fonts' `Baloo 2` family (OFL license, same license
family as the existing Nunito files). Only these 3 weights are needed —
the mockup never uses 400/500. Baloo 2 ships no italic style, so italic
text keeps using `Nunito-Italic` (real italic, per the recent Nunito
migration's explicit goal of avoiding synthetic slant).

Add a license file `Wishie/Resources/Fonts/Baloo2-OFL.txt` (Baloo 2's own
OFL copyright text) alongside the existing `OFL.txt` (Nunito's), since
these are two independently-licensed font families now.

`Info.plist`'s `UIAppFonts` array gains the 3 new filenames.

`WishieCustomFont.swift` gets a second enum + helper, mirroring the
existing pattern rather than overloading `WishieFont`:

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

Usage split (matches the mockup's actual inline styles):
- **Baloo 2** (`.wishiesDisplay`): greeting ("Hey, Khang!"), stat tile
  numbers/labels, tab selector labels, wishlist card titles, wishlist
  card dates, progress/gift-count pill text, corner sticker badge text.
- **Nunito** (`.wishies`, unchanged): subtitle ("Your celebrations
  await"), wishlist description (italic), empty-state copy, dialogs,
  every other screen in the app.

### 2. Color system — re-tint `GradientTheme` app-wide

`Wishie/Models/GradientWishlishTheme.swift` hex values change:

| case | primary (was) | primary (new) | secondary (was) | secondary (new) |
|---|---|---|---|---|
| sunset | `#FEF3D7` | `#FF9A76` | `#F1D790` | `#F4667A` |
| ocean | `#cbf1f5` | `#6FE3D0` | `#71c9ce` | `#38B7B0` |
| purpleDream | `F4EEFF` | `#B79CF2` | `#dcd6f7` | `#9C7BE0` |
| forest | `#bcd9a2` | `#8DE0A0` | `91C788` | `#3FAE72` |

`forest` isn't in the source mockup (which only shows 3 of the 4 themes)
— its new values are extrapolated to match the other three's
lightness/saturation pattern (light minty tone → deeper saturated tone,
same tonal distance). Flagged as a judgment call for the user to eyeball
once built, since it wasn't handed to us directly.

This changes color for every existing consumer of `.theme.primary` /
`.theme.secondary`: `HomeItemViewCell`, `WishlistDetailScreen`,
`WishItemDetailView`, `CreateWishlistPage3` — no code changes needed in
those files since they already read through `GradientTheme`, just a
visual change.

**Theme picker swatches** (`CreateWishlistPage3.swift`): currently
`Image(theme.imageName)` renders a static bitmap
(`sunset.imageset`/`ocean.imageset`/etc.) that will NOT reflect the new
hex values once changed — a bitmap can't read Swift constants. Replace
the swatch with a code-rendered gradient:

```swift
RoundedRectangle(cornerRadius: 10)
    .fill(
        LinearGradient(
            colors: [Color(hex: theme.primary), Color(hex: theme.secondary)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
```

keeping the existing `.aspectRatio(contentMode: .fit)` sizing, shadow,
and selection stroke overlay. The now-unused `.imageset` assets are left
in place (out of scope to clean up unrelated assets).

### 3. Background & decoration — scoped to Home only

`BaseWishieScreen.swift` currently hardcodes
`Color.lightYellow1.ignoresSafeArea()` as the background for every
screen that uses it. Add an optional `background` parameter defaulting
to today's behavior, so no other screen changes:

```swift
struct BaseWishieScreen<Background: View, TopBar: View, Content: View>: View {
    let background: Background
    let topBar: TopBar
    let content: Content

    init(
        @ViewBuilder background: () -> Background = { Color.lightYellow1 },
        @ViewBuilder topBar: () -> TopBar,
        @ViewBuilder content: () -> Content
    ) { ... }

    var body: some View {
        ZStack(alignment: .top) {
            background.ignoresSafeArea()
            ...
        }
    }
}
```

`HomeView` passes a `background:` closure containing:
- `LinearGradient` cream background (`#FFF8E8 → #FBEACB`, top to bottom).
- 4 small static confetti shapes (rounded square, 2 circles, 1 circle
  with a continuous slow float animation) at fixed offsets, matching the
  mockup's positions/colors.
- 1 soft radial-gradient glow blob, top-right, low opacity, static.

All decorative shapes are `allowsHitTesting(false)` so they never
intercept taps.

### 4. Top bar

`topAppBar()` in `HomeView.swift`:
- Greeting text switches to `.wishiesDisplay(.extraBold, 28)`, color
  `#5B3F0F`, with the 🎉 emoji as a separate `Text` with a continuous
  float animation (`repeatForever`, translateY-style via
  `.offset(y:)` animated between 0 and -6).
- Subtitle stays Nunito, updates color to `#9A7A3E`.
- Add button: rounded-square (14pt corner radius) `44x44`, orange-red
  gradient (`sunset` theme colors), rotated 6°, `+` glyph — replaces
  today's circle. Keeps its existing `anchorPreference` key
  (`homeAddButton`) and `onTapGesture { activeSheet = .add }` untouched
  so the tutorial overlay keeps targeting it correctly.
- Profile button: stays a circle, outline restyled to the new sunset
  gradient stroke.

### 5. Tab selector

`tabSelector`/`tabItem` in `HomeView.swift`: wrap in a white capsule
track (`Color.white`, 5pt padding, thin `#E9D8AC` border) instead of the
current translucent-white/gold-stroke capsule. Active tab's
`matchedGeometryEffect` capsule becomes the sunset gradient
(`#FF9A76 → #F4667A`) instead of today's gold gradient. Label font
becomes `.wishiesDisplay(.bold, 15)`. Existing tap-to-switch behavior and
`anchorPreference` (`homeTabSelector`) unchanged.

### 6. Stat summary — two rotated tiles

Replace `summaryCard()` (today: one horizontal bar with a vertical
divider) with two independent tiles side by side, each its own rotated
sticker:
- Left tile: teal fill, rotated -2°, shows wishlist count + "Wishlists"
  label.
- Right tile (only shown when `nearestDueDate` exists, preserving today's
  conditional): purple fill, rotated +2°, shows "🎉 Nd" / "Today!" +
  "Next Event" label.

Both use `.wishiesDisplay(.extraBold, 22)` for the value and
`.wishiesDisplay(.bold, 12)` for the label, matching the mockup.

### 7. Wishlist cards (`HomeItemViewCell.swift`)

- `themeBackground`: unchanged mechanism (theme primary→secondary
  gradient), now visually vivid due to the color system change (§2).
- New: alternating rotation per card, applied at the call site in
  `HomeView.swift`'s `ForEach` (not inside the cell itself, so the cell
  stays a pure component) — e.g. `rotationEffect(.degrees(index % 2 == 0
  ? -1 : 1.5))`.
- New corner sticker badge, positioned via `.overlay(alignment: .topTrailing)`
  with a negative offset so it sits above the card edge: reuses the
  existing `daysRemaining`/`isUrgent`/`isOverDue` logic already in the
  cell to pick between "🎉 TODAY" / "⏰ OVERDUE" / "Nd left", each with
  its own badge background/text color per the mockup (soft-gold for
  TODAY, white for the other two).
- `headerRow`: avatar circle moves to the top-right of the card (as
  today), name/date stay top-left; avatar size/border matches the
  mockup's `50x50` on the hero card. Title font becomes
  `.wishiesDisplay(.extraBold, 19–21)` depending on card prominence;
  date row switches to `.wishiesDisplay(.semiBold, 13)` (matches the
  mockup's 600-weight date text), color `rgba(255,255,255,0.9)`
  equivalent.
- `footerRow`: replace the circular `Circle().trim` progress ring +
  2 pills with:
  - a linear progress bar (`Capsule` track at 30% white opacity, filled
    `Capsule` sized by `progress`, white fill) — reuses the existing
    `progress` computed property.
  - a single "🎁 N/M gifts" (or "No gifts yet") pill, `.wishiesDisplay`,
    white-translucent capsule background — reuses `itemPicked`/`item.0.items.count`.
  - The urgency pill that used to live in the footer is removed (its
    info now lives in the corner sticker badge from the new §7 bullet
    above), avoiding duplicated status info.
- `decorativeOverlay` (translucent circles): kept as-is, still reads well
  against the more saturated gradients.

### 8. List container adjustments (`HomeView.swift`)

Keep `List` — not switching to `ScrollView`. Rationale: `List` already
gives `.swipeActions`, `.refreshable`, and the `anchorPreference` calls
the coach-mark tutorial depends on (`CoachMarkBoundsKey`); reimplementing
swipe-to-delete/leave by hand on a `ScrollView` would be strictly more
code and more risk for no product benefit.

Change: bump `.listRowInsets` vertical padding (top especially, to leave
room for the corner badge's negative offset) and `.listRowSpacing` so
neighboring rows don't clip each other's rotated bounding box / shadow.
Exact values tuned visually during implementation, starting from the
mockup's ~22pt inter-card gap plus badge overshoot (~14pt).

`matchedTransitionSource`/`.navigationTransition(.zoom(...))` wiring is
untouched — it's applied to the outer `ZStack`, independent of the
card's internal visual redesign.

### 9. Entrance animation

New `@State` tracking whether entrance animation has fired for the
current appearance, reset `onAppear`/`onDisappear` of `HomeView` so it
replays every time the screen appears (confirmed with user — including
returning from `WishlistDetailScreen`, switching back from Profile,
tab-switching within the app if applicable).

Each element gets `.opacity(appeared ? 1 : 0)`, `.offset(y: appeared ? 0
: 26)`, and (for rotated elements) animates its rotation degrees in from
0 to its resting rotation, driven by `.animation(.timingCurve(0.22, 1,
0.36, 1, duration: 0.5), value: appeared)` with a per-element `.delay(...)`:

| element | delay |
|---|---|
| greeting | 0.05s |
| subtitle | 0.12s |
| tab selector | 0.18s |
| stat tile 1 | 0.24s |
| stat tile 2 | 0.30s |
| wishlist card *i* | `0.36 + min(i, 6) * 0.08`s |

Capping the wishlist-card stagger at index 6 keeps large lists from
producing a slow, draggy entrance — cards beyond the 6th all animate in
together at the capped delay.

The 🎉 emoji float and the one floating confetti dot use a separate,
non-staggered `repeatForever` animation that starts independently
`onAppear` (not part of the entrance sequence — it's a continuous idle
loop, matching the mockup's `floatSlow` keyframe).

### 10. Empty state, dialogs, bottom sheet

`contentUnavailable`, `bottomSheet`, `bottomSheetOption` keep their
current structure; only their hardcoded hex colors update to pull from
the new palette (e.g. the gift-icon circle gradient uses the new sunset
values) for visual consistency. No structural changes — the mockup
doesn't depict these states.

## Out of scope

- No changes to `HomeViewModel`, Firestore queries, or real-time
  observing logic.
- No changes to `WishlistDetailScreen`/`WishItemDetailView` beyond the
  automatic visual effect of the `GradientTheme` re-tint.
- No changes to the coach-mark tutorial's content/copy or trigger logic
  — only ensuring its anchors still point at the right (now restyled)
  elements.
- No Dynamic Type-specific redesign; existing font-scaling behavior is
  inherited as-is.
- No app icon / launch screen changes.

## Testing

- Build and run in the Simulator; confirm no missing-font console
  warnings for the 3 new Baloo 2 weights.
- Visually compare against the mockup for the 0-wishlist, 1-wishlist,
  and many-wishlist (8+, to check stagger cap) states, both tabs.
- Confirm swipe-to-delete (My list) and swipe-to-leave (Friend's list)
  still work and still show their confirmation dialogs.
- Confirm the coach-mark tutorial still appears for a fresh
  `hasSeenHomeTutorial == false` state and highlights the right
  elements.
- Confirm the zoom transition into `WishlistDetailScreen` still animates
  correctly from a rotated card.
- Confirm the theme picker in wishlist creation shows the new gradient
  swatches and that `WishlistDetailScreen`/`WishItemDetailView` reflect
  the new colors for all 4 themes.
- Re-trigger the entrance animation by navigating away and back to
  confirm it replays.

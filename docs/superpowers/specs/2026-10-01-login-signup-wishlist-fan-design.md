# Login / Sign up Screen: Wishlist Fan Redesign

## Context

`LoginOrSignUpScreen` is the first screen an unauthenticated user sees
(`MainView` shows it for `appState == .unauthenticated`). Today it is a
dark screen: a dimmed photo background, two rows of tilted stock photos
(`bgimg1`–`bgimg8`) scrolling sideways via `BackgroundAnimationView`,
the logo, and two full-width buttons ("Login" in yellow, "Sign up" in
black).

Onboarding has since moved to the "Warm Refined" look: cream
`obScreenBg`, `obInk` text and buttons, `Baloo 2` headlines, `Nunito`
body. The auth screen is now the only dark, photo-led screen in that
flow, and the photos say nothing about what the app does.

The user compared four mockups
(`https://claude.ai/artifact/4u7MsfM3q9EoSBBP7fGSxW`) and chose option
B, "wishlist fan", with two changes agreed during brainstorming:

1. Cards use the app's real `GradientTheme` colors (as on Home), not
   the pastel `sunset` / `ocean` / `purple_dream` color assets shown in
   the mockup.
2. **Login is the large primary button; Sign up is the text link below
   it.** (The mockup shows the reverse.)

## Goal

Replace the scrolling-photo auth screen with a light screen that shows
three fanned wishlist cards, so a new user understands the product at a
glance and the screen matches onboarding. Navigation to `LoginView` and
`SignUpView` behaves exactly as it does today.

## Success criteria

- The screen matches the layout below on both a small phone (iPhone SE
  3rd gen) and a large one (iPhone 16 Pro Max): nothing clipped, no
  overlap between cards and text, buttons fully visible.
- Tapping "Login" pushes `LoginView`; tapping the "Sign up" link pushes
  `SignUpView`; both still receive `authViewModel`.
- With Reduce Motion on, the cards do not move.
- `bgimg1`–`bgimg8` and `BackgroundAnimationView` no longer exist in
  the project, and the app builds.
- All existing tests still pass.

## Design

### Files

| File | Change |
|------|--------|
| `Wishie/Screens/Auth/LoginOrSignUpScreen.swift` | Rewrite the body. Keep `NavigationStack`, `path`, and the `login` / `signup` destinations. Remove `listImage`, `listImage2`, and `BackgroundAnimationView`. |
| `Wishie/Screens/Auth/WishlistFanView.swift` | New. The three fanned cards, their sample data, and the sway animation. |
| `Wishie/Resources/Assets.xcassets/bgimg1.imageset` … `bgimg8.imageset` | Delete (about 34 MB). Only `LoginOrSignUpScreen` references them. |

The Xcode project uses file-system-synchronized groups
(`PBXFileSystemSynchronizedRootGroup`), so adding
`WishlistFanView.swift` and deleting the imagesets on disk is enough;
`project.pbxproj` is not edited.

### Screen layout (`LoginOrSignUpScreen`)

A `VStack(spacing: 0)` on an `obScreenBg` background that ignores the
safe area.

**Stage (top).** A `lightYellow` rectangle with only its two bottom
corners rounded (radius 44), extending under the status bar. Height is
54% of the screen height. `WishlistFanView` is centered inside it,
below the top safe area.

**Copy (below the stage).** Leading-aligned, 30pt horizontal padding
(same as onboarding), 24pt below the stage:

- Brand row: `Image("pen")` at 28×28 clipped to a rounded rectangle
  (radius 7), then "Wishie" in `.wishiesDisplay(.bold, 18)`, `obInk`.
- Headline: "Make a list.\nShare one link." in
  `.wishiesDisplay(.bold, 32)`, `obInk`, 8pt below the brand row.
- Subtext: "Friends reserve a gift, so nobody buys the same thing
  twice." in `.wishies(.regular, 16)`, `obInk` at 70% opacity, 8pt
  below the headline.

**Actions (pinned to the bottom).** A `Spacer` separates copy from
actions. 30pt horizontal padding, 40pt bottom safe-area padding (same
as onboarding).

- Primary: `WishieButton(title: "Login", enabled: true, filColor:
  Color("obInk"), titleColor: .white)`. Appends `"login"` to `path`.
- Link, 6pt below the button: a plain `Button` whose label is
  "Don't have an account? " in `.wishies(.regular, 15)` followed by
  "Sign up" in `.wishies(.bold, 15)` with an underline, all `obInk`,
  centered. The whole line is the tap target, with a minimum height of
  44pt. Appends `"signup"` to `path`.

On a small screen the headline may scale down: apply
`.minimumScaleFactor(0.8)` to the headline and let the subtext wrap to
at most 3 lines.

### Fanned cards (`WishlistFanView`)

**Sample data.** A private, file-local array of three values. No
network, no models from `Wishie/Models` other than `GradientTheme`.

| Position | Title | Subtitle | Theme | Items (name · reserved) |
|----------|-------|----------|-------|--------------------------|
| Front | Birthday 2026 | 12 items · 3 reserved | `.coral` | AirPods Pro · yes; Lego Orchid · no; Film camera · no; Running shoes · yes |
| Back left | Housewarming | 8 items | `.mint` | Moka pot · no; Desk lamp · no; Linen set · no |
| Back right | Tết wishlist | 5 items | `.grape` | Kindle · no; Tea set · no; Sketchbook · no |

**Card appearance.** Modeled on `HomeItemViewCell` so the preview looks
like what the user gets after signing in:

- Fill: solid `Color(hex: theme.primary)`.
- Shape: `RoundedRectangle(cornerRadius: 22)`.
- Decoration: two white circles clipped to the card, one 90pt at 16%
  opacity at the top-trailing corner, one 44pt at 8% opacity at the
  bottom-leading corner.
- Shadow: `Color(hex: theme.primary).opacity(0.45)`, radius 12, y 6.
- Title: `.wishiesDisplay(.bold, 18)`, white.
- Subtitle: `.wishies(.medium, 12)`, white at 85% opacity.
- Item row: white rounded rectangle (radius 12), 8pt padding, holding
  a 24×24 swatch (radius 7, `Color(hex: theme.primary)` lightened by
  0.6), the item name in `.wishies(.bold, 13)` `obInk` on one line with
  tail truncation, and, when reserved, a "Reserved" tag in
  `.wishies(.bold, 10)`, `lightYellow` text on an `obInk` rounded
  rectangle (radius 6).
- Rows are spaced 7pt apart; card padding is 14pt.

**Sizing.** `WishlistFanView` takes its width from its container. Card
width is 56% of the available width, capped at 240pt. Fonts and paddings
above are fixed point sizes; only the card width scales.

**Fan.** The front card is upright and drawn last. The two back cards
rotate around an anchor below their bottom edge
(`UnitPoint(x: 0.5, y: 1.2)`): back left rests at −14°, back right at
+14°. That anchor is what makes them fan out sideways rather than spin
in place.

**Sway.** On appear, a single `@State` Boolean flips inside
`withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses:
true))`, moving the back cards between ±14° and ±17° (a 6-second round
trip). The front card does not move.

**Reduce Motion.** Read `@Environment(\.accessibilityReduceMotion)`.
When it is true, do not start the animation; the cards stay at ±14°.

**Accessibility.** The whole fan is decorative:
`.accessibilityHidden(true)`. The copy, button, and link remain
readable by VoiceOver.

### Previews

- `WishlistFanView`: one `#Preview` on a `lightYellow` background.
- `LoginOrSignUpScreen`: one `#Preview` injecting `AuthViewModel()` as
  an environment object.

## Out of scope

- `LoginView`, `SignUpView`, `ForgotPasswordView`, `WelcomeView`, and
  onboarding.
- A Google or Apple sign-in button on this screen.
- Dark-mode variants. The screen uses the same fixed light palette as
  onboarding (`obScreenBg` and `obInk` have identical light and dark
  values).
- Localization of the new strings; the app's existing strings on this
  screen are hard-coded English.
- Changing `WishieButton`.

## Testing and verification

This is a presentation-only change and the project has no snapshot-test
infrastructure, so no new unit tests are added for the views.

- Build the `Wishie` scheme for an iOS simulator; it must succeed with
  no reference to `bgimg*` or `BackgroundAnimationView` remaining
  (`grep` returns nothing).
- Run the existing `WishieTests` suite; it must pass.
- Launch on iPhone SE (3rd generation) and iPhone 16 Pro Max
  simulators in the unauthenticated state. Take a screenshot of each
  and compare with mockup B (allowing for the two agreed changes).
- Tap "Login" and confirm `LoginView` appears; go back, tap "Sign up"
  and confirm `SignUpView` appears.
- Turn on Reduce Motion in the simulator and confirm the cards are
  still.

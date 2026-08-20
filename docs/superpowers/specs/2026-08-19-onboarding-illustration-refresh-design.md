# Onboarding Canvas Illustration Refresh

## Context

`Onboarding.dc.html` is a Claude Design canvas
(`claude.ai/design/p/45500a5b-be49-4f28-aa0b-40288a4338b2`) holding a
3-screen onboarding mockup — gift boxes / birthday cake / party popper —
built on the shared `IOSDevice` frame (`ios-frame.jsx`). It uses a warm
cream palette (`#EFE7D8` canvas / `#FBF3E4` screen background), `Baloo 2`
+ `Nunito` typography, and a `#F4667A` pink accent. This is a separate,
more polished design direction than what currently ships in the app
(`Wishie/Screens/OnboardingContainerView.swift`), which uses full-bleed
dark photo backgrounds, a typewriter headline effect, and a yellow CTA.

This spec covers only the design canvas file (`Onboarding.dc.html`).
Bringing any of this into the SwiftUI app is out of scope and not part
of this request.

Through visual-companion mockups, the user chose:
1. **"Warm Refined"** as the overall direction — keep the current cream
   base, `Baloo 2`/`Nunito` typography, and layout; do not adopt any of
   the other explored directions (Sunset Duotone, Papercut Bold, 3D
   Clay).
2. **"Literal objects, recolored"** — the three illustrations keep their
   current subject matter (gift boxes, cake, party popper) rather than
   becoming abstract gradient shapes; only their rendering style changes.
3. Copy stays unchanged.
4. UI accent elements (CTA circle/pill, pagination dots, Skip button)
   stay solid `#241A08` — the gradient is not extended to them.

## Goal

Re-render the three onboarding illustrations in a pink→coral gradient
duotone style (`#F4667A → #FFB27A`), replacing their current flat
multi-color rendering, while leaving every other part of the canvas —
copy, layout, animation timing, palette, typography, UI chrome — exactly
as it is today.

## Design

### Illustration assets

The three illustration files (`uploads/1.png` "Gift boxes",
`uploads/2.png` "Birthday cake", `uploads/3.png` "Party popper") are
replaced with new artwork supplied by the user, matching the pink→coral
gradient duotone style validated in the visual-companion mockup, sized
to roughly the same display widths already set inline
(268px / 282px / 268px). The implementation step asks the user for each
file by name (which screen it replaces) rather than substituting
placeholder art.

### Drop-shadow tint

Each `<img>`'s `filter: drop-shadow(...)` currently uses a neutral dark
tint (`rgba(36,26,8,0.16)`). Since a neutral-dark shadow reads as muddy
under brighter gradient artwork, shift it to a coral-tinted glow —
`rgba(244,102,122,0.25)` — on all three screens. This is the one
non-asset code change in `Onboarding.dc.html`.

### Everything else unchanged

No changes to: headline/subtext copy, `heroFloat`/`heroPop`/`lineUp`/
`fadeUp`/`popIn` animation keyframes or timing, pagination dots, Skip
button, CTA circle/pill (screens 1–2) or "Get started" pill (screen 3),
the `IOSDevice` frame usage, or the replay-animation control script.

## Out of scope

- The SwiftUI app's actual onboarding implementation
  (`OnboardingContainerView.swift`) — this spec only touches the design
  canvas.
- Any other file in the design project (`Home Screen Redesign.dc.html`,
  `ios-frame.jsx`, `support.js`).
- Copy changes, layout changes, new/removed screens, or changes to UI
  chrome color.

## Verification

- After the new illustration files are in place and the shadow tint is
  updated, replay the canvas animation (via the existing "↺ Replay
  animation" control) on all three screens and visually confirm the
  gradient artwork reads cleanly against the cream background with the
  new coral-tinted shadow.
- Confirm no other visual element moved or changed color as a side
  effect of the asset swap.

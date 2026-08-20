# Onboarding Canvas Illustration Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Re-render the three onboarding illustrations in `Onboarding.dc.html` (gift boxes, birthday cake, party popper) in a pink→coral gradient duotone style, and re-tint their drop-shadows to match — with no other visual, copy, or timing change to the canvas.

**Architecture:** This is a design-asset swap on a Claude Design canvas, not a code change in this git repository — `Onboarding.dc.html` lives at `claude.ai/design/p/45500a5b-be49-4f28-aa0b-40288a4338b2` and has no local copy. Each of the three task groups below opens that canvas, replaces one illustration's image asset, and edits one CSS color value shared/repeated across the three `<img>` drop-shadow filters. There are no unit tests; each task's "test" is a visual check via the canvas's built-in "↺ Replay animation" control, per the spec's own Verification section.

**Tech Stack:** Claude Design canvas editor (claude.ai/design), HTML/CSS (`Onboarding.dc.html`, shared `IOSDevice` frame from `ios-frame.jsx`).

**Spec:** [docs/superpowers/specs/2026-08-19-onboarding-illustration-refresh-design.md](../specs/2026-08-19-onboarding-illustration-refresh-design.md)

## Global Constraints

- Overall direction is locked to "Warm Refined": keep the cream base (`#EFE7D8` canvas / `#FBF3E4` screen background), `Baloo 2` + `Nunito` typography, and the current layout. Do not adopt Sunset Duotone, Papercut Bold, or 3D Clay.
- Illustrations keep their current literal subject matter (gift boxes, cake, party popper) — only the rendering style changes, to a pink→coral gradient duotone (`#F4667A → #FFB27A`).
- Copy (headline/subtext on every screen, Skip button, "Get started" pill) stays unchanged, character-for-character.
- UI accent elements — CTA circle/pill (screens 1–2), pagination dots, Skip button — stay solid `#241A08`. Do not extend the gradient to them.
- No changes to the `heroFloat`, `heroPop`, `lineUp`, `fadeUp`, `popIn` animation keyframes or their timing.
- No changes to the `IOSDevice` frame usage or the replay-animation control script.
- Out of scope, do not touch: `Wishie/Screens/OnboardingContainerView.swift` (the SwiftUI app), `Home Screen Redesign.dc.html`, `ios-frame.jsx`, `support.js`.

---

## Task 1: Collect the three replacement illustration files

**Target:** No canvas edit yet — this task only gathers and verifies the input assets.

- [ ] **Step 1: Ask the user for each of the three replacement PNG files by name**

Ask explicitly for three files, one per screen, matching the spec's naming:
- Screen 1 — "Gift boxes" (replaces `uploads/1.png`, displayed at `268px` wide)
- Screen 2 — "Birthday cake" (replaces `uploads/2.png`, displayed at `282px` wide)
- Screen 3 — "Party popper" (replaces `uploads/3.png`, displayed at `268px` wide)

Do not substitute placeholder art or generate stand-in images — wait for the user's actual files.

- [ ] **Step 2: Confirm each file matches the validated style**

For each of the three files the user provides, visually confirm it:
- Depicts the same literal subject as the screen it replaces (gift boxes / cake / party popper).
- Is rendered in the pink→coral gradient duotone style (`#F4667A → #FFB27A`) validated in the visual-companion mockup, not a flat multi-color or fully abstract rendering.
- Has a transparent (non-cream) background, matching how the current `uploads/1.png`/`2.png`/`3.png` composite over the `#FBF3E4` screen background.

If any file doesn't match, ask the user for a corrected version before proceeding — do not proceed with a mismatched asset and fix it later.

- [ ] **Step 3: Stage the files for upload**

Note the local path of each of the three confirmed files. No commit — these are working inputs for Tasks 2–4, not repository content.

## Task 2: Replace the Screen 1 illustration (Gift boxes)

**Target:** `Onboarding.dc.html`, Screen 1, the `<img>` currently sourcing `uploads/1.png`.

- [ ] **Step 1: Open the canvas**

Open `https://claude.ai/design/p/45500a5b-be49-4f28-aa0b-40288a4338b2` and open `Onboarding.dc.html` in the canvas editor.

- [ ] **Step 2: Locate the Screen 1 illustration element**

Find the `<img>` on Screen 1 whose `src` points at `uploads/1.png`. Confirm its inline width is `268px` before editing anything, so you can verify it's unchanged afterward.

- [ ] **Step 3: Replace the image asset**

Upload the "Gift boxes" file staged in Task 1 and point this `<img>`'s `src` at the new file (replacing `uploads/1.png`, or the equivalent new upload path the canvas editor assigns). Do not change the `<img>`'s `width`, `alt` text, class, or any surrounding markup.

- [ ] **Step 4: Verify Screen 1 renders correctly**

Use the "↺ Replay animation" control and watch Screen 1. Confirm:
- The new gradient artwork displays at the same `268px` width and same position as before.
- Nothing else on Screen 1 (headline, subtext, CTA circle/pill, pagination dots, Skip button) moved, resized, or changed color.
- The `heroFloat`/`heroPop`/`lineUp`/`fadeUp`/`popIn` timing on Screen 1 looks unchanged from before the swap.

Note: the drop-shadow will still look muddy at this point (neutral-dark tint against brighter artwork) — that's expected and is fixed in Task 5. Don't treat shadow color as a Task 2 failure.

## Task 3: Replace the Screen 2 illustration (Birthday cake)

**Target:** `Onboarding.dc.html`, Screen 2, the `<img>` currently sourcing `uploads/2.png`.

- [ ] **Step 1: Locate the Screen 2 illustration element**

In the same open canvas, find the `<img>` on Screen 2 whose `src` points at `uploads/2.png`. Confirm its inline width is `282px` before editing.

- [ ] **Step 2: Replace the image asset**

Upload the "Birthday cake" file staged in Task 1 and point this `<img>`'s `src` at the new file. Do not change `width`, `alt`, class, or surrounding markup.

- [ ] **Step 3: Verify Screen 2 renders correctly**

Replay the animation and confirm on Screen 2:
- New artwork displays at `282px` width, same position as before.
- No other Screen 2 element (headline, subtext, CTA circle/pill, pagination dots, Skip button) moved or changed color.
- Animation timing looks unchanged.

Same note as Task 2: the shadow tint fix is Task 5, not here.

## Task 4: Replace the Screen 3 illustration (Party popper)

**Target:** `Onboarding.dc.html`, Screen 3, the `<img>` currently sourcing `uploads/3.png`.

- [ ] **Step 1: Locate the Screen 3 illustration element**

Find the `<img>` on Screen 3 whose `src` points at `uploads/3.png`. Confirm its inline width is `268px` before editing.

- [ ] **Step 2: Replace the image asset**

Upload the "Party popper" file staged in Task 1 and point this `<img>`'s `src` at the new file. Do not change `width`, `alt`, class, or surrounding markup.

- [ ] **Step 3: Verify Screen 3 renders correctly**

Replay the animation and confirm on Screen 3:
- New artwork displays at `268px` width, same position as before.
- No other Screen 3 element (headline, subtext, "Get started" pill, pagination dots) moved or changed color.
- Animation timing looks unchanged.

## Task 5: Re-tint the drop-shadow on all three illustrations

**Target:** `Onboarding.dc.html` — the `filter: drop-shadow(...)` declaration(s) applied to the three illustration `<img>` elements from Tasks 2–4.

- [ ] **Step 1: Find every occurrence of the current shadow color**

Search the canvas's HTML/CSS for `rgba(36,26,8,0.16)` within a `drop-shadow(...)` filter. This may appear as a single shared CSS rule targeting all three `<img>`s, or as three separate inline `filter` declarations — check both before assuming which it is.

- [ ] **Step 2: Replace the color, keep the geometry**

For every occurrence found, replace only the color value: `rgba(36,26,8,0.16)` → `rgba(244,102,122,0.25)`. Leave the drop-shadow's x-offset, y-offset, and blur-radius numbers exactly as they are — only the color argument changes. This is the only non-asset code change this spec calls for.

- [ ] **Step 3: Verify all three screens**

Replay the animation and check all three screens in sequence. Confirm on each:
- The shadow under the illustration now reads as a coral-tinted glow, not a muddy dark smudge, against the new gradient artwork.
- No other filter, color, or layout property changed as a side effect.

- [ ] **Step 4: Full regression pass**

Replay the animation once more start to finish across all three screens and confirm, screen by screen:
- Headline/subtext copy is byte-for-byte what it was before this task (spec requires copy stays unchanged).
- CTA circle/pill (screens 1–2), "Get started" pill (screen 3), pagination dots, and Skip button are all still solid `#241A08` — none of them picked up the gradient or the coral shadow tint.
- Canvas background remains `#EFE7D8`, screen background remains `#FBF3E4`.
- Typography is still `Baloo 2` + `Nunito`.

If any of these regressed, fix it in the canvas before considering this plan complete — this spec explicitly requires everything except the three illustrations and their shadow tint to stay exactly as it was.

---

## Self-Review Notes

- Spec coverage: illustration assets (Tasks 1–4), drop-shadow tint (Task 5 Steps 1–2), "everything else unchanged" (Task 5 Steps 3–4 regression pass), out-of-scope files (Global Constraints) — all covered.
- No unit-test steps are included because the target is a visual design canvas with no test runner; verification throughout is the spec's own "Replay animation" visual check, matching the spec's Verification section.
- No `git commit` steps are included because the canvas is not part of this git repository and is versioned by claude.ai/design itself.

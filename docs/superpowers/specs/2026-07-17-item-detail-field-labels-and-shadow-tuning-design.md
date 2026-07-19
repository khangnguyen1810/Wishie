# Item detail sheet: field caption labels + shadow contrast tuning

Date: 2026-07-17
Status: Draft for review

## Motivation

After implementing the themed image glow shadow and themed focus border
(see `docs/superpowers/specs/2026-07-17-item-detail-theme-shadow-focus-border-design.md`),
the user compared a real screenshot of `WishItemDetailView` (edit flow,
`purpleDream` theme) against the original mockup and found two visible
gaps:

1. The image glow shadow is nearly invisible on `purpleDream` — the
   sheet's whole background is `primaryColor` (`#B79CF2`, light
   lavender), and the shadow color (`secondaryColor` at `0.4` opacity,
   `#9C7BE0`) is close enough in hue/lightness to the background that it
   visually disappears. This is a real defect in the already-shipped
   shadow, not new scope.
2. The mockup shows a small caption label (`TITLE`, `DESCRIPTION`,
   `PRICE`, `LINK`) above each field; the current implementation has
   none — fields only show placeholder text. This is new scope,
   explicitly out of scope in the prior spec, that the user now wants
   added.

Changing the sheet's overall background color, restyling the Save
button, and recoloring textfield fills remain out of scope (per the
user's explicit choice this round) — this spec covers only the shadow
contrast fix and the new caption labels.

## Scope

**In scope:**
- Increase the image glow shadow's opacity so it reads clearly against
  every theme's `primaryColor` background, not just against white.
- Add a caption label above each of the 4 fields (Item name,
  Description, Price, Link), matching the mockup's `TITLE` /
  `DESCRIPTION` / `PRICE` / `LINK` wording and visual weight as closely
  as practical within the app's existing type system.

**Out of scope:**
- Sheet background color (stays `primaryColor`, unchanged).
- Textfield fill color (stays `secondaryColor`, unchanged).
- Save button restyle (stays as-is).
- Price value text color (mockup shows a teal accent on the value —
  not requested this round).

## Shadow contrast fix

`WishItemDetailView.swift` currently has, in both image-box branches
(remote image display and the `ImagePickerBox` picker):

```swift
.shadow(color: secondaryColor.opacity(0.4), radius: 30, x: 0, y: 10)
```

Change `0.4` to `0.65` in both places, keeping `radius: 30, x: 0, y: 10`
unchanged. This is a one-value tuning of code shipped in commit
`68eb004` — no new modifiers, no new files.

## Field caption labels

The app has no existing "small uppercase caption above a field" pattern
(confirmed by searching `Wishie/Screens/`) — the closest precedent,
`EditProfileView`, uses title-case bold-black labels
(`.wishies(.bold, 17)`, no color override, no uppercase). Since the
user chose to match the mockup's literal `TITLE`/`DESCRIPTION`/`PRICE`/
`LINK` wording and its muted-brown color over the `EditProfileView`
pattern, this introduces a new (but small, self-contained) label style
for this screen — it does not touch or generalize `EditProfileView`'s
pattern.

For color, reuse `Color(hex: "#8C7A5A")` — already present twice in
`Wishie/Screens/Detail/WishlistDetailScreen.swift:419,527` as this
app's established muted-brown accent — rather than inventing a new hex
value.

Add one `Text` immediately before each of the 4 `TextField`s in
`WishItemDetailView.swift`:

```swift
Text("TITLE")
    .font(.wishies(.bold, 12))
    .foregroundStyle(Color(hex: "#8C7A5A"))
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 20)
    .padding(.bottom, 6)
```

- Same `.padding(.horizontal, 20)` as the field below it, so the label
  aligns with the field's left edge.
- `.padding(.bottom, 6)` separates the label from its field; the
  field's own existing `.padding(.horizontal, 20)` immediately follows,
  so no extra top padding is needed on the field.
- The 4 labels are `"TITLE"`, `"DESCRIPTION"`, `"PRICE"`, `"LINK"` —
  placed directly above the name, description, price, and link fields
  respectively, in that order (unchanged field order).
- Literal caps strings (`"TITLE"`, not `.textCase(.uppercase)` on a
  title-case string) — matches how the rest of this codebase writes
  fixed display strings; no precedent for `.textCase` exists here.

## Testing

No unit-testable logic (pure SwiftUI view/style code). Verified
interactively on the simulator, same convention as the prior spec:
- Open the Add/Edit item sheet on the `purpleDream` theme: the image
  glow shadow is now visibly distinguishable from the sheet background.
- Each of the 4 fields shows its caption label (`TITLE`, `DESCRIPTION`,
  `PRICE`, `LINK`) directly above it, left-aligned with the field.
- Switch to another theme (e.g. `sunset` or `ocean`): shadow remains
  visible; labels are theme-independent (fixed brown), so they look
  identical across themes.

## Open questions / risks

- None outstanding — shadow opacity value and label wording/color were
  confirmed during brainstorming.

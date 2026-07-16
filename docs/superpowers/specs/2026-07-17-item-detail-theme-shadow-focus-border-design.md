# Item detail sheet: themed image shadow + themed focus border

Date: 2026-07-17
Status: Draft for review

## Motivation

`WishItemDetailView` (the Add/Edit item bottom sheet) currently renders
its image box and four `TextField`s with flat, unstyled visuals: no
shadow behind the image, and no border feedback when a field is
focused. The user wants both to react to the wishlist's `GradientTheme`
(the same `primary`/`secondary` hex colors already driving the sheet's
background and field fills), matching a provided mockup that shows a
soft themed glow behind the image and a themed ring around the
currently-focused field.

## Scope

**In scope:**
- A soft, theme-colored glow shadow behind the image box, in both
  states of `WishItemDetailView` (existing remote image / `ImagePickerBox`
  picker).
- A themed border that fades in around whichever of the 4 `TextField`s
  (name, description, price, link) currently has keyboard focus, and
  fades out on blur.
- A small reusable `ViewModifier` for the focus-border behavior, since
  it applies identically to all 4 fields.

**Out of scope:**
- Any change to the sheet's overall background color/layout, the Save
  button, or `ImagePickerBox` itself (it applies no styling today; all
  styling stays caller-side, as it already is).
- `GradientTheme` gains no new cases/fields — only `primary` and
  `secondary` (already present) are used.
- Any change to other screens, even ones with similar-looking
  unfocused text fields (e.g. `CreateWishlistPage2`).

## Visual design

**Image shadow** — applied after each branch's existing `.clipShape`,
using the wishlist's `secondary` theme color as a soft glow rather than
a tight drop shadow:

```swift
.shadow(color: secondaryColor.opacity(0.4), radius: 30, x: 0, y: 10)
```

Applied to:
- `WishieWebImage` in the `isEdit && localImage == nil` branch
  (`WishItemDetailView.swift:38-41`).
- The inner content `ZStack` inside `ImagePickerBox` in the other
  branch (`WishItemDetailView.swift:44-64`), after its existing
  `.background(Color.wishiePink).clipShape(...)`.

**Focus border** — a new `@FocusState` enum drives which field is
active:

```swift
private enum DetailField: Hashable {
    case name, description, price, link
}
@FocusState private var focusedField: DetailField?
```

Each of the 4 `TextField`s gets `.focused($focusedField, equals: .x)`.

A new `ViewModifier`, `FocusableFieldBackground`, replaces the
repeated `.background(secondaryColor).clipShape(RoundedRectangle(cornerRadius: 10))`
tail currently duplicated across all 4 fields:

```swift
struct FocusableFieldBackground: ViewModifier {
    let fillColor: Color
    let borderColor: Color
    let isFocused: Bool
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 2)
                    .opacity(isFocused ? 1 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

extension View {
    func focusableFieldBackground(fillColor: Color, borderColor: Color, isFocused: Bool) -> some View {
        modifier(FocusableFieldBackground(fillColor: fillColor, borderColor: borderColor, isFocused: isFocused))
    }
}
```

Usage on each field (example for the name field):

```swift
TextField("Item name", text: $viewModel.newItemName)
    .font(.wishies(.bold, 17))
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .focused($focusedField, equals: .name)
    .focusableFieldBackground(fillColor: secondaryColor, borderColor: primaryColor, isFocused: focusedField == .name)
    .padding(.horizontal, 20)
    .padding(.bottom, 12)
```

The same substitution applies to the description, price, and link
fields — only the `.focused(equals:)` case and each field's own
existing modifiers (font, `lineLimit`, `keyboardType`, etc.) differ.
`borderColor` is `primaryColor` for all 4 (chosen for contrast against
the `secondary`-colored fill), `fillColor` is `secondaryColor` (matches
current background), consistent with the shadow's use of `secondary`
for the image glow.

`FocusableFieldBackground` lives in `WishItemDetailView.swift` itself
(private to the file) — it's used nowhere else yet, so it isn't worth
extracting to `CustomView/` until a second call site appears.

## Testing

No unit-testable logic is introduced (pure SwiftUI view/style code, no
view-model or service changes). Verified interactively on the
simulator:
- Opening the Add/Edit item sheet shows a soft themed glow behind the
  image box, colored per the wishlist's theme.
- Tapping into each of the 4 fields shows a themed border fade in
  around just that field; tapping away/into another field fades it out
  smoothly and the new field's border fades in.
- Switching between a couple of different wishlist themes confirms the
  glow/border colors track `secondary`/`primary` correctly rather than
  being hardcoded.

## Open questions / risks

- None outstanding — shadow color/intensity and border color/scope/
  animation were all confirmed during brainstorming.

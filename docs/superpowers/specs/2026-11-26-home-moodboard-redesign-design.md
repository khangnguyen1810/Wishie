# Home "Wish moodboard" redesign

Source of truth: design canvas "Wishie Home — Layout Options", option K (4 artboards:
My list, Friend's list, My list empty, Friend's list empty).

## Layout

- Flat `obScreenBg` background (the decorative gradient/confetti goes away).
- Header: "Hey, {name}!" (Baloo 2 extraBold 32) + subtitle (Nunito semiBold 15).
  Trailing: coral 48pt rounded-square "+" button, 48pt circular avatar with 2pt coral ring.
- Tab selector: cream track (`#F1E6D3`, 50pt capsule), selected segment is white with a soft
  shadow; Nunito 16.
- **Featured card** (the nearest upcoming wishlist, else the first): full theme-colour card,
  radius 26. A 3×2 mosaic: the top wish fills a 2×2 white tile (with "Top wish" badge if it is the
  most-desired item, and its name at the bottom), two small tiles show the next items; the last
  small tile carries "+N" for the remaining items. Footer: friend's list shows an owner line
  "(avatar) Minh's wishlist" right before the name; then the name (Baloo 26), "Fri, 25 Dec ·
  0 of 14 picked" / "4 of 10 still free", and a big days-left counter on the right.
- **Compact cards** (every other wishlist): soft theme tint, radius 22, a 76pt 2×2 mosaic of up
  to four item images, owner line (friend's list), name (Baloo 19), "14 Feb · 2 of 5 picked",
  trailing "81d".
- On a friend's list an item the current user picked shows a dark "✓ Yours" tag. The owner avatar
  sits only next to the name, never over an item image.

## Empty states

A placeholder card in solid `#F1E6D3` (no dashed border): white 2×2 tile with the primary action
(coral "+" circle "Your first wish" / dark QR square "A friend's wishes"), pale cream tiles, and grey
bars standing in for text. Friend's empty adds a blank avatar next to the name bar. Below: headline,
short paragraph, dark full-width capsule button (Create wishlist / Scan a friend's QR). Friend's empty
also shows "Already joined one? Pull down to refresh." and supports pull-to-refresh.

## Subtitle copy

- My list: "N wishlist(s) coming up" (upcoming = due today or later); none upcoming → "What are
  you wishing for?".
- Friend's list: "N friend(s) are wishing" (distinct owners); none → falls back to the My list copy.

## Kept as-is

Context menus (Change info / Archive / Delete, Leave), navigation + zoom transitions, entrance
animation, pull-to-refresh with the gift Lottie, home tutorial anchors. `HomeItemViewCell` stays for
Archived and Edit Wishlist Info. The scroll-collapsing hero card is replaced by the featured card.

## Theme tints

`GradientTheme` gains `soft` (compact card), `tile` (pale mosaic tile) and `ink` (text on card) so
cards never use ad-hoc hex values.

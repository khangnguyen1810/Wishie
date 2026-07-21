# LinkPresentation as the primary metadata source

**Date:** 2026-07-21
**Status:** Approved for planning

## Problem

`ProductMetadataService.fetchMetadata` currently delegates every request to
`WebViewMetadataExtractor`, which loads the page in a hidden `WKWebView`, waits,
then runs a large JavaScript extraction script. Two things are wrong with this:

1. **It is slow.** Measured 9.0–13.5s per link.
2. **Its main investment does not pay off.** Roughly 100 lines of the extraction
   script exist to scrape a price — OG tags, JSON-LD, `__NEXT_DATA__`, DOM
   scanning by font size, five retries. It returned no price on any tested site.

`LPMetadataProvider` (LinkPresentation) fetches the same class of information in
1.5–4.2s and returns a decoded image, at the cost of never providing a price.

## Measurements

Run on 2026-07-21, iPhone 17 simulator, three real product links.

| Site | Source | Time | Title | Image | Price | Canonical URL |
|---|---|---|---|---|---|---|
| Shopee | LP | 1.9s | — | — | n/a | yes |
| Shopee | WebView | 9.0s | homepage title only | — | — | no, bot-walled |
| Lazada | LP | 1.5s | yes | yes, 1024×1024 | n/a | no |
| Lazada | WebView | 13.5s | yes | yes, as URL | — | yes |
| Amazon | LP | 4.2s | yes, short | yes, 1024×536 | n/a | yes |
| Amazon | WebView | 12.8s | yes, full | — | — | yes |

Two findings drive this design:

- **Price extraction fails on all three sites.** Whatever we do about
  LinkPresentation, the current price scraping delivers nothing on the targets it
  was written for.
- **Shopee actively blocks the WebView**, redirecting to
  `shopee.vn/verify/traffic/error`. LinkPresentation does not get a title there
  either. Neither approach solves Shopee.

**Caveat on the measurement environment.** The machine sits behind a TLS-intercepting
DLP proxy (CoSoSys Endpoint Protector). The simulator had to be given that root
certificate for any HTTPS to succeed. Shopee's bot detection may be reacting in part
to that proxy, so the Shopee result should be re-confirmed on a clean network before
being treated as settled.

## Decision

Price is a nice-to-have — users can type it in. Speed, title, and image are what
matter. So: **try LinkPresentation first, fall back to the WebView extractor.**

The WebView extractor is kept rather than deleted. Only three hostile marketplaces
were measured; on ordinary shops and blogs with complete OG tags it still works, and
it remains the only path that could ever recover a price.

### Fallback condition

A LinkPresentation result counts as usable only when it has **both a non-empty title
and an image**. Title alone is not enough, because the gift-suggestion flow requires
an image.

For the three measured sites this criterion behaves identically to the looser
"title only" rule — Lazada and Amazon return both fields, Shopee returns neither. It
differs only for untested sites, where it buys safety at no measured cost.

### Resolution order

1. Validate the URL (unchanged: must parse, scheme must be `http`/`https`).
2. Try the LinkPresentation extractor. It throws when it has no usable title, so a
   returned result always has one.
3. If that result also has an image, return it.
4. Otherwise try the WebView extractor.
5. If the WebView result has no image but the LinkPresentation result did, attach
   that image to it before returning.
6. If the WebView extractor fails but the LinkPresentation extractor returned a
   result, return that result rather than failing.
7. If both fail, throw. Existing call sites already surface the error.

## Components

### `ProductMetadata` — add a local image

Add `localImage: UIImage?`, defaulting to `nil`.

`LPLinkMetadata` exposes its image as an `NSItemProvider` yielding a `UIImage`. It
deliberately does not expose the image URL, so an LP-sourced result cannot populate
`imageUrl`.

This mirrors `WishlistItem`, which already carries both `image: String?` and
`localImage: UIImage?`. The pattern and its upload path already exist; this change
extends them rather than introducing a new concept. Existing consumers compile
unchanged because the new field defaults to `nil`.

### `MetadataExtracting` — a shared protocol

```swift
@MainActor
protocol MetadataExtracting {
    func extract(from url: URL) async throws -> ProductMetadata
}
```

`WebViewMetadataExtractor` already has this exact shape and adopts it as-is.

### `LinkPresentationMetadataExtractor` — new

Lives in `Wishie/Utils/`, next to `WebViewMetadataExtractor`. Wraps
`LPMetadataProvider` with a 10s timeout (measured worst case was 4.2s).

Field mapping:

| `ProductMetadata` | Source |
|---|---|
| `title` | `LPLinkMetadata.title`, trimmed |
| `productUrl` | `LPLinkMetadata.url`, falling back to the requested URL |
| `localImage` | loaded from `imageProvider` |
| `imageUrl` | always `nil` — LinkPresentation does not expose it |
| `productDescription` | always `""` — `LPLinkMetadata` has no description field |
| `price` | always `nil` — `LPLinkMetadata` has no price field |

The extractor **throws** when the trimmed title is empty rather than substituting a
placeholder. `WebViewMetadataExtractor` uses `"Unknown Product"` as its sentinel, but
this extractor must not: a placeholder title would read as non-empty and defeat the
fallback condition, silently stranding Shopee on an empty LinkPresentation result.
Absence is signalled by throwing, so the orchestrator sees it.

A fresh `LPMetadataProvider` is created per request; the class is single-use and
reusing an instance is a documented crash. `cancel()` is never called after
completion, for the same reason.

The mapping from `LPLinkMetadata` to `ProductMetadata` is a separate pure function so
it can be tested without touching the network.

### `ProductMetadataService` — orchestration

Takes both extractors through its initializer instead of constructing
`WebViewMetadataExtractor()` inline, defaulting to the real ones so call sites are
unaffected. This is what makes the resolution order testable without network access.

## Call site changes

Two are mechanical:

- `CreateWishlistViewModel.addItemFromMetadata` passes `metadata.localImage` into the
  new `WishlistItem`. The existing upload loop then converts it to a URL on save.
- `WishlistDetailViewController.setNewItemFromMetadata` assigns `metadata.localImage`
  to `newItemImage`. `addNewWishlistItem` already uploads that.

Two need care:

- **`GiftSuggestionViewModel.validate(ideas:)`** filters candidates on
  `metadata.imageUrl?.isEmpty == false`. Left alone, every LP-sourced result would be
  discarded, since `imageUrl` is always `nil` on that path. The filter must accept a
  `localImage` as well. This is the easiest thing in this change to overlook.
- **Three views render images through `WishieWebImage(url:)`**, which only accepts a
  URL string: `PasteLinkSheet`, `AddItemPasteLinkDetailSheet`, and
  `GiftSuggestionCard`. Each needs to render a `UIImage` when that is what is
  available. The shared handling belongs in one small view used by all three rather
  than repeated three times.

## Testing

- **Mapping:** unit-test `LPLinkMetadata → ProductMetadata` directly.
  `LPLinkMetadata`'s properties are settable, so cases can be constructed in-process:
  title present, absent, and whitespace-only (the latter two must throw); image
  present/absent; `url` present/absent.
- **Resolution order:** stub both extractors and assert each branch — LP usable means
  the WebView extractor is never invoked; LP without an image falls through; a
  WebView result missing an image inherits LP's; both failing throws.
- **Regression:** `GiftSuggestionViewModel` keeps a suggestion whose metadata has a
  `localImage` but no `imageUrl`. This is the trap named above, so it gets an
  explicit test.
- All tests stay hermetic. `WishieTests/LinkPresentationSpike.swift`, which hits the
  real network, is deleted as part of this work.

## Out of scope

- **Shopee.** Neither extractor retrieves a title. Shopee's bot detection is a
  separate problem needing its own investigation, and it is what the current branch
  was originally aimed at. This design does not claim to fix it.
- **Price extraction.** It currently returns nothing on all three target sites. That
  is worth its own investigation; this design neither improves nor removes it. The
  WebView extractor keeps its price logic intact.
- **Removing `WebViewMetadataExtractor`.** Retained as the fallback.

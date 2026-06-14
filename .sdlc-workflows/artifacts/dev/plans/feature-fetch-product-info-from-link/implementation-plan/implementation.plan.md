Add Product Link Auto-Fill Option to Wish Item Creation

# Requirement Context

## Current State

`CreateWishlistPage2` allows users to add wish items manually via inline `WishlistItemCard` editing. Tapping "Add another gift" appends an empty `WishlistItem` directly. The `WishlistItem` model holds `name`, `description`, `image` (remote URL), `localImage` (UIImage), and `itemLink` fields. There is no auto-fill capability and no `price` field on items.

## Goals

1. Present a bottom sheet with two choices when users add a new wish item: paste a product link (auto-fill) or fill in manually.
2. Auto-fill a new `WishlistItem` by parsing Open Graph metadata from the product URL — no paid API required.
3. Add a `price` field to `WishlistItem` to capture product pricing from metadata.
4. Maintain the existing manual entry flow as a first-class option.

## Risk & Mitigation

- **E-commerce sites blocking scraping:** Many sites block automated requests with bot detection. Mitigation: set a browser-like `User-Agent` header; gracefully fall back to manual entry on failure.
- **No standard price OG tag:** Price is not universally available in Open Graph. Mitigation: attempt `product:price:amount` and `og:price`; treat price as optional if not found.
- **Remote image not shown in `WishlistItemCard`:** The card currently only renders `localImage`. Mitigation: update card to also display remote image from `item.image` using `WishieWebImage`.

# Technical Specification Context

## Functional Requirements:

- System MUST present a bottom sheet (`AddItemOptionSheet`) with two options when the user taps "Add another gift" in `CreateWishlistPage2`
- System MUST allow the user to paste a product URL in `PasteLinkSheet` and trigger a metadata fetch
- System MUST parse Open Graph tags (`og:title`, `og:description`, `og:image`, `og:url`) from the fetched HTML using `ProductMetadataService`
- System MUST fall back to `<title>` tag if `og:title` is absent, and to the original URL if `og:url` is absent
- System MUST attempt to extract price from `product:price:amount` and `product:price:currency` meta tags
- System MUST show a loading indicator in `PasteLinkSheet` during the fetch operation
- System MUST show a metadata preview (title, description, image thumbnail, price) in `PasteLinkSheet` after a successful fetch
- System MUST surface a human-readable error message in `PasteLinkSheet` if the fetch fails
- System MUST auto-fill a new `WishlistItem` from `ProductMetadata` and add it to `CreateWishlistViewModel.items` when the user confirms
- System MUST support the manual entry option (existing path): append an empty `WishlistItem` directly without showing `PasteLinkSheet`
- System MUST display the auto-fetched remote image (`item.image`) in `WishlistItemCard` using `WishieWebImage` when `item.localImage` is nil
- System MUST add optional `price: String?` field to `WishlistItem`

## Non-Functional Requirements:

- System MUST NOT require a paid or third-party API for metadata fetching
- System MUST use native `URLSession` for HTTP requests with a browser-like `User-Agent` header
- System MUST maintain backward compatibility — all existing wishlists without `price` remain valid
- System MUST follow the MVVM pattern: fetching logic lives in `CreateWishlistViewModel`, views remain stateless coordinators
- System MUST follow the protocol-based service abstraction pattern: `ProductMetadataServiceProtocol` separates interface from `ProductMetadataService` implementation
- System MUST gracefully degrade if Open Graph tags are absent — still allow the user to edit the item manually after auto-fill

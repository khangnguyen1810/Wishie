# Location-Aware Gift Suggestions — Design

**Date:** 2026-07-21
**Status:** Approved

## Goal

When a user opens the app, request permission to share their location. Use the
resulting country to enrich the Gemini gift-suggestion prompt so recommended
products and purchase links suit the user's country (retailers, availability,
shippability).

## Decisions

- **Data sent to Gemini:** country **name** only (e.g. "Vietnam"). No raw
  coordinates — better link relevance and more privacy.
- **On permission denied / not granted:** fall back to the device region
  (`Locale.current.region`) resolved to a country name. The flow never breaks;
  the prompt always has a plausible country.
- **Permission timing:** requested when the user enters the app (system prompt
  shows only when authorization status is `notDetermined`).

## Architecture

### iOS (Swift)

- **Info.plist:** add `NSLocationWhenInUseUsageDescription` with a user-facing
  explanation (Wishie uses your location to suggest gifts and shopping links
  suited to your country).
- **`LocationManager`** — new `ObservableObject` wrapping `CLLocationManager`:
  - On app entry: `requestWhenInUseAuthorization()`.
  - `func resolveCountryName() async -> String?`: reverse-geocode the latest
    location with `CLGeocoder` → `placemark.country` (English name). If no
    permission / no location / geocoding error, fall back to
    `Locale.current.region` → country name. Always returns a sensible value
    when any is derivable.
- **Trigger:** instantiate `LocationManager` at `WishieApp` (or
  `MainView.onAppear`) and request authorization when the app becomes active.
- **`GiftSuggestionService.fetchIdeas`:** add `country: String?` parameter →
  `payload["country"]` (set only when non-nil).
- **`GiftSuggestionViewModel.generate()`:** resolve country (await) before
  calling the service and pass it through.

### Functions (TypeScript)

- **`GiftPromptInput`:** add `country?: string | null`.
- **`buildPrompt`:** when country is present, add a line:
  "The recipient is located in {country}. Prefer gifts and https product links
  that are purchasable and shippable in {country}, using retailers popular in
  that country."
- **`index.ts`:** parse `country` from `request.data` (string else null) and
  pass it into `buildPrompt`.
- **Tests:** extend `giftPrompt.test.ts` covering both the with-country and
  without-country branches.

## Notes / Edge Cases

- Denying permission does not break the flow — the device-region fallback keeps
  a country in the prompt.
- Reverse geocoding needs network; failures fall back to device region.
- Coordinates are never stored or transmitted; only a country name.
- No change to how `interests`, `age`, `existingItemNames` are handled.

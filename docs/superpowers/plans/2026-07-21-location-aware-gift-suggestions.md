# Location-Aware Gift Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Request location permission when the user opens the app and pass the user's country into the Gemini gift-suggestion prompt so recommended products and links suit their country.

**Architecture:** iOS resolves a country *name* (never coordinates) via `CLGeocoder`, falling back to the device region when permission is absent, and threads it through `GiftSuggestionService` → the `suggestGifts` callable. The Cloud Function adds a country line to the prompt. Country resolution is behind a `CountryProviding` protocol so the view model stays unit-testable.

**Tech Stack:** Swift / SwiftUI, CoreLocation, Firebase Functions (Swift SDK); TypeScript Cloud Functions on Node 24; Swift Testing (`import Testing`) for iOS unit tests; `node --test` for functions.

## Global Constraints

- Never store or transmit raw coordinates — only a country name (English).
- Denying/withholding location permission must NOT break the suggestion flow; fall back to `Locale.current.region`.
- The `country` field is optional end-to-end: omit it from the callable payload and from the prompt when it is nil/empty.
- Follow existing patterns: services injected into `GiftSuggestionViewModel`; shared singletons use the `static let shared` pattern (see `SupabaseManager`).
- iOS unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`). Functions tests use `node:test` + `node:assert/strict`.

---

### Task 1: Add country to the Gemini prompt (Cloud Function)

**Files:**
- Modify: `functions/src/giftPrompt.ts`
- Modify: `functions/src/index.ts`
- Test: `functions/src/giftPrompt.test.ts`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces: `GiftPromptInput` gains `country?: string | null`; the `suggestGifts` callable accepts `data.country: string`.

- [ ] **Step 1: Write the failing tests**

Add these two tests to `functions/src/giftPrompt.test.ts`:

```typescript
test("buildPrompt includes country line when country is provided", () => {
  const prompt = buildPrompt({
    interests: ["Gaming"],
    age: 26,
    existingItemNames: [],
    country: "Vietnam",
  });
  assert.match(prompt, /Vietnam/);
  assert.match(prompt, /located in Vietnam/i);
});

test("buildPrompt omits country line when country is null", () => {
  const prompt = buildPrompt({
    interests: ["Gaming"],
    age: 26,
    existingItemNames: [],
    country: null,
  });
  assert.doesNotMatch(prompt, /located in/i);
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd functions && npm test`
Expected: FAIL — the new tests fail because `buildPrompt` ignores `country` (no "located in" text) and TypeScript may error that `country` is not on `GiftPromptInput`.

- [ ] **Step 3: Add `country` to the input type and prompt**

In `functions/src/giftPrompt.ts`, update the interface:

```typescript
export interface GiftPromptInput {
  interests: string[];
  age: number | null;
  existingItemNames: string[];
  country?: string | null;
}
```

In the same file, update `buildPrompt` to destructure `country`, build a location line, and insert it after `avoidLine`:

```typescript
export function buildPrompt(input: GiftPromptInput): string {
  const { interests, age, existingItemNames, country } = input;
  const interestLine = `The person enjoys: ${interests.join(", ")}.`;
  const ageLine =
    typeof age === "number" ? `They are about ${age} years old.` : "";
  const avoidLine =
    existingItemNames && existingItemNames.length
      ? `Do NOT suggest anything similar to items they already have: ${existingItemNames.join(", ")}.`
      : "";
  const locationLine =
    country && country.trim()
      ? `The recipient is located in ${country.trim()}. Prefer gifts and https product links that are purchasable and shippable in ${country.trim()}, using retailers popular in that country.`
      : "";

  return [
    "You are a thoughtful gift-recommendation assistant.",
    interestLine,
    ageLine,
    avoidLine,
    locationLine,
    "Suggest 8 to 10 specific, real, purchasable gift products that fit these interests.",
    'For each gift provide: a short product name, a one-sentence description, an estimated price (e.g. "$25"), and a direct https product link to a real, currently-buyable item on a major store.',
    "Prefer links to well-known retailers. Every link must be a real, working https URL to a specific product listing.",
    'Respond with ONLY valid JSON in exactly this shape: {"ideas":[{"name":"","description":"","price":"","link":""}]}',
    "Do not include any prose outside the JSON.",
  ]
    .filter(Boolean)
    .join("\n");
}
```

- [ ] **Step 4: Parse `country` in the callable**

In `functions/src/index.ts`, inside `suggestGifts`, after the `existingItemNames` parse block, add:

```typescript
    const country =
      typeof request.data?.country === "string" ? request.data.country : null;
```

Then update the `buildPrompt` call to pass it:

```typescript
    const prompt = buildPrompt({ interests, age, existingItemNames, country });
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd functions && npm test`
Expected: PASS — all existing tests plus the two new country tests pass.

- [ ] **Step 6: Lint**

Run: `cd functions && npm run lint`
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add functions/src/giftPrompt.ts functions/src/index.ts functions/src/giftPrompt.test.ts
git commit -m "feat: add country to gift-suggestion prompt"
```

---

### Task 2: Device-region country fallback helper (iOS)

**Files:**
- Modify: `Wishie/Services/GiftSuggestionInputBuilder.swift`
- Test: `WishieTests/GiftSuggestionInputBuilderTests.swift`

**Interfaces:**
- Consumes: nothing from earlier tasks.
- Produces:
  - `static func countryName(fromRegionCode code: String?) -> String?` — maps an ISO region code (e.g. `"VN"`) to an English country name (e.g. `"Vietnam"`); returns nil for nil/empty/unknown codes.
  - `static func deviceRegionCountryName() -> String?` — English country name of the current device region, or nil.

- [ ] **Step 1: Write the failing tests**

Add to `WishieTests/GiftSuggestionInputBuilderTests.swift`:

```swift
    @Test func countryNameMapsIsoRegionCodeToEnglishName() {
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: "VN") == "Vietnam")
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: "US") == "United States")
    }

    @Test func countryNameReturnsNilForNilOrEmptyCode() {
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: nil) == nil)
        #expect(GiftSuggestionInputBuilder.countryName(fromRegionCode: "") == nil)
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/GiftSuggestionInputBuilderTests 2>&1 | tail -30`
Expected: FAIL — `countryName(fromRegionCode:)` does not exist (compile error).
(If no `iPhone 16` simulator exists, run `xcrun simctl list devicetypes | grep iPhone` and substitute an available name.)

- [ ] **Step 3: Implement the helpers**

Add to the `GiftSuggestionInputBuilder` enum in `Wishie/Services/GiftSuggestionInputBuilder.swift`:

```swift
    /// English country name for an ISO region code (e.g. "VN" -> "Vietnam").
    static func countryName(fromRegionCode code: String?) -> String? {
        guard let code, !code.isEmpty else { return nil }
        return Locale(identifier: "en_US").localizedString(forRegionCode: code)
    }

    /// English country name for the device's current region, if any.
    static func deviceRegionCountryName() -> String? {
        countryName(fromRegionCode: Locale.current.region?.identifier)
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/GiftSuggestionInputBuilderTests 2>&1 | tail -30`
Expected: PASS — all `GiftSuggestionInputBuilderTests` pass, including the two new ones.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Services/GiftSuggestionInputBuilder.swift WishieTests/GiftSuggestionInputBuilderTests.swift
git commit -m "feat: add device-region country name helpers"
```

---

### Task 3: CountryProviding protocol + LocationManager (iOS)

**Files:**
- Create: `Wishie/Manager/LocationManager.swift`

**Interfaces:**
- Consumes: `GiftSuggestionInputBuilder.countryName(fromRegionCode:)` and `.deviceRegionCountryName()` from Task 2.
- Produces:
  - `protocol CountryProviding { func resolveCountryName() async -> String? }`
  - `final class LocationManager: NSObject, ObservableObject, CountryProviding` with `static let shared: LocationManager` and `func requestPermission()`.

- [ ] **Step 1: Create the LocationManager**

Create `Wishie/Manager/LocationManager.swift`:

```swift
import Foundation
import CoreLocation

/// Resolves the user's country name for prompt enrichment.
protocol CountryProviding {
    func resolveCountryName() async -> String?
}

/// Wraps CLLocationManager: requests when-in-use permission on app entry and
/// resolves the latest location to an English country name. Falls back to the
/// device region whenever permission/location/geocoding is unavailable so the
/// flow never breaks. Never stores or transmits coordinates.
final class LocationManager: NSObject, ObservableObject, CountryProviding {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastLocation: CLLocation?

    override private init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Shows the system prompt only when authorization is `notDetermined`.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func resolveCountryName() async -> String? {
        if let location = lastLocation,
           let placemarks = try? await geocoder.reverseGeocodeLocation(location),
           let name = GiftSuggestionInputBuilder.countryName(
               fromRegionCode: placemarks.first?.isoCountryCode) {
            return name
        }
        return GiftSuggestionInputBuilder.deviceRegionCountryName()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Ignore: resolveCountryName() falls back to the device region.
    }
}
```

- [ ] **Step 2: Verify it compiles**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: `BUILD SUCCEEDED`.
(Note: new files are auto-added to the target by the modern Xcode file-system-synchronized group; if the build reports the file is not in the target, add it to the `Wishie` target in Xcode.)

- [ ] **Step 3: Commit**

```bash
git add Wishie/Manager/LocationManager.swift
git commit -m "feat: add LocationManager and CountryProviding"
```

---

### Task 4: Thread country through service and view model (iOS)

**Files:**
- Modify: `Wishie/Services/GiftSuggestionService.swift`
- Modify: `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift`
- Test: `WishieTests/GiftSuggestionViewModelTests.swift`

**Interfaces:**
- Consumes: `CountryProviding` and `LocationManager.shared` (Task 3); `GiftSuggestionServiceProtocol` (existing).
- Produces:
  - `GiftSuggestionServiceProtocol.fetchIdeas(interests:age:existingItemNames:country:)` — `country: String?` appended.
  - `GiftSuggestionViewModel.init(..., countryProvider: CountryProviding = LocationManager.shared)`.

- [ ] **Step 1: Update the protocol, the stub, and add a failing test**

In `WishieTests/GiftSuggestionViewModelTests.swift`, update `StubSuggestionService` to the new signature and capture the country:

```swift
    final class StubSuggestionService: GiftSuggestionServiceProtocol {
        var ideas: [GiftIdea] = []
        var error: Error?
        private(set) var didCallFetch = false
        private(set) var receivedAge: Int?
        private(set) var receivedCountry: String?
        func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> [GiftIdea] {
            didCallFetch = true
            receivedAge = age
            receivedCountry = country
            if let error { throw error }
            return ideas
        }
    }
```

Add a stub country provider and a test near the other tests in the same struct:

```swift
    struct StubCountryProvider: CountryProviding {
        let name: String?
        func resolveCountryName() async -> String? { name }
    }

    @Test func generatePassesResolvedCountryToService() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(3)
        let metadata = MockProductMetadataService()
        for i in 0..<3 {
            metadata.results["https://ex.com/\(i)"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/\(i)"))
        }

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"]),
            countryProvider: StubCountryProvider(name: "Vietnam")
        )
        await vm.generate()

        #expect(suggestion.receivedCountry == "Vietnam")
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/GiftSuggestionViewModelTests 2>&1 | tail -30`
Expected: FAIL — compile error: `fetchIdeas` signature mismatch and `GiftSuggestionViewModel.init` has no `countryProvider` parameter.

- [ ] **Step 3: Update the service protocol and implementation**

In `Wishie/Services/GiftSuggestionService.swift`, update the protocol and method:

```swift
protocol GiftSuggestionServiceProtocol {
    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> [GiftIdea]
}

final class GiftSuggestionService: GiftSuggestionServiceProtocol {
    private lazy var functions = Functions.functions()

    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String], country: String?) async throws -> [GiftIdea] {
        var payload: [String: Any] = [
            "interests": interests,
            "existingItemNames": existingItemNames
        ]
        if let age { payload["age"] = age }
        if let country, !country.isEmpty { payload["country"] = country }

        let result = try await functions.httpsCallable("suggestGifts").call(payload)
        return GiftIdea.parse(from: result.data)
    }
}
```

- [ ] **Step 4: Inject the country provider into the view model**

In `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift`, add a stored property and init parameter. Add to the stored properties block (next to `authService`):

```swift
    private let countryProvider: CountryProviding
```

Update the initializer signature and body:

```swift
    init(
        existingItemNames: [String],
        suggestionService: GiftSuggestionServiceProtocol = GiftSuggestionService(),
        metadataService: ProductMetadataServiceProtocol = ProductMetadataService(),
        authService: AuthenticateServiceProtocol = AuthenticateService(),
        countryProvider: CountryProviding = LocationManager.shared
    ) {
        self.existingItemNames = existingItemNames
        self.suggestionService = suggestionService
        self.metadataService = metadataService
        self.authService = authService
        self.countryProvider = countryProvider
    }
```

In `generate()`, resolve the country before calling the service and pass it. Replace the `fetchIdeas` call block:

```swift
        let country = await countryProvider.resolveCountryName()

        let ideas: [GiftIdea]
        do {
            ideas = try await suggestionService.fetchIdeas(
                interests: interestNames,
                age: age,
                existingItemNames: existingItemNames,
                country: country
            )
        } catch {
            phase = .error(error.localizedDescription)
            return
        }
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:WishieTests/GiftSuggestionViewModelTests 2>&1 | tail -30`
Expected: PASS — all `GiftSuggestionViewModelTests` pass, including `generatePassesResolvedCountryToService`.

- [ ] **Step 6: Commit**

```bash
git add Wishie/Services/GiftSuggestionService.swift Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift WishieTests/GiftSuggestionViewModelTests.swift
git commit -m "feat: thread country through gift suggestion service and view model"
```

---

### Task 5: Request permission on app entry + Info.plist (iOS)

**Files:**
- Modify: `Wishie/Info.plist`
- Modify: `Wishie/WishieApp.swift`

**Interfaces:**
- Consumes: `LocationManager.shared.requestPermission()` (Task 3).
- Produces: nothing consumed by later tasks (final task).

- [ ] **Step 1: Add the usage-description key to Info.plist**

In `Wishie/Info.plist`, add this key/value inside the top-level `<dict>` (e.g. right after the `<key>CFBundleURLTypes</key>` array closes):

```xml
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>Wishie uses your location to suggest gifts and shopping links suited to the country you're in.</string>
```

- [ ] **Step 2: Request permission when the app becomes active**

In `Wishie/WishieApp.swift`, add the CoreLocation-backed request inside the existing `.onAppear` on the root `ZStack`. Update the `.onAppear` block to:

```swift
            .onAppear {
                LocationManager.shared.requestPermission()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring) {
                        isActive = true
                    }
                }
            }
```

- [ ] **Step 3: Build and verify the whole app compiles**

Run: `xcodebuild build -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20`
Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Manually verify the permission prompt (simulator)**

Run: `xcodebuild test -project Wishie.xcodeproj -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20` to confirm the full test suite still passes, then launch the app in the simulator (Xcode Run) and confirm the "Allow While Using App" location prompt appears on first launch. In the simulator, set a location via Features → Location → Custom Location (e.g. a Vietnam coordinate) to exercise reverse geocoding.
Expected: system location prompt appears once; suggestions still generate whether the prompt is allowed or denied.

- [ ] **Step 5: Commit**

```bash
git add Wishie/Info.plist Wishie/WishieApp.swift
git commit -m "feat: request location permission on app entry"
```

---

## Self-Review Notes

- **Spec coverage:** Permission request on entry → Task 5. Country name (not coordinates) → Tasks 2–3 (`countryName`, `isoCountryCode`). Device-region fallback → Tasks 2–3. Country in prompt → Task 1. Service/view-model plumbing → Task 4. All spec sections covered.
- **Type consistency:** `fetchIdeas(interests:age:existingItemNames:country:)` and `resolveCountryName() -> String?` used identically across Tasks 3–4; `country?: string | null` consistent across `GiftPromptInput`, `index.ts`, and tests in Task 1.
- **No coordinates leak:** only `country` (String) crosses the service boundary; `LocationManager` keeps `lastLocation` private.

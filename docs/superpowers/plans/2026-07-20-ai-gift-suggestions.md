# AI Gift Suggestions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a wishlist owner generate 5-6 personalized, fully-populated gift ideas (name, description, price, product link, image) from their interests and add them to their wishlist with one tap.

**Architecture:** The app calls a Firebase callable Function (`suggestGifts`) that holds the Gemini API key server-side and returns 8-10 raw ideas. The client validates each idea's product link concurrently by reusing the existing `ProductMetadataService` (WKWebView scraper), streaming the first 5-6 that resolve into a results sheet. Reached from the shared `AddItemOptionSheet`, so both the create-wishlist flow and the wishlist detail screen get it.

**Tech Stack:** SwiftUI, Firebase (Firestore + Functions callable + Auth), Google Gemini free tier, Node.js (Cloud Function), Swift Testing framework (`import Testing`), Node built-in test runner (`node:test`).

## Global Constraints

- **Platform:** iOS, SwiftUI, `@MainActor` view models, `async/await`.
- **Test framework (Swift):** Swift Testing — `import Testing`, `@Test`, `#expect(...)`. NOT XCTest.
- **Test framework (Node):** `node:test` + `node:assert/strict`. No new test dependencies.
- **Fonts:** `Text(...).font(.wishies(.bold, 16))` / `.wishies(.regular, 13)`. Cases available: `.bold`, `.regular` (no `.semibold`).
- **Colors:** `.wishiePink`, `.lightYellow`, `.lightYellow1`, `.black`, `.gray` as used elsewhere.
- **Remote images:** `WishieWebImage(url: String)`.
- **Loading animation:** DotLottie asset named `"giftloading"` (already bundled).
- **Over-request rule:** Function requests **8-10** ideas; client keeps the first **6** that validate (cap `maxResults = 6`). If fewer than **3** validate, show what exists + a Try again action.
- **Current-user source:** `AuthenticateServiceProtocol.getUserInfo() async throws -> UserModel?` returns `interests: [String]` and `dateOfBirth: Date`.
- **Interest catalog:** global `hobbyCategories: [HobbyCategory]`; each `HobbyItem` has `id`, `name`, `emoji`.
- **Firebase region:** default (`us-central1`) — use `Functions.functions()` with no explicit region.

---

## File Structure

**Created (Swift):**
- `Wishie/Models/GiftSuggestion.swift` — `GiftIdea`, `GiftSuggestion` value types + JSON parsing + `WishlistItem` mapping.
- `Wishie/Services/GiftSuggestionInputBuilder.swift` — pure helpers: interest ids→names, age from DOB, dedupe list.
- `Wishie/Services/GiftSuggestionService.swift` — calls the `suggestGifts` callable, returns `[GiftIdea]`.
- `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift` — orchestration + validation pipeline + no-interests state.
- `Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift` — one idea card.
- `Wishie/Screens/GiftSuggestions/GiftSuggestionsSheet.swift` — results sheet (loading / cards / interest-pick / retry).

**Created (Function):**
- `functions/index.js` — `suggestGifts` callable wiring.
- `functions/giftPrompt.js` — pure `buildPrompt(input)` + `parseGeminiJson(text)`.
- `functions/package.json` — function deps + test script.
- `functions/test/giftPrompt.test.js` — Node tests for prompt + parse.
- `functions/.gitignore` — ignore `node_modules`.

**Created (Swift tests):**
- `WishieTests/GiftSuggestionInputBuilderTests.swift`
- `WishieTests/GiftSuggestionParsingTests.swift`
- `WishieTests/GiftSuggestionViewModelTests.swift`
- `WishieTests/MockProductMetadataService.swift`

**Modified:**
- `Wishie/Screens/CreateList/AddItemOptionSheet.swift` — add third "Suggest gifts" row + `onSuggestGifts` callback.
- `Wishie/Screens/Detail/WishlistDetailScreen.swift` — wire suggest option → results sheet.
- `Wishie/Screens/CreateList/CreateWishlistPage2.swift` — wire suggest option → results sheet.
- `Wishie.xcodeproj/project.pbxproj` — add `FirebaseFunctions` product to the `Wishie` target (done via Xcode).

---

## Task 1: Gift models + input builder (pure Swift)

Pure value types and pure helpers — no Firebase, fully unit-testable.

**Files:**
- Create: `Wishie/Models/GiftSuggestion.swift`
- Create: `Wishie/Services/GiftSuggestionInputBuilder.swift`
- Test: `WishieTests/GiftSuggestionInputBuilderTests.swift`
- Test: `WishieTests/GiftSuggestionParsingTests.swift`

**Interfaces:**
- Produces:
  - `struct GiftIdea { let name: String; let description: String; let price: String; let link: String }`
  - `static func GiftIdea.parse(from data: Any?) -> [GiftIdea]` — decodes a callable result payload `{ "ideas": [ { name, description, price, link } ] }`.
  - `struct GiftSuggestion { let idea: GiftIdea; let metadata: ProductMetadata; func toWishlistItem() -> WishlistItem }`
  - `enum GiftSuggestionInputBuilder` with:
    - `static func interestNames(fromIds ids: [String]) -> [String]`
    - `static func age(from dateOfBirth: Date, now: Date = Date()) -> Int?`
    - `static func existingItemNames(from items: [WishlistItem]) -> [String]`

- [ ] **Step 1: Write the failing tests**

Create `WishieTests/GiftSuggestionInputBuilderTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct GiftSuggestionInputBuilderTests {

    @Test func interestNamesMapsKnownIdsToHumanNames() {
        let names = GiftSuggestionInputBuilder.interestNames(fromIds: ["gaming", "reading"])
        #expect(names.contains("Gaming"))
        #expect(names.contains("Reading"))
        #expect(names.count == 2)
    }

    @Test func interestNamesDropsUnknownIds() {
        let names = GiftSuggestionInputBuilder.interestNames(fromIds: ["gaming", "not_a_real_id"])
        #expect(names == ["Gaming"])
    }

    @Test func ageComputesWholeYearsFromDateOfBirth() {
        let cal = Calendar(identifier: .gregorian)
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 20))!
        let dob = cal.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        #expect(GiftSuggestionInputBuilder.age(from: dob, now: now) == 26)
    }

    @Test func existingItemNamesTrimsAndDropsEmpty() {
        let items = [
            WishlistItem(name: "  AirPods  "),
            WishlistItem(name: ""),
            WishlistItem(name: "Book")
        ]
        let names = GiftSuggestionInputBuilder.existingItemNames(from: items)
        #expect(names == ["AirPods", "Book"])
    }
}
```

Create `WishieTests/GiftSuggestionParsingTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

struct GiftSuggestionParsingTests {

    @Test func parseReadsIdeasArray() {
        let payload: [String: Any] = [
            "ideas": [
                ["name": "Mechanical Keyboard", "description": "Clicky keys", "price": "$80", "link": "https://ex.com/kb"],
                ["name": "Board Game", "description": "Fun night", "price": "$30", "link": "https://ex.com/bg"]
            ]
        ]
        let ideas = GiftIdea.parse(from: payload)
        #expect(ideas.count == 2)
        #expect(ideas[0].name == "Mechanical Keyboard")
        #expect(ideas[0].link == "https://ex.com/kb")
    }

    @Test func parseSkipsEntriesMissingNameOrLink() {
        let payload: [String: Any] = [
            "ideas": [
                ["name": "Good", "description": "d", "price": "$1", "link": "https://ex.com/a"],
                ["description": "no name", "price": "$1", "link": "https://ex.com/b"],
                ["name": "No link", "description": "d", "price": "$1"]
            ]
        ]
        let ideas = GiftIdea.parse(from: payload)
        #expect(ideas.count == 1)
        #expect(ideas[0].name == "Good")
    }

    @Test func parseReturnsEmptyForBadPayload() {
        #expect(GiftIdea.parse(from: nil).isEmpty)
        #expect(GiftIdea.parse(from: "nope").isEmpty)
    }

    @Test func toWishlistItemPopulatesAllFields() {
        let idea = GiftIdea(name: "Keyboard", description: "Clicky", price: "$80", link: "https://ex.com/kb")
        let metadata = ProductMetadata(
            title: "Real Keyboard",
            productDescription: "From store",
            imageUrl: "https://ex.com/img.jpg",
            productUrl: "https://ex.com/kb",
            price: "$79"
        )
        let item = GiftSuggestion(idea: idea, metadata: metadata).toWishlistItem()
        #expect(item.name == "Real Keyboard")
        #expect(item.image == "https://ex.com/img.jpg")
        #expect(item.itemLink == "https://ex.com/kb")
        #expect(item.price == "$79")
        #expect(item.description == "From store")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WishieTests/GiftSuggestionInputBuilderTests -only-testing:WishieTests/GiftSuggestionParsingTests`
Expected: FAIL — `GiftSuggestionInputBuilder` / `GiftIdea` unresolved.

- [ ] **Step 3: Implement the models**

Create `Wishie/Models/GiftSuggestion.swift`:

```swift
import Foundation

struct GiftIdea: Hashable {
    let name: String
    let description: String
    let price: String
    let link: String

    static func parse(from data: Any?) -> [GiftIdea] {
        guard
            let dict = data as? [String: Any],
            let rawIdeas = dict["ideas"] as? [[String: Any]]
        else { return [] }

        return rawIdeas.compactMap { entry in
            guard
                let name = (entry["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                !name.isEmpty,
                let link = (entry["link"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                !link.isEmpty
            else { return nil }

            return GiftIdea(
                name: name,
                description: (entry["description"] as? String) ?? "",
                price: (entry["price"] as? String) ?? "",
                link: link
            )
        }
    }
}

struct GiftSuggestion: Hashable, Identifiable {
    let idea: GiftIdea
    let metadata: ProductMetadata

    var id: String { metadata.productUrl }

    func toWishlistItem() -> WishlistItem {
        WishlistItem(
            name: metadata.title.isEmpty ? idea.name : metadata.title,
            description: metadata.productDescription.isEmpty ? idea.description : metadata.productDescription,
            image: metadata.imageUrl,
            itemLink: metadata.productUrl,
            price: (metadata.price?.isEmpty == false ? metadata.price : idea.price)
        )
    }
}
```

Note: `ProductMetadata` is not `Hashable` today. If the compiler complains about `GiftSuggestion: Hashable`, add `Hashable` conformance to `ProductMetadata` in `Wishie/Models/ProductMetadata.swift` (all its stored properties are already hashable, so `struct ProductMetadata: Hashable {` suffices).

- [ ] **Step 4: Implement the input builder**

Create `Wishie/Services/GiftSuggestionInputBuilder.swift`:

```swift
import Foundation

enum GiftSuggestionInputBuilder {

    static func interestNames(fromIds ids: [String]) -> [String] {
        let lookup: [String: String] = hobbyCategories
            .flatMap { $0.items }
            .reduce(into: [:]) { dict, item in dict[item.id] = item.name }
        return ids.compactMap { lookup[$0] }
    }

    static func age(from dateOfBirth: Date, now: Date = Date()) -> Int? {
        Calendar(identifier: .gregorian)
            .dateComponents([.year], from: dateOfBirth, to: now)
            .year
    }

    static func existingItemNames(from items: [WishlistItem]) -> [String] {
        items
            .map { $0.name.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WishieTests/GiftSuggestionInputBuilderTests -only-testing:WishieTests/GiftSuggestionParsingTests`
Expected: PASS (all cases).

- [ ] **Step 6: Commit**

```bash
git add Wishie/Models/GiftSuggestion.swift Wishie/Models/ProductMetadata.swift Wishie/Services/GiftSuggestionInputBuilder.swift WishieTests/GiftSuggestionInputBuilderTests.swift WishieTests/GiftSuggestionParsingTests.swift
git commit -m "feat: add gift suggestion models and input builder"
```

---

## Task 2: Firebase callable Function `suggestGifts` (Node)

Server side that holds the Gemini key and returns 8-10 raw ideas. Prompt building and JSON parsing are pure functions with their own tests.

**Prerequisites (one-time, manual — do before deploy, not required to write/test code):**
- Firebase **Blaze** plan enabled on the project.
- A **Gemini API key** created in Google AI Studio.
- Firebase CLI installed (`npm i -g firebase-tools`) and `firebase login` done.

**Files:**
- Create: `functions/package.json`
- Create: `functions/index.js`
- Create: `functions/giftPrompt.js`
- Create: `functions/.gitignore`
- Test: `functions/test/giftPrompt.test.js`

**Interfaces:**
- Produces (callable named `suggestGifts`):
  - Input: `{ interests: string[], age: number | null, existingItemNames: string[] }`
  - Output: `{ ideas: [ { name, description, price, link } ] }`
- Produces (pure, for tests): `buildPrompt(input) -> string`, `parseGeminiJson(text) -> { ideas: [...] }`.

- [ ] **Step 1: Write the failing tests**

Create `functions/test/giftPrompt.test.js`:

```js
const test = require("node:test");
const assert = require("node:assert/strict");
const { buildPrompt, parseGeminiJson } = require("../giftPrompt");

test("buildPrompt includes interests, age, and avoid list", () => {
  const prompt = buildPrompt({
    interests: ["Gaming", "Reading"],
    age: 26,
    existingItemNames: ["AirPods"],
  });
  assert.match(prompt, /Gaming/);
  assert.match(prompt, /Reading/);
  assert.match(prompt, /26/);
  assert.match(prompt, /AirPods/);
  assert.match(prompt, /8|8-10|8 to 10/);
});

test("buildPrompt omits age line when age is null", () => {
  const prompt = buildPrompt({ interests: ["Gaming"], age: null, existingItemNames: [] });
  assert.doesNotMatch(prompt, /age/i);
});

test("parseGeminiJson extracts ideas from a fenced code block", () => {
  const text = '```json\n{"ideas":[{"name":"KB","description":"d","price":"$1","link":"https://x/1"}]}\n```';
  const parsed = parseGeminiJson(text);
  assert.equal(parsed.ideas.length, 1);
  assert.equal(parsed.ideas[0].name, "KB");
});

test("parseGeminiJson extracts ideas from raw JSON", () => {
  const parsed = parseGeminiJson('{"ideas":[{"name":"A","description":"d","price":"$1","link":"https://x/a"}]}');
  assert.equal(parsed.ideas[0].link, "https://x/a");
});

test("parseGeminiJson throws on unparseable text", () => {
  assert.throws(() => parseGeminiJson("sorry, no json here"));
});
```

- [ ] **Step 2: Create package.json and run tests to verify they fail**

Create `functions/package.json`:

```json
{
  "name": "wishie-functions",
  "description": "Cloud Functions for Wishie",
  "engines": { "node": "20" },
  "main": "index.js",
  "scripts": {
    "test": "node --test",
    "deploy": "firebase deploy --only functions"
  },
  "dependencies": {
    "firebase-admin": "^12.6.0",
    "firebase-functions": "^5.1.0"
  },
  "private": true
}
```

Create `functions/.gitignore`:

```
node_modules/
```

Run: `cd functions && npm install && npm test`
Expected: FAIL — `Cannot find module '../giftPrompt'`.

- [ ] **Step 3: Implement the pure prompt module**

Create `functions/giftPrompt.js`:

```js
function buildPrompt({ interests, age, existingItemNames }) {
  const interestLine = `The person enjoys: ${interests.join(", ")}.`;
  const ageLine = typeof age === "number" ? `They are about ${age} years old.` : "";
  const avoidLine =
    existingItemNames && existingItemNames.length
      ? `Do NOT suggest anything similar to items they already have: ${existingItemNames.join(", ")}.`
      : "";

  return [
    "You are a thoughtful gift-recommendation assistant.",
    interestLine,
    ageLine,
    avoidLine,
    "Suggest 8 to 10 specific, real, purchasable gift products that fit these interests.",
    "For each gift provide: a short product name, a one-sentence description, an estimated price (e.g. \"$25\"), and a direct https product link to a real, currently-buyable item on a major store.",
    "Prefer links to well-known retailers. Every link must be a real, working https URL to a specific product page.",
    'Respond with ONLY valid JSON in exactly this shape: {"ideas":[{"name":"","description":"","price":"","link":""}]}',
    "Do not include any prose outside the JSON.",
  ]
    .filter(Boolean)
    .join("\n");
}

function parseGeminiJson(text) {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenced ? fenced[1] : text;
  const start = candidate.indexOf("{");
  const end = candidate.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    throw new Error("No JSON object found in model response");
  }
  const json = JSON.parse(candidate.slice(start, end + 1));
  if (!json || !Array.isArray(json.ideas)) {
    throw new Error("Parsed JSON has no ideas array");
  }
  return json;
}

module.exports = { buildPrompt, parseGeminiJson };
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd functions && npm test`
Expected: PASS (5 tests).

- [ ] **Step 5: Implement the callable wiring**

Create `functions/index.js`:

```js
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { buildPrompt, parseGeminiJson } = require("./giftPrompt");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GEMINI_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";

exports.suggestGifts = onCall({ secrets: [GEMINI_API_KEY] }, async (request) => {
  const interests = Array.isArray(request.data?.interests) ? request.data.interests : [];
  const age = typeof request.data?.age === "number" ? request.data.age : null;
  const existingItemNames = Array.isArray(request.data?.existingItemNames)
    ? request.data.existingItemNames
    : [];

  if (interests.length === 0) {
    throw new HttpsError("invalid-argument", "At least one interest is required.");
  }

  const prompt = buildPrompt({ interests, age, existingItemNames });

  let response;
  try {
    response = await fetch(`${GEMINI_URL}?key=${GEMINI_API_KEY.value()}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.9, responseMimeType: "application/json" },
      }),
    });
  } catch (err) {
    throw new HttpsError("unavailable", "Could not reach the suggestion service.");
  }

  if (!response.ok) {
    throw new HttpsError("unavailable", "Suggestion service returned an error.");
  }

  const body = await response.json();
  const text = body?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  let parsed;
  try {
    parsed = parseGeminiJson(text);
  } catch (err) {
    throw new HttpsError("internal", "Could not parse suggestions.");
  }

  return { ideas: parsed.ideas.slice(0, 10) };
});
```

- [ ] **Step 6: Commit**

```bash
git add functions/index.js functions/giftPrompt.js functions/package.json functions/.gitignore functions/test/giftPrompt.test.js
git commit -m "feat: add suggestGifts Firebase callable function"
```

- [ ] **Step 7: Deploy (manual, after Blaze + secret are set)**

Run:
```bash
cd functions
firebase functions:secrets:set GEMINI_API_KEY   # paste key when prompted
npm run deploy
```
Expected: deploy succeeds; `suggestGifts` listed as a callable function. (If `firebase.json` doesn't exist yet, run `firebase init functions` first and keep this `functions/` source directory.)

---

## Task 3: Add FirebaseFunctions SDK + `GiftSuggestionService`

Wire the client to the callable. The service is a thin adapter returning `[GiftIdea]`; parsing is reused from Task 1.

**Files:**
- Modify: `Wishie.xcodeproj/project.pbxproj` (via Xcode — add `FirebaseFunctions` product)
- Create: `Wishie/Services/GiftSuggestionService.swift`

**Interfaces:**
- Consumes: `GiftIdea.parse(from:)` (Task 1).
- Produces:
  - `protocol GiftSuggestionServiceProtocol { func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String]) async throws -> [GiftIdea] }`
  - `final class GiftSuggestionService: GiftSuggestionServiceProtocol`

- [ ] **Step 1: Add the FirebaseFunctions product to the target**

In Xcode: select the project → `Wishie` target → **General** → **Frameworks, Libraries, and Embedded Content** → **+** → from the existing `firebase-ios-sdk` package choose **FirebaseFunctions** → Add.
(Equivalent to adding a `FirebaseFunctions` product dependency referencing package `firebase-ios-sdk` in `project.pbxproj`, mirroring the existing `FirebaseFirestore` entries at the `packageProductDependencies` and `PBXBuildFile`/`Frameworks` sections.)

- [ ] **Step 2: Verify it links**

Run: `xcodebuild build -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED (a file doing `import FirebaseFunctions` will compile in the next step).

- [ ] **Step 3: Implement the service**

Create `Wishie/Services/GiftSuggestionService.swift`:

```swift
import Foundation
import FirebaseFunctions

protocol GiftSuggestionServiceProtocol {
    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String]) async throws -> [GiftIdea]
}

final class GiftSuggestionService: GiftSuggestionServiceProtocol {
    private lazy var functions = Functions.functions()

    func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String]) async throws -> [GiftIdea] {
        var payload: [String: Any] = [
            "interests": interests,
            "existingItemNames": existingItemNames
        ]
        if let age { payload["age"] = age }

        let result = try await functions.httpsCallable("suggestGifts").call(payload)
        return GiftIdea.parse(from: result.data)
    }
}
```

- [ ] **Step 4: Build to verify it compiles**

Run: `xcodebuild build -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Commit**

```bash
git add Wishie.xcodeproj/project.pbxproj Wishie/Services/GiftSuggestionService.swift
git commit -m "feat: add FirebaseFunctions SDK and gift suggestion service"
```

---

## Task 4: `GiftSuggestionViewModel` — validation pipeline

Orchestrates: load current user → fetch ideas → validate links concurrently via `ProductMetadataService`, streaming validated `GiftSuggestion`s, capped at 6. Handles the no-interests and error states.

**Files:**
- Create: `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift`
- Test: `WishieTests/MockProductMetadataService.swift`
- Test: `WishieTests/GiftSuggestionViewModelTests.swift`

**Interfaces:**
- Consumes: `GiftSuggestionServiceProtocol` (Task 3), `ProductMetadataServiceProtocol` (existing), `AuthenticateServiceProtocol` (existing), `GiftSuggestionInputBuilder` + `GiftSuggestion` (Task 1).
- Produces:
  - `enum GiftSuggestionPhase: Equatable { case idle, needsInterests, loading, results, empty, error(String) }`
  - `@MainActor final class GiftSuggestionViewModel: ObservableObject`
    - `@Published var phase: GiftSuggestionPhase`
    - `@Published var suggestions: [GiftSuggestion]`
    - `init(existingItemNames: [String], suggestionService:_, metadataService:_, authService:_)`
    - `func start() async` — entry point (checks interests, then generates)
    - `func generate() async` — fetch + validate pipeline
    - `func saveInterestsAndContinue(_ interestIds: [String]) async` — no-interests resume
    - `let maxResults = 6`, `let minResults = 3`

- [ ] **Step 1: Write the mock and failing tests**

Create `WishieTests/MockProductMetadataService.swift`:

```swift
import Foundation
@testable import Wishie

final class MockProductMetadataService: ProductMetadataServiceProtocol {
    /// Map of URL -> result. Missing URL or `.failure` simulates a dead/invalid link.
    var results: [String: Result<ProductMetadata, Error>] = [:]

    func fetchMetadata(from urlString: String) async throws -> ProductMetadata {
        switch results[urlString] {
        case .success(let metadata): return metadata
        case .failure(let error): throw error
        case .none: throw URLError(.badURL)
        }
    }

    static func metadata(for url: String) -> ProductMetadata {
        ProductMetadata(
            title: "Title \(url)",
            productDescription: "Desc",
            imageUrl: "https://img/\(url).jpg",
            productUrl: url,
            price: "$10"
        )
    }
}
```

Create `WishieTests/GiftSuggestionViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import Wishie

@MainActor
struct GiftSuggestionViewModelTests {

    final class StubSuggestionService: GiftSuggestionServiceProtocol {
        var ideas: [GiftIdea] = []
        var error: Error?
        func fetchIdeas(interests: [String], age: Int?, existingItemNames: [String]) async throws -> [GiftIdea] {
            if let error { throw error }
            return ideas
        }
    }

    func makeIdeas(_ count: Int) -> [GiftIdea] {
        (0..<count).map { i in
            GiftIdea(name: "Gift \(i)", description: "d", price: "$1", link: "https://ex.com/\(i)")
        }
    }

    func authStub(interests: [String]) -> MockAuthenticateService {
        let auth = MockAuthenticateService()
        auth.userToReturn = UserModel(dictionary: ["interests": interests])
        return auth
    }

    @Test func generateKeepsFirstSixValidatedAndDropsFailures() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(10)

        let metadata = MockProductMetadataService()
        // Fail #2 and #5; all others validate.
        for i in 0..<10 where i != 2 && i != 5 {
            metadata.results["https://ex.com/\(i)"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/\(i)"))
        }

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"])
        )
        await vm.generate()

        #expect(vm.suggestions.count == 6)
        #expect(vm.phase == .results)
        #expect(!vm.suggestions.contains { $0.metadata.productUrl == "https://ex.com/2" })
    }

    @Test func generateWithTooFewValidatedSetsEmptyPhase() async {
        let suggestion = StubSuggestionService()
        suggestion.ideas = makeIdeas(10)
        let metadata = MockProductMetadataService()
        // Only 2 validate (< minResults of 3).
        metadata.results["https://ex.com/0"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/0"))
        metadata.results["https://ex.com/1"] = .success(MockProductMetadataService.metadata(for: "https://ex.com/1"))

        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: metadata,
            authService: authStub(interests: ["gaming"])
        )
        await vm.generate()

        #expect(vm.suggestions.count == 2)
        #expect(vm.phase == .empty)
    }

    @Test func generateSurfacesServiceError() async {
        let suggestion = StubSuggestionService()
        suggestion.error = URLError(.notConnectedToInternet)
        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: suggestion,
            metadataService: MockProductMetadataService(),
            authService: authStub(interests: ["gaming"])
        )
        await vm.generate()

        if case .error = vm.phase { } else { Issue.record("expected error phase, got \(vm.phase)") }
    }

    @Test func startWithNoInterestsRequestsInterests() async {
        let vm = GiftSuggestionViewModel(
            existingItemNames: [],
            suggestionService: StubSuggestionService(),
            metadataService: MockProductMetadataService(),
            authService: authStub(interests: [])
        )
        await vm.start()
        #expect(vm.phase == .needsInterests)
    }
}
```

Note: this assumes `MockAuthenticateService` has a settable `userToReturn` returned from `getUserInfo()`. If the existing mock lacks it, extend `WishieTests/MockAuthenticateService.swift` with `var userToReturn: UserModel?` and `func getUserInfo() async throws -> UserModel? { userToReturn }` (keep existing behavior for other methods).

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WishieTests/GiftSuggestionViewModelTests`
Expected: FAIL — `GiftSuggestionViewModel` unresolved.

- [ ] **Step 3: Implement the view model**

Create `Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift`:

```swift
import Foundation

enum GiftSuggestionPhase: Equatable {
    case idle
    case needsInterests
    case loading
    case results
    case empty
    case error(String)
}

@MainActor
final class GiftSuggestionViewModel: ObservableObject {
    @Published var phase: GiftSuggestionPhase = .idle
    @Published var suggestions: [GiftSuggestion] = []

    let maxResults = 6
    let minResults = 3

    private let existingItemNames: [String]
    private let suggestionService: GiftSuggestionServiceProtocol
    private let metadataService: ProductMetadataServiceProtocol
    private let authService: AuthenticateServiceProtocol

    init(
        existingItemNames: [String],
        suggestionService: GiftSuggestionServiceProtocol = GiftSuggestionService(),
        metadataService: ProductMetadataServiceProtocol = ProductMetadataService(),
        authService: AuthenticateServiceProtocol = AuthenticateService()
    ) {
        self.existingItemNames = existingItemNames
        self.suggestionService = suggestionService
        self.metadataService = metadataService
        self.authService = authService
    }

    func start() async {
        let interests = (try? await authService.getUserInfo())?.interests ?? []
        if interests.isEmpty {
            phase = .needsInterests
            return
        }
        await generate()
    }

    func saveInterestsAndContinue(_ interestIds: [String]) async {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else {
            phase = .error("User session not found.")
            return
        }
        do {
            try await authService.updateUserInterests(userId: userId, interests: interestIds)
            await generate()
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    func generate() async {
        phase = .loading
        suggestions = []

        let user = try? await authService.getUserInfo()
        let interestIds = user?.interests ?? []
        let interestNames = GiftSuggestionInputBuilder.interestNames(fromIds: interestIds)
        let age = user.map { GiftSuggestionInputBuilder.age(from: $0.dateOfBirth) } ?? nil

        let ideas: [GiftIdea]
        do {
            ideas = try await suggestionService.fetchIdeas(
                interests: interestNames,
                age: age,
                existingItemNames: existingItemNames
            )
        } catch {
            phase = .error(error.localizedDescription)
            return
        }

        await validate(ideas: ideas)

        if suggestions.count >= minResults {
            phase = .results
        } else {
            phase = .empty
        }
    }

    /// Validate candidate links concurrently (bounded), publishing each success as it arrives.
    /// Stops once `maxResults` have validated.
    private func validate(ideas: [GiftIdea]) async {
        let concurrency = 3
        var index = 0

        while index < ideas.count && suggestions.count < maxResults {
            let batch = ideas[index..<min(index + concurrency, ideas.count)]
            index += batch.count

            let validated: [GiftSuggestion] = await withTaskGroup(of: GiftSuggestion?.self) { group in
                for idea in batch {
                    group.addTask { [metadataService] in
                        guard let metadata = try? await metadataService.fetchMetadata(from: idea.link),
                              metadata.imageUrl?.isEmpty == false
                        else { return nil }
                        return GiftSuggestion(idea: idea, metadata: metadata)
                    }
                }
                var found: [GiftSuggestion] = []
                for await result in group {
                    if let result { found.append(result) }
                }
                return found
            }

            for suggestion in validated where suggestions.count < maxResults {
                suggestions.append(suggestion)
            }
        }
    }
}
```

Note on the test for "keeps first six": validation runs in batches of 3, and within a batch order is not guaranteed, but failures (#2, #5) are always excluded and the count caps at 6 — which is exactly what the assertions check. The `dropsFailures` assertion checks membership, not position.

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:WishieTests/GiftSuggestionViewModelTests`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add Wishie/Screens/GiftSuggestions/GiftSuggestionViewModel.swift WishieTests/MockProductMetadataService.swift WishieTests/GiftSuggestionViewModelTests.swift WishieTests/MockAuthenticateService.swift
git commit -m "feat: add gift suggestion view model with validation pipeline"
```

---

## Task 5: Results sheet + card UI

The sheet the owner sees: loading state, streamed cards each with Add, the no-interests picker, and error/empty + retry. No new business logic — pure SwiftUI over Task 4's view model.

**Files:**
- Create: `Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift`
- Create: `Wishie/Screens/GiftSuggestions/GiftSuggestionsSheet.swift`

**Interfaces:**
- Consumes: `GiftSuggestionViewModel`, `GiftSuggestion` (Task 4/1), `hobbyCategories` + `HobbyChipView` (existing), `WishieButton`, `WishieWebImage`.
- Produces:
  - `struct GiftSuggestionCard: View` — `init(suggestion: GiftSuggestion, onAdd: () -> Void)`
  - `struct GiftSuggestionsSheet: View` — `init(existingItemNames: [String], onAdd: @escaping (WishlistItem) -> Void)`

- [ ] **Step 1: Implement the card**

Create `Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift`:

```swift
import SwiftUI

struct GiftSuggestionCard: View {
    let suggestion: GiftSuggestion
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let imageUrl = suggestion.metadata.imageUrl {
                WishieWebImage(url: imageUrl)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.metadata.title.isEmpty ? suggestion.idea.name : suggestion.metadata.title)
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(.black)
                    .lineLimit(2)

                let price = suggestion.metadata.price?.isEmpty == false ? suggestion.metadata.price! : suggestion.idea.price
                if !price.isEmpty {
                    Text(price)
                        .font(.wishies(.bold, 13))
                        .foregroundStyle(.wishiePink)
                }

                if !suggestion.idea.description.isEmpty {
                    Text(suggestion.idea.description)
                        .font(.wishies(.regular, 12))
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.wishiePink))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.wishiePink.opacity(0.12), lineWidth: 1.5))
        )
    }
}
```

- [ ] **Step 2: Implement the sheet**

Create `Wishie/Screens/GiftSuggestions/GiftSuggestionsSheet.swift`:

```swift
import SwiftUI
import DotLottie

struct GiftSuggestionsSheet: View {
    @StateObject private var viewModel: GiftSuggestionViewModel
    @Environment(\.dismiss) private var dismiss
    private let onAdd: (WishlistItem) -> Void

    @State private var selectedInterestIds: Set<String> = []
    @State private var addedIds: Set<String> = []

    init(existingItemNames: [String], onAdd: @escaping (WishlistItem) -> Void) {
        self.onAdd = onAdd
        _viewModel = StateObject(wrappedValue: GiftSuggestionViewModel(existingItemNames: existingItemNames))
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(.gray.opacity(0.3)).frame(width: 40, height: 4).padding(.top, 12)
            Text("Gift ideas for you").font(.wishies(.bold, 20))

            content
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .task { await viewModel.start() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .loading:
            loadingView
        case .needsInterests:
            interestPicker
        case .results, .empty:
            resultsView
        case .error(let message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            DotLottieAnimation(fileName: "giftloading", config: AnimationConfig(autoplay: true, loop: true)).view()
                .frame(width: 100)
            Text("Finding gifts that match your interests…")
                .font(.wishies(.regular, 14))
                .foregroundStyle(.gray)
        }
        .frame(maxHeight: .infinity)
    }

    private var resultsView: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.suggestions) { suggestion in
                        GiftSuggestionCard(suggestion: suggestion) {
                            onAdd(suggestion.toWishlistItem())
                            addedIds.insert(suggestion.id)
                        }
                        .opacity(addedIds.contains(suggestion.id) ? 0.5 : 1)
                    }
                }
                .padding(.vertical, 4)
            }
            if viewModel.phase == .empty {
                Text("We couldn't find enough matches. Try again?")
                    .font(.wishies(.regular, 13))
                    .foregroundStyle(.gray)
                WishieButton(title: "Try again") { Task { await viewModel.generate() } }
            }
        }
    }

    private var interestPicker: some View {
        VStack(spacing: 12) {
            Text("Pick a few interests so we can suggest gifts")
                .font(.wishies(.regular, 14))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(hobbyCategories) { category in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.title).font(.wishies(.bold, 16))
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                                ForEach(category.items) { item in
                                    HobbyChipView(
                                        item: item,
                                        isSelected: selectedInterestIds.contains(item.id),
                                        onTap: {
                                            if selectedInterestIds.contains(item.id) {
                                                selectedInterestIds.remove(item.id)
                                            } else {
                                                selectedInterestIds.insert(item.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            WishieButton(title: "Continue", enabled: !selectedInterestIds.isEmpty) {
                Task { await viewModel.saveInterestsAndContinue(Array(selectedInterestIds)) }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.wishies(.regular, 14))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
            WishieButton(title: "Try again") { Task { await viewModel.generate() } }
        }
        .frame(maxHeight: .infinity)
    }
}
```

- [ ] **Step 3: Build to verify it compiles**

Run: `xcodebuild build -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Wishie/Screens/GiftSuggestions/GiftSuggestionCard.swift Wishie/Screens/GiftSuggestions/GiftSuggestionsSheet.swift
git commit -m "feat: add gift suggestions results sheet and card"
```

---

## Task 6: Wire entry points (add-item sheet, detail screen, create flow)

Add the third option to the shared sheet and present `GiftSuggestionsSheet` from both hosts.

**Files:**
- Modify: `Wishie/Screens/CreateList/AddItemOptionSheet.swift`
- Modify: `Wishie/Screens/Detail/WishlistDetailScreen.swift`
- Modify: `Wishie/Screens/CreateList/CreateWishlistPage2.swift`

**Interfaces:**
- Consumes: `GiftSuggestionsSheet` (Task 5), `WishlistDetailViewController.wishlistInfo.items` and `wishlistService.addWishlistItem`, `CreateWishlistViewModel.items`.
- Produces: `AddItemOptionSheet` gains `let onSuggestGifts: () -> Void`.

- [ ] **Step 1: Add the third option to `AddItemOptionSheet`**

In `Wishie/Screens/CreateList/AddItemOptionSheet.swift`, add the property and a third `optionCard`.

Add after `let onManual: () -> Void`:

```swift
    let onSuggestGifts: () -> Void
```

Add after the `onManual` `optionCard(...)` block (still inside the `VStack`):

```swift
            optionCard(
                icon: "sparkles",
                iconTint: .wishiePink,
                title: "Suggest gifts for me",
                subtitle: "Get ideas based on your interests",
                borderColor: .wishiePink.opacity(0.15),
                action: onSuggestGifts
            )
```

- [ ] **Step 2: Wire the detail screen**

In `Wishie/Screens/Detail/WishlistDetailScreen.swift`:

Add a presentation flag near the other `@State` (top of the view, next to `sheetHeight`):

```swift
    @State private var showSuggestGiftsSheet: Bool = false
```

Update the `AddItemOptionSheet(...)` call (the one around the `showAddItemOptionSheet` sheet) to pass the new callback:

```swift
            AddItemOptionSheet(
                onPasteLink: {
                    viewModel.showAddItemOptionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showAddItemPasteLinkSheet = true
                    }
                },
                onManual: {
                    viewModel.showAddItemOptionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.showAddItemManualSheet = true
                    }
                },
                onSuggestGifts: {
                    viewModel.showAddItemOptionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showSuggestGiftsSheet = true
                    }
                }
            )
            .presentationDetents([.height(340)])
```

Add a new `.sheet` after the `showAddItemPasteLinkSheet` sheet:

```swift
        .sheet(isPresented: $showSuggestGiftsSheet) {
            GiftSuggestionsSheet(
                existingItemNames: GiftSuggestionInputBuilder.existingItemNames(from: viewModel.wishlistInfo.items)
            ) { item in
                Task {
                    _ = try? await viewModel.addSuggestedItem(item, wishlistId: viewModel.wishlistInfo.id)
                }
            }
            .presentationDetents([.large])
        }
```

Add a helper to `WishlistDetailViewController` (`Wishie/Screens/Detail/WishlistDetailViewController.swift`), after `addNewWishlistItem`:

```swift
    func addSuggestedItem(_ item: WishlistItem, wishlistId: String) async throws {
        if checkIfItemExists(withLink: item.itemLink) { return }
        _ = try await wishlistService.addWishlistItem(wishlistId: wishlistId, item: item)
    }
```

- [ ] **Step 3: Wire the create flow**

In `Wishie/Screens/CreateList/CreateWishlistPage2.swift`:

Add a flag near the other `@State`:

```swift
    @State private var showSuggestGiftsSheet: Bool = false
```

Update the `AddItemOptionSheet(...)` call to add the callback:

```swift
            AddItemOptionSheet(
                onPasteLink: {
                    showAddItemOptionSheet = false
                    showPasteLinkSheet = true
                },
                onManual: {
                    createWishlistViewModel.items.append(WishlistItem())
                    showAddItemOptionSheet = false
                },
                onSuggestGifts: {
                    showAddItemOptionSheet = false
                    showSuggestGiftsSheet = true
                }
            )
            .presentationDetents([.height(340)])
```

Add a `.sheet` after the `showPasteLinkSheet` sheet:

```swift
        .sheet(isPresented: $showSuggestGiftsSheet) {
            GiftSuggestionsSheet(
                existingItemNames: GiftSuggestionInputBuilder.existingItemNames(from: createWishlistViewModel.items)
            ) { item in
                createWishlistViewModel.items.append(item)
            }
            .presentationDetents([.large])
        }
```

- [ ] **Step 4: Build to verify everything compiles**

Run: `xcodebuild build -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: BUILD SUCCEEDED.

- [ ] **Step 5: Run the full test suite**

Run: `xcodebuild test -scheme Wishie -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`
Expected: PASS (existing tests + new gift suggestion tests).

- [ ] **Step 6: Commit**

```bash
git add Wishie/Screens/CreateList/AddItemOptionSheet.swift Wishie/Screens/Detail/WishlistDetailScreen.swift Wishie/Screens/Detail/WishlistDetailViewController.swift Wishie/Screens/CreateList/CreateWishlistPage2.swift
git commit -m "feat: wire gift suggestions into add-item sheet, detail, and create flow"
```

---

## Manual Verification (after deploying the Function)

1. Ensure the Function is deployed and `GEMINI_API_KEY` secret is set (Task 2 Step 7).
2. Run the app on a simulator/device signed into a user **with interests set**.
3. Open a wishlist you own → **+** → **"Suggest gifts for me"**. Confirm the loading animation shows, then 5-6 cards stream in with image, name, price, description.
4. Tap **Add** on a card → confirm the item appears in the wishlist (Firestore).
5. Repeat from the create-wishlist flow (Page 2 → Add another gift → Suggest gifts) → confirm added items appear in the draft list.
6. Sign in as a user **with no interests** → open Suggest gifts → confirm the interest picker appears, select a few, tap Continue → confirm generation proceeds.
7. Turn off networking / use a bad key to confirm the error state + Try again path.

---

## Self-Review Notes

- **Spec coverage:** audience/owner (Task 6 owner-only entry) ✓; Gemini via Firebase callable (Task 2/3) ✓; over-request 8-10 keep 6 (Task 2 prompt + Task 4 `maxResults`) ✓; scrape/validate via `ProductMetadataService` (Task 4) ✓; interests + age + dedupe inputs (Task 1 builder, Task 4 wiring) ✓; no-interests picker then resume (Task 4 `saveInterestsAndContinue`, Task 5 picker) ✓; progressive reveal (Task 4 batched publish, Task 5 streamed cards) ✓; both entry points (Task 6) ✓; full-info `WishlistItem` on Add (Task 1 `toWishlistItem`) ✓; tests for builder/parse/pipeline/mapping (Tasks 1,4) ✓.
- **No key in app:** key only in Function secret (Task 2) ✓.
- **Out of scope kept out:** no gift-giver mode, occasion tuning, caching, or server-side scraping.
```

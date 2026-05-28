# Task 1: Data Layer — Model and Service Updates

- [ ] 1.1: In `Wishie/Models/UserModel.swift` UPDATE:
  - Add `var interests: [String] = []` property to `UserModel`.
  - Add `var hasCompletedInterestsSetup: Bool = false` property to `UserModel`.
  - In `init(dictionary:)`, decode `interests` as `dictionary["interests"] as? [String] ?? []`.
  - In `init(dictionary:)`, decode `hasCompletedInterestsSetup` as `dictionary["hasCompletedInterestsSetup"] as? Bool ?? false`.

- [ ] 1.2: In `Wishie/Models/HobbyCategory.swift` CREATE:
  - Define `struct HobbyItem: Identifiable, Hashable` with fields `id: String`, `name: String`, `emoji: String`.
  - Define `struct HobbyCategory: Identifiable` with fields `id: String`, `title: String`, `items: [HobbyItem]`.
  - Define a top-level `let hobbyCategories: [HobbyCategory]` constant with all 6 categories and their items:
    - `id: "active_sports"`, title: `"Active & Sports"`: `HobbyItem(id: "sports", name: "Sports", emoji: "🏅")`, `HobbyItem(id: "gym_fitness", name: "Gym & Fitness", emoji: "🏋️")`, `HobbyItem(id: "yoga_meditation", name: "Yoga & Meditation", emoji: "🧘")`, `HobbyItem(id: "hiking_trekking", name: "Hiking & Trekking", emoji: "🥾")`, `HobbyItem(id: "cycling", name: "Cycling", emoji: "🚴")`, `HobbyItem(id: "swimming", name: "Swimming", emoji: "🏊")`
    - `id: "creative"`, title: `"Creative"`: `HobbyItem(id: "reading", name: "Reading", emoji: "📚")`, `HobbyItem(id: "drawing_painting", name: "Drawing & Painting", emoji: "🎨")`, `HobbyItem(id: "photography", name: "Photography", emoji: "📸")`, `HobbyItem(id: "writing_journaling", name: "Writing & Journaling", emoji: "✍️")`, `HobbyItem(id: "music", name: "Music", emoji: "🎵")`, `HobbyItem(id: "crafting_diy", name: "Crafting & DIY", emoji: "🧶")`
    - `id: "entertainment_tech"`, title: `"Entertainment & Tech"`: `HobbyItem(id: "gaming", name: "Gaming", emoji: "🎮")`, `HobbyItem(id: "movies_series", name: "Watching Movies & Series", emoji: "🎬")`, `HobbyItem(id: "podcasts", name: "Podcasts", emoji: "🎙️")`, `HobbyItem(id: "anime_manga", name: "Anime & Manga", emoji: "🌸")`
    - `id: "food_drink"`, title: `"Food & Drink"`: `HobbyItem(id: "cooking_baking", name: "Cooking & Baking", emoji: "🍳")`, `HobbyItem(id: "food_exploring", name: "Food Exploring", emoji: "🍜")`, `HobbyItem(id: "coffee_tea", name: "Coffee & Tea", emoji: "☕")`
    - `id: "travel_outdoor"`, title: `"Travel & Outdoor"`: `HobbyItem(id: "traveling", name: "Traveling", emoji: "✈️")`, `HobbyItem(id: "camping", name: "Camping", emoji: "⛺")`, `HobbyItem(id: "nature_gardening", name: "Nature & Gardening", emoji: "🌿")`
    - `id: "selfcare_lifestyle"`, title: `"Self-care & Lifestyle"`: `HobbyItem(id: "beauty_skincare", name: "Beauty & Skincare", emoji: "💆")`, `HobbyItem(id: "fashion_styling", name: "Fashion & Styling", emoji: "👗")`, `HobbyItem(id: "collecting", name: "Collecting", emoji: "🗄️")`, `HobbyItem(id: "dancing", name: "Dancing", emoji: "💃")`

- [ ] 1.3: In `Wishie/Services/AuthenticateService.swift` UPDATE:
  - Add `func updateUserInterests(userId: String, interests: [String]) async throws` to `AuthenticateServiceProtocol`.
  - Implement in `AuthenticateService`: call `try await db.collection(WishieConstants.firebaseUserPath).document(userId).updateData(["interests": interests, "hasCompletedInterestsSetup": true])`.

---


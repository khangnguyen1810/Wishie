import Foundation

struct HobbyItem: Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
}

struct HobbyCategory: Identifiable {
    let id: String
    let title: String
    let items: [HobbyItem]
}

let hobbyCategories: [HobbyCategory] = [
    HobbyCategory(
        id: "active_sports",
        title: "Active & Sports",
        items: [
            HobbyItem(id: "sports", name: "Sports", emoji: "🏅"),
            HobbyItem(id: "gym_fitness", name: "Gym & Fitness", emoji: "🏋️"),
            HobbyItem(id: "yoga_meditation", name: "Yoga & Meditation", emoji: "🧘"),
            HobbyItem(id: "hiking_trekking", name: "Hiking & Trekking", emoji: "🥾"),
            HobbyItem(id: "cycling", name: "Cycling", emoji: "🚴"),
            HobbyItem(id: "swimming", name: "Swimming", emoji: "🏊")
        ]
    ),
    HobbyCategory(
        id: "creative",
        title: "Creative",
        items: [
            HobbyItem(id: "reading", name: "Reading", emoji: "📚"),
            HobbyItem(id: "drawing_painting", name: "Drawing & Painting", emoji: "🎨"),
            HobbyItem(id: "photography", name: "Photography", emoji: "📸"),
            HobbyItem(id: "writing_journaling", name: "Writing & Journaling", emoji: "✍️"),
            HobbyItem(id: "music", name: "Music", emoji: "🎵"),
            HobbyItem(id: "crafting_diy", name: "Crafting & DIY", emoji: "🧶")
        ]
    ),
    HobbyCategory(
        id: "entertainment_tech",
        title: "Entertainment & Tech",
        items: [
            HobbyItem(id: "gaming", name: "Gaming", emoji: "🎮"),
            HobbyItem(id: "movies_series", name: "Watching Movies & Series", emoji: "🎬"),
            HobbyItem(id: "podcasts", name: "Podcasts", emoji: "🎙️"),
            HobbyItem(id: "anime_manga", name: "Anime & Manga", emoji: "🌸")
        ]
    ),
    HobbyCategory(
        id: "food_drink",
        title: "Food & Drink",
        items: [
            HobbyItem(id: "cooking_baking", name: "Cooking & Baking", emoji: "🍳"),
            HobbyItem(id: "food_exploring", name: "Food Exploring", emoji: "🍜"),
            HobbyItem(id: "coffee_tea", name: "Coffee & Tea", emoji: "☕")
        ]
    ),
    HobbyCategory(
        id: "travel_outdoor",
        title: "Travel & Outdoor",
        items: [
            HobbyItem(id: "traveling", name: "Traveling", emoji: "✈️"),
            HobbyItem(id: "camping", name: "Camping", emoji: "⛺"),
            HobbyItem(id: "nature_gardening", name: "Nature & Gardening", emoji: "🌿")
        ]
    ),
    HobbyCategory(
        id: "selfcare_lifestyle",
        title: "Self-care & Lifestyle",
        items: [
            HobbyItem(id: "beauty_skincare", name: "Beauty & Skincare", emoji: "💆"),
            HobbyItem(id: "fashion_styling", name: "Fashion & Styling", emoji: "👗"),
            HobbyItem(id: "collecting", name: "Collecting", emoji: "🗄️"),
            HobbyItem(id: "dancing", name: "Dancing", emoji: "💃")
        ]
    )
]

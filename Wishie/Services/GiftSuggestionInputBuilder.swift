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

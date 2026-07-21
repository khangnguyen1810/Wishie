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

    /// English country name for an ISO region code (e.g. "VN" -> "Vietnam").
    static func countryName(fromRegionCode code: String?) -> String? {
        guard let code, !code.isEmpty else { return nil }
        return Locale(identifier: "en_US").localizedString(forRegionCode: code)
    }

    /// English country name for the device's current region, if any.
    static func deviceRegionCountryName() -> String? {
        countryName(fromRegionCode: Locale.current.region?.identifier)
    }
}

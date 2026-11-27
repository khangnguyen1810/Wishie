//
//  HomeCardSummary.swift
//  Wishie
//

import Foundation

/// Everything the Home moodboard cards show about one wishlist, derived without touching SwiftUI.
struct HomeCardSummary {
    let wishlist: WishlistModel
    let currentUserId: String?

    enum Countdown: Equatable {
        case daysLeft(Int)
        case today
        case past

        /// Big counter on the featured card.
        var value: String {
            switch self {
            case .daysLeft(let days): return "\(days)"
            case .today: return "Today!"
            case .past: return "Past"
            }
        }

        /// Caption under the big counter; empty when the value says it all.
        var caption: String {
            switch self {
            case .daysLeft(let days): return days == 1 ? "day left" : "days left"
            case .today, .past: return ""
            }
        }

        /// Trailing label on a compact card.
        var short: String {
            switch self {
            case .daysLeft(let days): return "\(days)d"
            case .today: return "Today"
            case .past: return "Past"
            }
        }
    }

    // MARK: - Items

    var topItem: WishlistItem? {
        wishlist.items.first(where: \.isMostDesired) ?? wishlist.items.first
    }

    var isTopItemMostDesired: Bool {
        topItem?.isMostDesired ?? false
    }

    /// Items after the top wish, in list order.
    var otherItems: [WishlistItem] {
        guard let topItem else { return [] }
        return wishlist.items.filter { $0.id != topItem.id }
    }

    /// Items the featured card's three tiles can't show, rendered as "+N" on the last tile.
    var extraCount: Int {
        max(0, wishlist.items.count - 3)
    }

    func isPickedByMe(_ item: WishlistItem) -> Bool {
        guard let currentUserId, item.isPicked else { return false }
        return item.pickedUserId == currentUserId
    }

    // MARK: - Text

    func statusText(isOwnList: Bool) -> String {
        let total = wishlist.items.count
        guard total > 0 else { return "No gifts yet" }
        let picked = wishlist.items.filter(\.isPicked).count
        return isOwnList ? "\(picked) of \(total) picked" : "\(total - picked) of \(total) still free"
    }

    func countdown(today: Date = Date(), calendar: Calendar = .current) -> Countdown {
        let days = Self.daysBetween(today, wishlist.dueDate, calendar: calendar)
        if days > 0 { return .daysLeft(days) }
        return days == 0 ? .today : .past
    }

    static func ownerFirstName(profile: UserModel, wishlist: WishlistModel) -> String {
        profile.firstName.isEmpty ? (wishlist.ownerName ?? "") : profile.firstName
    }

    // MARK: - List-level helpers

    /// The featured card is the nearest wishlist due today or later; with nothing upcoming, the first one.
    static func splitFeatured<T>(
        _ entries: [T],
        today: Date = Date(),
        calendar: Calendar = .current,
        wishlist: (T) -> WishlistModel
    ) -> (featured: T?, rest: [T]) {
        let upcoming = entries.indices
            .filter { daysBetween(today, wishlist(entries[$0]).dueDate, calendar: calendar) >= 0 }
            .min { wishlist(entries[$0]).dueDate < wishlist(entries[$1]).dueDate }
        guard let index = upcoming ?? entries.indices.first else { return (nil, []) }
        var rest = entries
        let featured = rest.remove(at: index)
        return (featured, rest)
    }

    static func subtitle(
        isMyList: Bool,
        mine: [WishlistModel],
        friends: [WishlistModel],
        today: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        if !isMyList {
            let owners = Set(friends.map(ownerId))
            if !owners.isEmpty {
                return owners.count == 1 ? "1 friend is wishing" : "\(owners.count) friends are wishing"
            }
        }
        let upcoming = mine.filter { daysBetween(today, $0.dueDate, calendar: calendar) >= 0 }.count
        switch upcoming {
        case 0: return "What are you wishing for?"
        case 1: return "1 wishlist coming up"
        default: return "\(upcoming) wishlists coming up"
        }
    }

    private static func ownerId(_ wishlist: WishlistModel) -> String {
        wishlist.members.first { $0.value == .owner }?.key ?? wishlist.userCreateId
    }

    private static func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: from), to: calendar.startOfDay(for: to)).day ?? 0
    }
}

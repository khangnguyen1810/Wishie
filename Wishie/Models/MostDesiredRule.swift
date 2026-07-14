//
//  MostDesiredRule.swift
//  Wishie
//

import Foundation

/// A wishlist may hold at most one most-desired item. Marking a new item therefore has to
/// clear the flag on whichever item held it before, in the same write.
enum MostDesiredRule {
    static func apply(
        items: [[String: Any]],
        itemId: String,
        isMostDesired: Bool
    ) -> [[String: Any]] {
        items.map { item in
            var item = item
            guard let id = item["id"] as? String else { return item }
            if id == itemId {
                item["isMostDesired"] = isMostDesired
            } else if isMostDesired {
                item["isMostDesired"] = false
            }
            return item
        }
    }
}

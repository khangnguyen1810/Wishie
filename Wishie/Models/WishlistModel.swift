//
//  WishlistModel.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 17/12/25.
//

import Foundation
import FirebaseCore

enum WishlistRole: String, Codable {
    case owner
    case member
}

struct WishlistModel: Identifiable, Hashable {
    let id: String
    var name: String
    var description: String
    var dueDate: Date
    var items: [WishlistItem]
    var themeColor: String?
    var userCreateId: String
    let members: [String: WishlistRole]
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        dueDate: Date = Date(),
        items: [WishlistItem] = [],
        themeColor :String? = nil,
        userCreateId: String,
        members: [String: WishlistRole] = [:]) {
            self.id = id
            self.name = name
            self.description = description
            self.dueDate = dueDate
            self.items = items
            self.userCreateId = userCreateId
            self.themeColor = themeColor
            self.members = members
        }
   func isOwner() -> Bool {
       guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return false }
       return members[userId] == .owner
    }
    var theme: GradientTheme {
        GradientTheme(rawValue: themeColor ?? "sunset") ?? .sunset
    }
    func getItemsRemaining() -> Int {
        let itemPickedCount = items.lazy.filter({ $0.isPicked }).count
        return items.count - itemPickedCount
    }
    func isUserJoined() -> Bool {
        guard let userId = UserDefaults.standard.string(forKey: WishieConstants.userIdKey) else { return false }
        return members[userId] != nil
    }
}
extension WishlistModel {

    init(dictionary: [String: Any]) throws {

        guard
            let id = dictionary["id"] as? String,
            let name = dictionary["wishListName"] as? String,
            let description = dictionary["description"] as? String,
            let userCreateId = dictionary["userCreateId"] as? String
        else {
            throw NSError(
                domain: "WishlistModel",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid wishlist data"]
            )
        }

        self.id = id
        self.name = name
        self.description = description
        self.userCreateId = userCreateId
        self.dueDate = (dictionary["dueDate"] as? Timestamp)?.dateValue() ?? Date()
        self.themeColor = dictionary["colorTheme"] as? String
        if let membersDict = dictionary["members"] as? [String: String] {
            self.members = membersDict.compactMapValues { WishlistRole(rawValue: $0) }
        } else {
            self.members = [:]
        }
        if let itemsData = dictionary["wishListItems"] as? [[String: Any]] {
            self.items = try itemsData.map { try WishlistItem(dictionary: $0) }
        } else {
            self.items = []
        }
    }
}

//
//  WishlistItem.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import Foundation
import UIKit

struct WishlistItem: Identifiable, Hashable{
    let id: String
    var name: String
    var description: String
    var image: String?
    var pickedUserId: String?
    var isPicked: Bool
    var isMostDesired: Bool
    var localImage: UIImage?
    var itemLink: String

    init(
        id: String = UUID().uuidString,
        name: String = "",
        description: String = "",
        image: String? = nil,
        pickedUserId: String? = nil,
        isPicked: Bool = false,
        isMostDesired: Bool = false,
        localImage: UIImage? = nil,
        itemLink: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.image = image
        self.pickedUserId = pickedUserId
        self.isPicked = isPicked
        self.isMostDesired = isMostDesired
        self.localImage = localImage
        self.itemLink = itemLink
    }
}
extension WishlistItem {

    init(dictionary: [String: Any]) throws {

        guard
            let id = dictionary["id"] as? String,
            let name = dictionary["name"] as? String
        else {
            throw NSError(
                domain: "WishlistItem",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Invalid wishlist item data"]
            )
        }

        self.id = id
        self.name = name
        self.description = dictionary["description"] as? String ?? ""
        self.image = dictionary["imageUrl"] as? String
        self.isPicked = dictionary["isPicked"] as? Bool ?? false
        self.pickedUserId = dictionary["pickedBy"] as? String
        self.itemLink = dictionary["itemLink"] as? String ?? ""
        self.isMostDesired = dictionary["isMostDesired"] as? Bool ?? false
        self.localImage = nil
    }
}

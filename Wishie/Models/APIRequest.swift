import Foundation

struct SignUpRequest {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var dateOfBirth: Date = Date()
}

struct CreateWishlistItemRequest: Encodable {
    let id: String
    let name: String
    let description: String
    let itemLink: String
    let price: String?

    init(_ item: WishlistItem) {
        self.id = item.id
        self.name = item.name
        self.description = item.description
        self.itemLink = item.itemLink
        self.price = item.price
    }
}

struct CreateWishlistRequest: Encodable {
    let id: String
    let name: String
    let description: String
    let dueDate: String
    let colorTheme: String?
    let items: [CreateWishlistItemRequest]

    init(_ wishlist: WishlistModel) {
        self.id = wishlist.id
        self.name = wishlist.name
        self.description = wishlist.description
        self.dueDate = WishieDateFormatting.dateOnly.string(from: wishlist.dueDate)
        self.colorTheme = wishlist.themeColor
        self.items = wishlist.items.map(CreateWishlistItemRequest.init)
    }
}

import Testing
import Foundation
@testable import Wishie

struct APIRequestTests {
    @Test func createWishlistItemRequestEncodesExpectedFields() throws {
        let item = WishlistItem(id: "i1", name: "Lego", description: "Fun set", itemLink: "https://shop.example.com", price: "19.99")
        let request = CreateWishlistItemRequest(item)

        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["id"] as? String == "i1")
        #expect(json["name"] as? String == "Lego")
        #expect(json["description"] as? String == "Fun set")
        #expect(json["itemLink"] as? String == "https://shop.example.com")
        #expect(json["price"] as? String == "19.99")
        #expect(json["imageUrl"] == nil)
    }

    @Test func createWishlistRequestEncodesExpectedFieldsIncludingItemsAndDateOnly() throws {
        let dueDate = try #require(WishieDateFormatting.dateOnly.date(from: "2026-09-01"))
        let item = WishlistItem(id: "i1", name: "Lego", itemLink: "https://shop.example.com", price: "19.99")
        let wishlist = WishlistModel(
            id: "w1",
            name: "Birthday",
            description: "Party",
            dueDate: dueDate,
            items: [item],
            themeColor: "sunset",
            userCreateId: "u1"
        )
        let request = CreateWishlistRequest(wishlist)

        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["id"] as? String == "w1")
        #expect(json["name"] as? String == "Birthday")
        #expect(json["description"] as? String == "Party")
        #expect(json["dueDate"] as? String == "2026-09-01")
        #expect(json["colorTheme"] as? String == "sunset")
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.count == 1)
        #expect(items[0]["id"] as? String == "i1")
    }
}

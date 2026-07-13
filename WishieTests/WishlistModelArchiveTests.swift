import Testing
@testable import Wishie

struct WishlistModelArchiveTests {

    @Test func memberwiseInitDefaultsToNotArchived() {
        let wishlist = WishlistModel(name: "Test", userCreateId: "u1")
        #expect(wishlist.isArchived == false)
    }

    @Test func dictionaryInitDefaultsToNotArchivedWhenFieldMissing() throws {
        let dictionary: [String: Any] = [
            "id": "1",
            "wishListName": "Test",
            "description": "",
            "userCreateId": "u1"
        ]
        let wishlist = try WishlistModel(dictionary: dictionary)
        #expect(wishlist.isArchived == false)
    }

    @Test func dictionaryInitReadsArchivedTrue() throws {
        let dictionary: [String: Any] = [
            "id": "1",
            "wishListName": "Test",
            "description": "",
            "userCreateId": "u1",
            "isArchived": true
        ]
        let wishlist = try WishlistModel(dictionary: dictionary)
        #expect(wishlist.isArchived == true)
    }
}

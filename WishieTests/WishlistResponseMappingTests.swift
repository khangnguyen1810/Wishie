// WishieTests/WishlistResponseMappingTests.swift
import Testing
import Foundation
@testable import Wishie

struct WishlistResponseMappingTests {
    private func sampleItemResponse(id: String = "i1", isMostDesired: Bool = false) -> WishlistItemResponse {
        WishlistItemResponse(
            id: id, wishlistId: "w1", name: "Lego Set", description: "Fun", imageUrl: "https://x/y.jpg",
            isPicked: true, pickedBy: "u2", itemLink: "https://shop", price: "19.99", isMostDesired: isMostDesired
        )
    }

    private func sampleResponse(members: [WishlistMemberResponse] = [], items: [WishlistItemResponse] = [], isArchived: Bool = false) -> WishlistResponse {
        WishlistResponse(
            id: "w1", name: "Birthday", description: "Party", ownerId: "u1",
            dueDate: "2026-09-01T00:00:00.000Z", colorTheme: "sunset", isArchived: isArchived,
            createdAt: "2026-01-01T00:00:00.000Z", members: members, items: items
        )
    }

    @Test func mapsBasicFieldsAndOwnerId() {
        let wishlist = WishlistModel(response: sampleResponse())

        #expect(wishlist.id == "w1")
        #expect(wishlist.name == "Birthday")
        #expect(wishlist.description == "Party")
        #expect(wishlist.userCreateId == "u1")
        #expect(wishlist.themeColor == "sunset")
        #expect(wishlist.isArchived == false)
    }

    @Test func foldsMembersArrayIntoTheRoleDictionary() {
        let members = [
            WishlistMemberResponse(wishlistId: "w1", userId: "u1", role: "owner", joinedAt: "2026-01-01T00:00:00.000Z"),
            WishlistMemberResponse(wishlistId: "w1", userId: "u2", role: "member", joinedAt: "2026-01-02T00:00:00.000Z")
        ]
        let wishlist = WishlistModel(response: sampleResponse(members: members))

        #expect(wishlist.members["u1"] == .owner)
        #expect(wishlist.members["u2"] == .member)
        #expect(wishlist.isOwner() == false) // isOwner() reads the current device's userId, unset in this test
    }

    @Test func mapsItemsViaWishlistItemInitResponse() throws {
        let wishlist = WishlistModel(response: sampleResponse(items: [sampleItemResponse()]))

        #expect(wishlist.items.count == 1)
        let item = try #require(wishlist.items.first)
        #expect(item.id == "i1")
        #expect(item.name == "Lego Set")
        #expect(item.image == "https://x/y.jpg")
        #expect(item.isPicked == true)
        #expect(item.pickedUserId == "u2")
        #expect(item.price == "19.99")
    }

    @Test func handlesNilMembersAndItemsAsEmpty() {
        let response = WishlistResponse(
            id: "w1", name: "Birthday", description: "Party", ownerId: "u1",
            dueDate: "2026-09-01T00:00:00.000Z", colorTheme: nil, isArchived: false,
            createdAt: "2026-01-01T00:00:00.000Z", members: nil, items: nil
        )
        let wishlist = WishlistModel(response: response)

        #expect(wishlist.members.isEmpty)
        #expect(wishlist.items.isEmpty)
    }
}

import Testing
import Foundation
@testable import Wishie

struct GiftSuggestionParsingTests {

    @Test func parseReadsIdeasArray() {
        let payload: [String: Any] = [
            "ideas": [
                ["name": "Mechanical Keyboard", "description": "Clicky keys", "price": "$80", "link": "https://ex.com/kb"],
                ["name": "Board Game", "description": "Fun night", "price": "$30", "link": "https://ex.com/bg"]
            ]
        ]
        let ideas = GiftIdea.parse(from: payload)
        #expect(ideas.count == 2)
        #expect(ideas[0].name == "Mechanical Keyboard")
        #expect(ideas[0].link == "https://ex.com/kb")
    }

    @Test func parseSkipsEntriesMissingNameOrLink() {
        let payload: [String: Any] = [
            "ideas": [
                ["name": "Good", "description": "d", "price": "$1", "link": "https://ex.com/a"],
                ["description": "no name", "price": "$1", "link": "https://ex.com/b"],
                ["name": "No link", "description": "d", "price": "$1"]
            ]
        ]
        let ideas = GiftIdea.parse(from: payload)
        #expect(ideas.count == 1)
        #expect(ideas[0].name == "Good")
    }

    @Test func parseReturnsEmptyForBadPayload() {
        #expect(GiftIdea.parse(from: nil).isEmpty)
        #expect(GiftIdea.parse(from: "nope").isEmpty)
    }

    @Test func toWishlistItemPopulatesAllFields() {
        let idea = GiftIdea(name: "Keyboard", description: "Clicky", price: "$80", link: "https://ex.com/kb")
        let metadata = ProductMetadata(
            title: "Real Keyboard",
            productDescription: "From store",
            imageUrl: "https://ex.com/img.jpg",
            productUrl: "https://ex.com/kb",
            price: "$79"
        )
        let item = GiftSuggestion(idea: idea, metadata: metadata).toWishlistItem()
        #expect(item.name == "Real Keyboard")
        #expect(item.image == "https://ex.com/img.jpg")
        #expect(item.itemLink == "https://ex.com/kb")
        #expect(item.price == "$79")
        #expect(item.description == "From store")
    }
}

//
//  SampleWishlistTests.swift
//  WishieTests
//

import Testing
@testable import Wishie

struct SampleWishlistTests {
    @Test func eachAuthScreenThemeHasASampleInThatTheme() {
        for theme in [GradientTheme.coral, .mint, .grape, .gold] {
            #expect(SampleWishlist.sample(for: theme).theme == theme)
        }
    }

    @Test func sampleTitlesMatchTheSpec() {
        #expect(SampleWishlist.sample(for: .coral).title == "Birthday 2026")
        #expect(SampleWishlist.sample(for: .mint).title == "Housewarming")
        #expect(SampleWishlist.sample(for: .grape).title == "Tết wishlist")
        #expect(SampleWishlist.sample(for: .gold).title == "Wedding")
    }

    @Test func weddingSampleHasThreeUnreservedItems() {
        let wedding = SampleWishlist.sample(for: .gold)
        #expect(wedding.subtitle == "10 items")
        #expect(wedding.items.map(\.name) == ["Dinner set", "Wine glasses", "Photo frame"])
        #expect(wedding.items.allSatisfy { !$0.reserved })
    }

    @Test func aThemeWithoutItsOwnSampleFallsBackToTheFrontCard() {
        #expect(SampleWishlist.sample(for: .green).title == "Birthday 2026")
    }
}

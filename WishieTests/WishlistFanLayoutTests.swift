//
//  WishlistFanLayoutTests.swift
//  WishieTests
//

import Testing
import CoreGraphics
@testable import Wishie

struct WishlistFanLayoutTests {
    // MARK: cardWidth

    @Test func cardWidthIs56PercentOfContainerWidthWhenHeightIsGenerous() {
        let width = WishlistFanLayout.cardWidth(for: CGSize(width: 350, height: 600))
        #expect(abs(width - 196) < 0.001)
    }

    @Test func cardWidthIsCappedAt240OnAVeryWideContainer() {
        let width = WishlistFanLayout.cardWidth(for: CGSize(width: 1000, height: 1000))
        #expect(width == 240)
    }

    @Test func cardWidthShrinksSoTheFanFitsAShortContainer() {
        // Design fan is 280 tall at card width 220, so a 140-tall container allows half of that.
        let width = WishlistFanLayout.cardWidth(for: CGSize(width: 350, height: 140))
        #expect(abs(width - 110) < 0.001)
    }

    @Test func cardWidthIsZeroForAnEmptyContainer() {
        #expect(WishlistFanLayout.cardWidth(for: .zero) == 0)
    }

    @Test func cardWidthIsZeroForANegativeContainer() {
        #expect(WishlistFanLayout.cardWidth(for: CGSize(width: -20, height: -20)) == 0)
    }

    // MARK: hugging box

    @Test func fanExactlyFillsABoxOfItsAspectRatio() {
        // Neither side of such a box is spare: the width rule and the height rule give the same card width.
        let box = CGSize(width: 400, height: 400 / WishlistFanLayout.fanAspectRatio)
        let byWidth = box.width * WishlistFanLayout.cardWidthRatio
        let byHeight = WishlistFanLayout.designCardWidth * box.height / WishlistFanLayout.designFanHeight
        #expect(abs(byWidth - byHeight) < 0.001)
        #expect(abs(WishlistFanLayout.cardWidth(for: box) - byWidth) < 0.001)
    }

    @Test func cardsReachTheirWidthCapAtMaxFanWidth() {
        let box = CGSize(width: WishlistFanLayout.maxFanWidth, height: 1000)
        #expect(abs(WishlistFanLayout.cardWidth(for: box) - WishlistFanLayout.maxCardWidth) < 0.001)
    }

    // MARK: scale

    @Test func scaleIsCardWidthOverDesignCardWidth() {
        let scale = WishlistFanLayout.scale(for: CGSize(width: 350, height: 140))
        #expect(abs(scale - 0.5) < 0.001)
    }

    @Test func scaleIsZeroForAnEmptyContainer() {
        let scale = WishlistFanLayout.scale(for: .zero)
        #expect(scale == 0)
        #expect(scale.isFinite)
    }

    // MARK: angle

    @Test func backCardsRestAtFourteenDegreesMirrored() {
        #expect(WishlistFanLayout.angle(for: .left, swayed: false) == -14)
        #expect(WishlistFanLayout.angle(for: .right, swayed: false) == 14)
    }

    @Test func backCardsSwayToSeventeenDegreesMirrored() {
        #expect(WishlistFanLayout.angle(for: .left, swayed: true) == -17)
        #expect(WishlistFanLayout.angle(for: .right, swayed: true) == 17)
    }

    // MARK: shouldStartSway

    @Test func swayStartsOnFirstAppearWithMotionAllowed() {
        #expect(WishlistFanLayout.shouldStartSway(reduceMotion: false, alreadySwaying: false))
    }

    @Test func swayNeverStartsUnderReduceMotion() {
        #expect(!WishlistFanLayout.shouldStartSway(reduceMotion: true, alreadySwaying: false))
    }

    @Test func swayDoesNotRestartWhenTheScreenReappears() {
        #expect(!WishlistFanLayout.shouldStartSway(reduceMotion: false, alreadySwaying: true))
    }
}

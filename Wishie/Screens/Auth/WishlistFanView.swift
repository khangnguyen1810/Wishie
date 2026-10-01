//
//  WishlistFanView.swift
//  Wishie
//

import SwiftUI

/// Sizing and angle rules for the fanned sample wishlists on the auth screen.
/// Kept free of view state so the rules can be unit tested.
enum WishlistFanLayout {
    enum Side {
        case left
        case right
    }

    /// The fan is drawn at this card width, then scaled as one unit to fit its container.
    static let designCardWidth: CGFloat = 220
    /// Height of the whole fan (front card plus the rotated back cards) at `designCardWidth`.
    static let designFanHeight: CGFloat = 280

    static let cardWidthRatio: CGFloat = 0.56
    static let maxCardWidth: CGFloat = 240
    static let restAngle: Double = 14
    static let swayAngle: Double = 17

    static func cardWidth(for container: CGSize) -> CGFloat {
        let byWidth = container.width * cardWidthRatio
        let byHeight = designCardWidth * container.height / designFanHeight
        return max(0, min(byWidth, byHeight, maxCardWidth))
    }

    static func scale(for container: CGSize) -> CGFloat {
        cardWidth(for: container) / designCardWidth
    }

    static func angle(for side: Side, swayed: Bool) -> Double {
        let magnitude = swayed ? swayAngle : restAngle
        return side == .left ? -magnitude : magnitude
    }

    static func shouldStartSway(reduceMotion: Bool, alreadySwaying: Bool) -> Bool {
        !reduceMotion && !alreadySwaying
    }
}

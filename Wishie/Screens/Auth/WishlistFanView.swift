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

// MARK: - Sample data

private struct SampleWishlist {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let reserved: Bool
    }

    let title: String
    let subtitle: String
    let theme: GradientTheme
    let items: [Item]

    static let front = SampleWishlist(
        title: "Birthday 2026",
        subtitle: "12 items · 3 reserved",
        theme: .coral,
        items: [
            Item(name: "AirPods Pro", reserved: true),
            Item(name: "Lego Orchid", reserved: false),
            Item(name: "Film camera", reserved: false),
            Item(name: "Running shoes", reserved: true),
        ]
    )

    static let backLeft = SampleWishlist(
        title: "Housewarming",
        subtitle: "8 items",
        theme: .mint,
        items: [
            Item(name: "Moka pot", reserved: false),
            Item(name: "Desk lamp", reserved: false),
            Item(name: "Linen set", reserved: false),
        ]
    )

    static let backRight = SampleWishlist(
        title: "Tết wishlist",
        subtitle: "5 items",
        theme: .grape,
        items: [
            Item(name: "Kindle", reserved: false),
            Item(name: "Tea set", reserved: false),
            Item(name: "Sketchbook", reserved: false),
        ]
    )
}

// MARK: - Card

/// One sample wishlist, styled after `HomeItemViewCell` so it previews what Home looks like.
private struct SampleWishlistCard: View {
    let wishlist: SampleWishlist

    private var tint: Color {
        Color(hex: wishlist.theme.primary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(wishlist.title)
                .font(.wishiesDisplay(.bold, 18))
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(wishlist.subtitle)
                .font(.wishies(.medium, 12))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
            ForEach(wishlist.items) { item in
                row(for: item)
            }
        }
        .padding(14)
        .frame(width: WishlistFanLayout.designCardWidth, alignment: .leading)
        .background {
            tint
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 90, height: 90)
                        .offset(x: 30, y: -30)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .offset(x: -14, y: 14)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: tint.opacity(0.45), radius: 12, x: 0, y: 6)
    }

    private func row(for item: SampleWishlist.Item) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 7)
                .fill(tint.lightened(by: 0.6))
                .frame(width: 24, height: 24)
            Text(item.name)
                .font(.wishies(.bold, 13))
                .foregroundStyle(Color("obInk"))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            if item.reserved {
                Text("Reserved")
                    .font(.wishies(.bold, 10))
                    .foregroundStyle(Color.lightYellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color("obInk")))
                    .fixedSize()
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
    }
}

// MARK: - Fan

/// Three sample wishlists fanned out, the two at the back swaying gently.
/// Decorative: hidden from VoiceOver and unaffected by Dynamic Type.
struct WishlistFanView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var swayed = false

    /// Below each back card's bottom edge, so the cards fan out sideways instead of spinning in place.
    private let fanAnchor = UnitPoint(x: 0.5, y: 1.2)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                SampleWishlistCard(wishlist: .backLeft)
                    .offset(y: 14)
                    .rotationEffect(
                        .degrees(WishlistFanLayout.angle(for: .left, swayed: swayed)),
                        anchor: fanAnchor
                    )
                SampleWishlistCard(wishlist: .backRight)
                    .offset(y: 14)
                    .rotationEffect(
                        .degrees(WishlistFanLayout.angle(for: .right, swayed: swayed)),
                        anchor: fanAnchor
                    )
                SampleWishlistCard(wishlist: .front)
            }
            .scaleEffect(WishlistFanLayout.scale(for: geo.size))
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .dynamicTypeSize(.large)
        .accessibilityHidden(true)
        .onAppear {
            guard WishlistFanLayout.shouldStartSway(reduceMotion: reduceMotion, alreadySwaying: swayed) else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                swayed = true
            }
        }
    }
}

#Preview {
    WishlistFanView()
        .padding()
        .background(Color.lightYellow)
}

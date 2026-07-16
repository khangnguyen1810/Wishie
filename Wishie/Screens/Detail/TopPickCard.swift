//
//  TopPickCard.swift
//  Wishie
//

import SwiftUI
import DotLottie
import SDWebImageSwiftUI

/// The "Most Desired" highlight card.
///
/// Mirrors the three looping animations from the design:
///   topPickFloat  3.2s  rotate(-1deg) translateY(0 -> -6px)
///   topPickGlow   3.2s  box-shadow 0 12px 26px rgba(230,170,50,.35) -> 0 14px 34px rgba(230,170,50,.55)
///   topPickBadge  1.8s  rotate(6deg) scale(1 -> 1.08)
///
/// Standalone and `Equatable` on purpose: the parent rebuilds on every scroll frame
/// (StickyHeaderView republishes its scroll offset) and on every Firestore update, and a
/// `repeatForever` animation resets its phase each time the view it is attached to is rebuilt.
struct TopPickCard: View, Equatable {
    let item: WishlistItem
    let onTap: () -> Void

    @State private var isFloating = false
    @State private var isGlowing = false
    @State private var isBadgePulsing = false

    private static let glow = Color(red: 230 / 255, green: 170 / 255, blue: 50 / 255)

    static func == (lhs: TopPickCard, rhs: TopPickCard) -> Bool {
        lhs.item == rhs.item
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            card
            badge
                .offset(x: -14, y: -12)
        }
        // The -1deg tilt belongs on the wrapper, not the card: in the design the badge sits
        // *inside* the rotated container, so it inherits the tilt and stays glued to the card.
        // Its own 6deg rotation stacks on top of this.
        .rotationEffect(.degrees(-1))
        .padding(.top, 12)          // room for the badge's -12px overhang
        .offset(y: isFloating ? -6 : 5)
        .animation(
            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear {
            isFloating = true
            isGlowing = true
            isBadgePulsing = true
        }
        .onTapGesture(perform: onTap)
    }

    private var card: some View {
        HStack(spacing: 14) {
            thumbnail
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .font(.wishies(.bold, 16.5))
                    .foregroundStyle(Color(hex: "#6B4A0E"))
                    .lineLimit(1)
                if let price = item.price, !price.isEmpty {
                    Text(price)
                        .font(.wishies(.bold, 12.5))
                        .foregroundStyle(Color(hex: "#7A5A1E"))
                        .padding(.top, 3)
                }
                HStack(spacing: 5) {
                    Text("💛")
                        .font(.system(size: 11))
                    Text("Wanted most")
                        .font(.wishies(.bold, 11))
                        .foregroundStyle(Color(hex: "#6B4A0E"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.55)))
                .padding(.top, 8)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FFD66B"), Color(hex: "#F3B23A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: Self.glow.opacity(isGlowing ? 0.55 : 0.35),
                    radius: isGlowing ? 17 : 13,
                    x: 0,
                    y: isGlowing ? 14 : 12
                )
        )
        .animation(
            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
            value: isGlowing
        )
    }

    private var thumbnail: some View {
        // Keyed on the image URL and `.equatable()` on purpose: the card's `body` re-evaluates
        // on every Firestore update that touches an unrelated field (isPicked, price, …), which
        // would otherwise reconcile the `WebImage` and flash the loading placeholder over an
        // already-cached image. Isolating it here means the placeholder only appears while the
        // image is genuinely loading for the first time.
        TopPickThumbnail(imageURL: item.image)
            .equatable()
    }

    private var badge: some View {
        Text("TOP PICK")
            .font(.wishies(.bold, 11))
            .foregroundStyle(Color(hex: "#B8935A"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 7, x: 0, y: 6)
            )
            .scaleEffect(isBadgePulsing ? 1.08 : 1.0)
            .rotationEffect(.degrees(6))
            .animation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: isBadgePulsing
            )
    }
}

/// The card's thumbnail, isolated so it only re-renders when the image URL itself changes.
///
/// `Equatable` on the URL string keeps the `WebImage` (and its loading placeholder) stable across
/// the frequent rebuilds the parent card goes through on scroll and Firestore updates.
private struct TopPickThumbnail: View, Equatable {
    let imageURL: String?

    static func == (lhs: TopPickThumbnail, rhs: TopPickThumbnail) -> Bool {
        lhs.imageURL == rhs.imageURL
    }

    /// A non-empty, parseable URL — or `nil` when the item simply has no image.
    private var resolvedURL: URL? {
        guard let imageURL, !imageURL.isEmpty else { return nil }
        return URL(string: imageURL)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                )
            if let resolvedURL {
                WebImage(url: resolvedURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    // Only shown while the image is genuinely loading — items with no URL
                    // fall through to the static gift below instead of looping this forever.
                    DotLottieAnimation(
                        fileName: "giftloading",
                        config: AnimationConfig(autoplay: true, loop: true)
                    )
                    .view()
                    .frame(width: 32, height: 32)
                }
                .frame(width: 42, height: 42)
            } else {
                Text("🎁")
                    .font(.system(size: 30))
            }
        }
        .frame(width: 64, height: 64)
    }
}

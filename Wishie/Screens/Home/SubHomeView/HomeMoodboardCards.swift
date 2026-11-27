//
//  HomeMoodboardCards.swift
//  Wishie
//
//  The two wishlist cards of the Home "wish moodboard": a large featured card for the
//  nearest event and a compact row for every other wishlist.
//

import SwiftUI

private enum HomeCardDate {
    static let long: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM"
        return formatter
    }()
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter
    }()
}

// MARK: - Featured card

struct HomeFeaturedCard: View {
    let wishlist: WishlistModel
    let owner: UserModel
    let isOwnList: Bool
    let currentUserId: String?

    private var summary: HomeCardSummary { HomeCardSummary(wishlist: wishlist, currentUserId: currentUserId) }
    private var theme: GradientTheme { wishlist.theme }
    private var ink: Color { Color(hex: theme.ink) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            mosaic
                .frame(height: 236)
            footer
                .padding(EdgeInsets(top: 22, leading: 12, bottom: 10, trailing: 12))
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(hex: theme.primary))
        )
        // White reads better than the dark theme ink on the saturated theme colour.
        .foregroundStyle(Color.white)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var mosaic: some View {
        let others = summary.otherItems
        return GeometryReader { proxy in
            let spacing: CGFloat = 6
            let sideWidth = (proxy.size.width - spacing * 2) / 3
            HStack(spacing: spacing) {
                topTile
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                VStack(spacing: spacing) {
                    sideTile(others.first, extra: 0)
                    sideTile(others.dropFirst().first, extra: summary.extraCount)
                }
                .frame(width: sideWidth)
            }
        }
    }

    private var topTile: some View {
        let item = summary.topItem
        return ZStack {
            Color.white
            if let item, hasImage(item) {
                WishieProductImage(localImage: item.localImage, url: item.image, placeholderSize: 60)
            } else {
                Image(systemName: "gift")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(Color.obInk)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topLeading) {
            if summary.isTopItemMostDesired {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                    Text("Top wish")
                        .font(.wishies(.bold, 12))
                }
                .foregroundStyle(Color.obInk)
                .padding(.horizontal, 9)
                .frame(height: 24)
                .background(Capsule().fill(HomePalette.topWish))
                .padding(10)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let item {
                Text(topLabel(for: item))
                    .font(.wishies(.bold, 13))
                    .foregroundStyle(Color.obInk)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(hasImage(item) ? 0.92 : 0)))
                    .padding(.horizontal, 6)
                    .padding(.bottom, 8)
            }
        }
    }

    private func topLabel(for item: WishlistItem) -> String {
        guard !isOwnList else { return item.name }
        return "\(item.name) · \(item.isPicked ? "Picked" : "Available")"
    }

    private func sideTile(_ item: WishlistItem?, extra: Int) -> some View {
        ZStack {
            Color(hex: theme.tile)
            if let item, hasImage(item) {
                WishieProductImage(localImage: item.localImage, url: item.image, placeholderSize: 28)
                    .opacity(dimmed(item) ? 0.5 : 1)
            } else if item != nil {
                Image(systemName: "gift")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(Color.obInk.opacity(item.map(dimmed) == true ? 0.4 : 1))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            if let item, !isOwnList, summary.isPickedByMe(item) {
                HomeYoursTag().padding(6)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if extra > 0 {
                Text("+\(extra)")
                    .font(.wishies(.bold, 11))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(Capsule().fill(ink))
                    .padding(6)
            }
        }
    }

    /// On a friend's list, gifts someone else already picked step back.
    private func dimmed(_ item: WishlistItem) -> Bool {
        !isOwnList && item.isPicked && !summary.isPickedByMe(item)
    }

    private var footer: some View {
        let countdown = summary.countdown()
        return HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                if !isOwnList {
                    HomeOwnerLine(owner: owner, wishlist: wishlist, avatarSize: 24, fontSize: 13)
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                }
                Text(wishlist.name)
                    .font(.wishiesDisplay(.extraBold, 26))
                    .lineLimit(1)
                Text("\(HomeCardDate.long.string(from: wishlist.dueDate)) · \(summary.statusText(isOwnList: isOwnList))")
                    .font(.wishies(.bold, 14))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: -4) {
                Text(countdown.value)
                    .font(.wishiesDisplay(.extraBold, 30))
                if !countdown.caption.isEmpty {
                    Text(countdown.caption)
                        .font(.wishies(.bold, 13))
                }
            }
            .fixedSize()
        }
    }
}

// MARK: - Compact card

struct HomeCompactCard: View {
    let wishlist: WishlistModel
    let owner: UserModel
    let isOwnList: Bool
    let currentUserId: String?

    private var summary: HomeCardSummary { HomeCardSummary(wishlist: wishlist, currentUserId: currentUserId) }
    private var theme: GradientTheme { wishlist.theme }

    var body: some View {
        HStack(spacing: 12) {
            mosaic
            VStack(alignment: .leading, spacing: 2) {
                if !isOwnList {
                    HomeOwnerLine(owner: owner, wishlist: wishlist, avatarSize: 20, fontSize: 12)
                }
                Text(wishlist.name)
                    .font(.wishiesDisplay(.extraBold, 19))
                    .lineLimit(1)
                Text("\(HomeCardDate.short.string(from: wishlist.dueDate)) · \(summary.statusText(isOwnList: isOwnList))")
                    .font(.wishies(.bold, 13))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Text(summary.countdown().short)
                .font(.wishiesDisplay(.extraBold, 20))
                .fixedSize()
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 14))
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(hex: theme.soft))
        )
        .foregroundStyle(Color(hex: theme.ink))
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var mosaic: some View {
        let items = Array(([summary.topItem].compactMap { $0 } + summary.otherItems).prefix(4))
        let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                tile(index < items.count ? items[index] : nil)
            }
        }
        .frame(width: 76, height: 76)
    }

    private func tile(_ item: WishlistItem?) -> some View {
        ZStack {
            if let item {
                Color.white
                if hasImage(item) {
                    WishieProductImage(localImage: item.localImage, url: item.image, placeholderSize: 18)
                } else {
                    Image(systemName: "gift")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.obInk)
                }
            } else {
                Color(hex: theme.tile)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Shared pieces

/// "(M) Minh's wishlist": who the list belongs to, placed right before the list name.
struct HomeOwnerLine: View {
    let owner: UserModel
    let wishlist: WishlistModel
    let avatarSize: CGFloat
    let fontSize: CGFloat

    var body: some View {
        let name = HomeCardSummary.ownerFirstName(profile: owner, wishlist: wishlist)
        HStack(spacing: 7) {
            HomeOwnerAvatar(user: owner, fallbackName: name, size: avatarSize)
                .foregroundStyle(Color(hex: wishlist.theme.ink))
            Text(name.isEmpty ? "A friend's wishlist" : "\(name)'s wishlist")
                .font(.wishies(.bold, fontSize))
                .lineLimit(1)
        }
    }
}

struct HomeOwnerAvatar: View {
    let user: UserModel
    let fallbackName: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Color.white)
            if let url = user.avatarUrl, !url.isEmpty {
                // Frame before clipping: an aspect-filled photo otherwise spills past the circle.
                WishieWebImage(url: url, placeholderSize: size)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let initial = fallbackName.first {
                Text(String(initial).uppercased())
                    .font(.wishies(.bold, size * 0.5))
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
        .accessibilityHidden(true)
    }
}

/// Dark "✓ Yours" tag on a gift the current user picked.
struct HomeYoursTag: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .heavy))
            Text("Yours")
                .font(.wishies(.bold, 11))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 7)
        .frame(height: 22)
        .background(Capsule().fill(Color.obInk))
    }
}

private func hasImage(_ item: WishlistItem) -> Bool {
    item.localImage != nil || !(item.image ?? "").isEmpty
}

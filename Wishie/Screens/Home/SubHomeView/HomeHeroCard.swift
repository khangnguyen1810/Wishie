//
//  HomeHeroCard.swift
//  Wishie
//

import SwiftUI

struct HomeHeroCard: View {
    var wishlist: (WishlistModel, UserModel)
    var progress: CGFloat
    var selectedTab: HomeView.HomeTab
    var statusOwner: UserModel
    var homeAppeared: Bool
    var onCTATapped: () -> Void

    var body: some View {
        let p = min(max(progress, 0), 1)
        let days = daysUntil(wishlist.0.dueDate)
        let pickedCount = wishlist.0.items.filter { $0.isPicked }.count
        let remainingCount = wishlist.0.items.count - pickedCount
        let ownerFirstName = wishlist.1.firstName.isEmpty ? (wishlist.0.ownerName ?? "") : wishlist.1.firstName

        VStack(alignment: .leading, spacing: lerp(10, 4, p)) {
            if selectedTab == .friendsList {
                HStack(spacing: 6) {
                    HomeAvatarView(user: wishlist.1, size: 18)
                    Text("Xem sự kiện của \(ownerFirstName)")
                        .font(.wishiesDisplay(.bold, 12))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .opacity(1 - p)
                .frame(height: lerp(20, 0, p), alignment: .leading)
                .clipped()
            }
            Text("✨ SẮP ĐẾN RỒI")
                .font(.wishiesDisplay(.bold, 12))
                .foregroundStyle(Color.white.opacity(0.85))
                .opacity(1 - p)
                .frame(height: lerp(16, 0, p), alignment: .leading)
                .clipped()
            Text("\(wishlist.0.name) 🎂")
                .font(.wishiesDisplay(.extraBold, lerp(20, 15, p)))
                .foregroundStyle(Color.white)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(days == 0 ? "Hôm nay!" : "\(days)")
                    .font(.wishiesDisplay(.extraBold, lerp(36, 22, p)))
                    .foregroundStyle(Color.white)
                if days > 0 {
                    Text("ngày nữa")
                        .font(.wishiesDisplay(.bold, lerp(14, 11, p)))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
            }
            HStack(spacing: 8) {
                HomeAvatarView(user: statusOwner, size: 22)
                    .opacity(1 - p)
                    .frame(width: lerp(22, 0, p))
                Text(selectedTab == .myList
                     ? "\(pickedCount) món quà đã chọn"
                     : "\(ownerFirstName) đang mong ước \(remainingCount) món quà")
                    .font(.wishiesDisplay(.bold, 13))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .opacity(1 - p)
                    .lineLimit(1)
                Spacer(minLength: 0)
                ctaButton(progress: p)
            }
        }
        .padding(lerp(18, 12, p))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "#B79CF2").opacity(0.82))
            }
            .shadow(color: Color(hex: "#B79CF2").opacity(0.35), radius: 10, x: 0, y: 5)
        )
        .opacity(homeAppeared ? 1 : 0)
        .offset(y: homeAppeared ? 0 : 26)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.24), value: homeAppeared)
    }

    @ViewBuilder
    private func ctaButton(progress: CGFloat) -> some View {
        Button(action: onCTATapped) {
            Text(selectedTab == .myList ? "🎁 Xem quà" : "🎁 Chọn quà tặng")
                .font(.wishiesDisplay(.bold, lerp(13, 11, progress)))
                .foregroundStyle(Color(hex: "#B79CF2"))
                .padding(.horizontal, lerp(14, 10, progress))
                .padding(.vertical, lerp(8, 6, progress))
                .background(Capsule().fill(Color.white))
        }
    }

    private func daysUntil(_ date: Date) -> Int {
        max(0, Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: date)
        ).day ?? 0)
    }

    private func lerp(_ from: CGFloat, _ to: CGFloat, _ t: CGFloat) -> CGFloat {
        from + (to - from) * t
    }
}

struct HomeAvatarView: View {
    var user: UserModel
    var size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.35))
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            if let avatarUrl = user.avatarUrl, !avatarUrl.isEmpty {
                WishieWebImage(url: avatarUrl)
                    .frame(width: size - 4, height: size - 4)
                    .clipShape(Circle())
            } else {
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.5, height: size * 0.5)
            }
        }
    }
}

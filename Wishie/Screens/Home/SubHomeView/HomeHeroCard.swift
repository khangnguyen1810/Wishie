//
//  HomeHeroCard.swift
//  Wishie
//

import SwiftUI

struct HomeHeroCard: View {
    var wishlist: (WishlistModel, UserModel)
    var progress: CGFloat
    @Binding var path: NavigationPath
    var animation: Namespace.ID
    var selectedTab: HomeView.HomeTab
    var statusOwner: UserModel
    var homeAppeared: Bool

    private static let dueDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM, yy"
        return formatter
    }()

    var body: some View {
        let p = min(max(progress, 0), 1)
        let days = daysUntil(wishlist.0.dueDate)
        let pickedCount = wishlist.0.items.filter { $0.isPicked }.count
        let remainingCount = wishlist.0.items.count - pickedCount
        let ownerFirstName = wishlist.1.firstName.isEmpty ? (wishlist.0.ownerName ?? "") : wishlist.1.firstName

        VStack(alignment: .leading, spacing: lerp(10, 4, p)) {
            HStack(alignment: .firstTextBaseline) {
                Text("COMING SOON")
                    .font(.wishiesDisplay(.bold, 12))
                    .foregroundStyle(Color(hex: "#F4667A"))
                Spacer(minLength: 8)
                Text(Self.dueDateFormatter.string(from: wishlist.0.dueDate))
                    .font(.wishies(.medium, 12))
                    .foregroundStyle(Color(hex: "#9A7A3E"))
            }
            .opacity(1 - p)
            .frame(height: lerp(16, 0, p), alignment: .leading)
            .clipped()

            if selectedTab == .friendsList {
                HStack(spacing: 6) {
                    HomeAvatarView(user: wishlist.1, size: 18)
                    Text("\(ownerFirstName)'s event")
                        .font(.wishiesDisplay(.bold, 12))
                        .foregroundStyle(Color(hex: "#9A7A3E"))
                }
                .opacity(1 - p)
                .frame(height: lerp(20, 0, p), alignment: .leading)
                .clipped()
            }

            HStack(alignment: .top, spacing: 6) {
                Text(wishlist.0.name)
                    .font(.wishiesDisplay(.extraBold, lerp(20, 15, p)))
                    .foregroundStyle(Color(hex: "#3E2A0F"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: -12) {
                    Text(days == 0 ? "Today!" : "\(days)")
                        .font(.wishiesDisplay(.extraBold, lerp(30, 20, p)))
                        .foregroundStyle(Color(hex: "#F4667A"))
                    if days > 0 {
                        Text("days left")
                            .font(.wishiesDisplay(.bold, lerp(12, 10, p)))
                            .foregroundStyle(Color(hex: "#9A7A3E"))
                    }
                }
            }

            Divider()
                .background(Color(hex: "#E9D8AC"))
                .opacity(1 - p)
                .frame(height: lerp(1, 0, p))
                .clipped()

            HStack(spacing: 8) {
                HomeAvatarView(user: statusOwner, size: 22)
                    .opacity(1 - p)
                    .frame(width: lerp(22, 0, p))
                Text(selectedTab == .myList
                     ? "\(pickedCount) gifts picked"
                     : "\(ownerFirstName) wishes for \(remainingCount) gifts")
                    .font(.wishiesDisplay(.bold, 13))
                    .foregroundStyle(Color(hex: "#9A7A3E"))
                    .opacity(1 - p)
                    .lineLimit(1)
                Spacer(minLength: 0)
                ctaButton(progress: p)
            }
        }
        .padding(lerp(18, 12, p))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color(hex: "#E9D8AC"), lineWidth: 2)
                )
                .shadow(color: Color(hex: "#B48C3C").opacity(0.25), radius: 12, x: 0, y: 6)
        )
        .opacity(homeAppeared ? 1 : 0)
        .offset(y: homeAppeared ? 0 : 26)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.24), value: homeAppeared)
    }

    @ViewBuilder
    private func ctaButton(progress: CGFloat) -> some View {
        NavigationLink {
            WishlistDetailView(
                navigationPath: $path,
                wishlist: wishlist.0,
                owner: wishlist.1
            )
            .navigationTransition(.zoom(sourceID: wishlist.0.id, in: animation))
        } label: {
            Text(selectedTab == .myList ? "View gifts" : "Pick a gift")
                .font(.wishiesDisplay(.bold, lerp(13, 11, progress)))
                .foregroundStyle(Color.white)
                .padding(.horizontal, lerp(14, 10, progress))
                .padding(.vertical, lerp(8, 6, progress))
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
                .shadow(color: Color(hex: "#F4667A").opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .matchedTransitionSource(id: wishlist.0.id, in: animation)
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
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            if let avatarUrl = user.avatarUrl, !avatarUrl.isEmpty {
                WishieWebImage(url: avatarUrl)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if !user.firstName.isEmpty {
                Text(user.firstName.prefix(1).uppercased())
                    .font(.wishiesDisplay(.bold, size * 0.5))
                    .foregroundStyle(Color.white)
            } else {
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.5, height: size * 0.5)
            }
        }
    }
}

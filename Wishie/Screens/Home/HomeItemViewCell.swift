import SwiftUI

struct HomeItemViewCell: View {
    var item: (WishlistModel, UserModel)

    private var itemPicked: [WishlistItem] {
        item.0.items.filter { $0.isPicked }
    }

    private var progress: Double {
        item.0.items.count > 0 ? Double(itemPicked.count) / Double(item.0.items.count) : 0.0
    }

    private var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: item.0.dueDate)
        return max(-1, calendar.dateComponents([.day], from: today, to: due).day ?? 0)
    }

    private var isUrgent: Bool {
        daysRemaining <= 7 && daysRemaining >= 0
    }

    private var isOverDue: Bool {
        daysRemaining < 0
    }

    private var avatarView: some View {
        Group {
            if let avatarUrl = item.1.avatarUrl, !avatarUrl.isEmpty {
                WishieWebImage(url: avatarUrl)
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
            } else {
                Image("user")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 21)
            }
        }
    }

    var body: some View {
        ZStack {
            themeBackground
            decorativeOverlay
            contentLayer
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color(hex: item.0.theme.secondary).opacity(0.45), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private var themeBackground: some View {
        LinearGradient(
            colors: [
                Color(hex: item.0.theme.primary),
                Color(hex: item.0.theme.secondary)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var decorativeOverlay: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 120, height: 120)
                .offset(x: geo.size.width - 55, y: -55)
            Circle()
                .fill(Color.white.opacity(0.09))
                .frame(width: 72, height: 72)
                .offset(x: geo.size.width - 85, y: 32)
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 48, height: 48)
                .offset(x: -18, y: geo.size.height - 18)
        }
        .clipped()
    }

    @ViewBuilder
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            if !item.0.description.isEmpty {
                Text(item.0.description)
                    .font(.wishies(.italic, 13))
                    .foregroundStyle(Color.black.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            footerRow
        }
        .padding(16)
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.0.name)
                    .foregroundStyle(Color.black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.wishies(.bold, 18))
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.wishiePink)
                    Text(item.0.dueDate.toShortDateString())
                        .font(.wishies(.regular, 11))
                        .foregroundStyle(Color.black.opacity(0.65))
                }
            }
            Spacer()
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(Color.white.opacity(0.9), lineWidth: 1.5))
                    avatarView
                }
                Text(item.1.firstName.isEmpty ? "—" : item.1.firstName)
                    .font(.wishies(.regular, 10))
                    .foregroundStyle(Color.black.opacity(0.6))
                    .lineLimit(1)
                    .frame(maxWidth: 48)
            }
        }
    }

    @ViewBuilder
    private var footerRow: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.wishiePink)
                Text(item.0.items.count > 0 ? "\(itemPicked.count)/\(item.0.items.count) gifts" : "No gifts yet")
                    .font(.wishies(.regular, 12))
                    .foregroundStyle(Color.black.opacity(0.75))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.5)))

            HStack(spacing: 4) {
                Image(systemName: daysRemaining == 0 ? "star.fill" : "clock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(isUrgent ? Color.wishiePink : Color.black.opacity(0.5))
                Text(daysRemaining == -1 ? "Overdue": (daysRemaining == 0 ? "Today!" : "\(daysRemaining)d left"))
                    .font(.wishies(.bold, 11))
                    .foregroundStyle(isUrgent ? Color.wishiePink : (isOverDue ? Color.lightGrey : Color.black.opacity(0.65)))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.5)))

            Spacer()

            GiftProgressView(progress: progress)
                .frame(width: 48, height: 48)
        }
    }
}

#Preview {
    let item1 = WishlistItem(id: "1", name: "Leather journal", isPicked: true)
    let item2 = WishlistItem(id: "2", name: "Gold earrings")
    let item3 = WishlistItem(id: "3", name: "Scented candle set")
    let wishListModel = WishlistModel(
        id: "1",
        name: "Birthday Celebrations",
        description: "Things I'd love to receive for my special day!",
        dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date(),
        items: [item1, item2, item3],
        themeColor: "sunset",
        userCreateId: "1",
        members: [:]
    )
    let userModel = UserModel()
    HomeItemViewCell(item: (wishListModel, userModel))
        .padding()
}

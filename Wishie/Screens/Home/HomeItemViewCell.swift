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
        .overlay(alignment: .topTrailing) {
            statusBadge
                .offset(x: -14, y: -14)
        }
        .padding(.horizontal, 15)
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
    private var statusBadge: some View {
        if daysRemaining == 0 {
            badgeLabel(
                text: "🎉 TODAY",
                background: Color(hex: "#FFE9A8"),
                foreground: Color(hex: "#8C5A17"),
                rotation: 8,
                hasBorder: true
            )
        } else if isOverDue {
            badgeLabel(
                text: "⏰ OVERDUE",
                background: .white,
                foreground: Color(hex: "#B85C3E"),
                rotation: -6,
                hasBorder: false
            )
        } else {
            badgeLabel(
                text: "\(daysRemaining)d left",
                background: .white,
                foreground: isUrgent ? Color.wishiePink : Color(hex: item.0.theme.secondary),
                rotation: 6,
                hasBorder: false
            )
        }
    }

    @ViewBuilder
    private func badgeLabel(text: String, background: Color, foreground: Color, rotation: Double, hasBorder: Bool) -> some View {
        Text(text)
            .font(.wishiesDisplay(.extraBold, 12))
            .foregroundStyle(foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(background)
                    .overlay(
                        Capsule().stroke(Color.white, lineWidth: hasBorder ? 2 : 0)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
            .rotationEffect(.degrees(rotation))
    }

    @ViewBuilder
    private var contentLayer: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            if !item.0.description.isEmpty {
                Text(item.0.description)
                    .font(.wishies(.italic, 13))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            footerRow
        }
        .padding(16)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.0.name)
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.wishiesDisplay(.extraBold, 19))
                HStack(spacing: 4) {
                    Text("📅")
                        .font(.system(size: 11))
                    Text(item.0.dueDate.toShortDateString())
                        .font(.wishiesDisplay(.semiBold, 13))
                        .foregroundStyle(Color.white.opacity(0.9))
                }
            }
            Spacer()
            VStack(spacing: 3) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    avatarView
                }
                Text(item.1.firstName.isEmpty ? "—" : item.1.firstName)
                    .font(.wishiesDisplay(.bold, 10))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .frame(maxWidth: 48)
            }
        }
    }

    @ViewBuilder
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.3))
            GeometryReader { geo in
                Capsule()
                    .fill(Color.white)
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 10)
    }

    @ViewBuilder
    private var footerRow: some View {
        HStack(alignment: .center, spacing: 10) {
            progressBar
            HStack(spacing: 5) {
                Text("🎁")
                    .font(.system(size: 11))
                Text(item.0.items.count > 0 ? "\(itemPicked.count)/\(item.0.items.count)" : "No gifts yet")
                    .font(.wishiesDisplay(.extraBold, 12))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.28)))
            .fixedSize()
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

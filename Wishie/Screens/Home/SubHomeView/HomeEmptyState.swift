//
//  HomeEmptyState.swift
//  Wishie
//

import SwiftUI

/// Empty Home tab: a placeholder card in the shape of a real one, then the call to action.
struct HomeEmptyState: View {
    var selectedTab: HomeView.HomeTab
    var action: () -> Void
    var onRefresh: () async -> Void

    private var isMyList: Bool { selectedTab == .myList }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Button(action: action) { placeholderCard }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isMyList ? "Create your first wish" : "Scan a friend's QR code")

                VStack(spacing: 8) {
                    Text(isMyList ? "Start your first wishlist" : "Your friends' wishes land here")
                        .font(.wishiesDisplay(.extraBold, 24))
                        .foregroundStyle(Color.obInk)
                    Text(isMyList
                         ? "Add a few things you'd love, pick the date, then share the QR so friends know what to get you."
                         : "Scan a friend's Wishie QR code to see what they're hoping for, then quietly pick a gift.")
                        .font(.wishies(.regular, 15))
                        .foregroundStyle(HomePalette.bodyText)
                        .lineSpacing(4)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.top, 28)

                WishieButton(
                    title: isMyList ? "Create wishlist" : "Scan a friend's QR",
                    enabled: true,
                    filColor: .obInk,
                    titleColor: .obScreenBg,
                    height: 54,
                    systemImage: isMyList ? "plus" : "qrcode",
                    cornerRadius: 27,
                    font: .wishies(.bold, 16),
                    action: action
                )
                .padding(.horizontal, 12)
                .padding(.top, 20)

                if !isMyList {
                    Text("Already joined one? Pull down to refresh.")
                        .font(.wishies(.regular, 14))
                        .foregroundStyle(HomePalette.mutedText)
                        .padding(.top, 14)
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .refreshable { await onRefresh() }
    }

    private var placeholderCard: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                HStack(spacing: 6) {
                    primaryTile
                    VStack(spacing: 6) {
                        paleTile {
                            Image(systemName: "gift")
                                .font(.system(size: 24, weight: .light))
                                .foregroundStyle(HomePalette.placeholderIcon)
                        }
                        paleTile { EmptyView() }
                    }
                    .frame(width: (proxy.size.width - 12) / 3)
                }
            }
            .frame(height: 236)

            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    if !isMyList {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                                .overlay {
                                    Image(systemName: "person")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(HomePalette.placeholderIcon)
                                }
                            bar(HomePalette.barSoft, height: 12, fraction: 0.3)
                        }
                    }
                    bar(HomePalette.barStrong, height: 18, fraction: 0.58)
                    bar(HomePalette.barSoft, height: 12, fraction: isMyList ? 0.4 : 0.44)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                RoundedRectangle(cornerRadius: 10)
                    .fill(HomePalette.barSoft)
                    .frame(width: 44, height: 40)
            }
            .padding(EdgeInsets(top: 14, leading: 12, bottom: 10, trailing: 12))
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(HomePalette.track))
        .accessibilityElement(children: .ignore)
    }

    private var primaryTile: some View {
        VStack(spacing: 10) {
            Group {
                if isMyList {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(HomePalette.accent))
                } else {
                    Image(systemName: "qrcode")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.obScreenBg)
                        .frame(width: 56, height: 56)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.obInk))
                }
            }
            Text(isMyList ? "Your first wish" : "A friend's wishes")
                .font(.wishies(.bold, 15))
                .foregroundStyle(Color.obInk)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
    }

    private func paleTile<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(HomePalette.emptyTile)
            .overlay { content() }
    }

    private func bar(_ color: Color, height: CGFloat, fraction: CGFloat) -> some View {
        GeometryReader { proxy in
            Capsule()
                .fill(color)
                .frame(width: proxy.size.width * fraction)
        }
        .frame(height: height)
    }
}

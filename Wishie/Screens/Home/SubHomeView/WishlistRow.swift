//
//  WishlistRow.swift
//  Wishie
//

import SwiftUI

struct WishlistRow<Menu: View>: View {
    var wishlist: (WishlistModel, UserModel)
    var index: Int
    var animation: Namespace.ID
    @Binding var path: NavigationPath
    var homeAppeared: Bool
    var contextMenu: () -> Menu

    init(
        wishlist: (WishlistModel, UserModel),
        index: Int,
        animation: Namespace.ID,
        path: Binding<NavigationPath>,
        homeAppeared: Bool,
        @ViewBuilder contextMenu: @escaping () -> Menu
    ) {
        self.wishlist = wishlist
        self.index = index
        self.animation = animation
        self._path = path
        self.homeAppeared = homeAppeared
        self.contextMenu = contextMenu
    }

    var body: some View {
        NavigationLink {
            WishlistDetailView(
                navigationPath: $path,
                wishlist: wishlist.0,
                owner: wishlist.1
            )
            .navigationTransition(.zoom(sourceID: wishlist.0.id, in: animation))
        } label: {
            HomeItemViewCell(item: wishlist)
                .rotationEffect(.degrees(index % 2 == 0 ? -1 : 1.5))
                .padding(.top, index == 0 ? 15 : 0)
                .padding(.bottom, 10)
        }
        .buttonStyle(.plain)
        .padding(.vertical, 14)
        .opacity(homeAppeared ? 1 : 0)
        .offset(y: homeAppeared ? 0 : 26)
        .animation(
            .timingCurve(0.22, 1, 0.36, 1, duration: 0.5)
                .delay(0.36 + Double(min(index, 6)) * 0.08),
            value: homeAppeared
        )
        .matchedTransitionSource(id: wishlist.0.id, in: animation)
        .contextMenu { contextMenu() }
    }
}

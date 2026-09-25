//
//  HomeEmptyState.swift
//  Wishie
//

import SwiftUI

struct HomeEmptyState: View {
    var msg: String
    var buttonTitle: String
    var selectedTab: HomeView.HomeTab
    var action: () -> Void
    var onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                Image("gift_img")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
            }
            VStack(spacing: 8) {
                Text(selectedTab == .myList ? "Your wishlist is waiting..." : "No events joined yet")
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)
                Text(msg)
                    .font(.wishies(.regular, 14))
                    .foregroundStyle(Color.darkGrey)
                    .multilineTextAlignment(.center)
            }
            WishieButton(
                title: buttonTitle,
                enabled: true,
                filColor: Color(hex: "#FF9A76"),
                width: 220,
                height: 48,
                action: action
            )
            Button(action: onRefresh) {
                Text("Refresh")
                    .font(.wishies(.regular, 14))
                    .foregroundStyle(Color.wishiePink)
            }
        }
        .padding(40)
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

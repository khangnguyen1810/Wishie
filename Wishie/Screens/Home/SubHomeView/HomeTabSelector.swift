//
//  HomeTabSelector.swift
//  Wishie
//

import SwiftUI

struct HomeTabSelector: View {
    @Binding var selectedTab: HomeView.HomeTab
    var animation: Namespace.ID

    var body: some View {
        HStack(spacing: 0) {
            tabItem(title: "My list", tab: .myList)
            tabItem(title: "Friend's list", tab: .friendsList)
        }
        .frame(height: 44)
        .padding(5)
        .background {
            Capsule()
                .fill(Color.white)
                .overlay(
                    Capsule().stroke(Color(hex: "#E9D8AC"), lineWidth: 1)
                )
                .shadow(color: Color(hex: "#B48C3C").opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeTabSelector": $0] }
    }

    @ViewBuilder
    private func tabItem(title: String, tab: HomeView.HomeTab) -> some View {
        ZStack {
            if selectedTab == tab {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color(hex: "#F4667A").opacity(0.3), radius: 8, x: 0, y: 3)
                    .matchedGeometryEffect(id: "TAB", in: animation)
            }
            Text(title)
                .font(.wishiesDisplay(.bold, 15))
                .foregroundStyle(selectedTab == tab ? .white : Color(hex: "#A5875A"))
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
        }
        .onTapGesture { selectedTab = tab }
    }
}

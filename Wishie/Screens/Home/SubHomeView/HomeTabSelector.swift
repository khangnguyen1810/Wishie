//
//  HomeTabSelector.swift
//  Wishie
//

import SwiftUI

struct HomeTabSelector: View {
    @Binding var selectedTab: HomeView.HomeTab
    var animation: Namespace.ID

    var body: some View {
        HStack(spacing: 4) {
            tabItem(title: "My list", tab: .myList)
            tabItem(title: "Friend's list", tab: .friendsList)
        }
        .padding(4)
        .frame(height: 50)
        .background(Capsule().fill(HomePalette.track))
        .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeTabSelector": $0] }
    }

    @ViewBuilder
    private func tabItem(title: String, tab: HomeView.HomeTab) -> some View {
        let isSelected = selectedTab == tab
        Button {
            selectedTab = tab
        } label: {
            Text(title)
                .font(.wishies(.bold, 16))
                .foregroundStyle(isSelected ? Color.obInk : HomePalette.bodyText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.white)
                            .shadow(color: Color.obInk.opacity(0.12), radius: 1.5, x: 0, y: 1)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

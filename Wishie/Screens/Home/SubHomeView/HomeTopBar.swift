//
//  HomeTopBar.swift
//  Wishie
//

import SwiftUI

struct HomeTopBar: View {
    var firstName: String
    var homeAppeared: Bool
    var onAddTapped: () -> Void
    var onProfileTapped: () -> Void

    var body: some View {
        TopAppBar {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(firstName.isEmpty ? "Hey there!" : "Hey, \(firstName)!")
                        .font(.wishiesDisplay(.extraBold, 28))
                        .foregroundColor(Color(hex: "#5B3F0F"))
                }
                .opacity(homeAppeared ? 1 : 0)
                .offset(y: homeAppeared ? 0 : 26)
                .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.05), value: homeAppeared)
                Text("Your celebrations await ✨")
                    .font(.wishies(.medium, 13))
                    .foregroundStyle(Color(hex: "#9A7A3E"))
                    .opacity(homeAppeared ? 1 : 0)
                    .offset(y: homeAppeared ? 0 : 26)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.12), value: homeAppeared)
            }
        } trailing: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color(hex: "#F4667A").opacity(0.35), radius: 8, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                .rotationEffect(.degrees(6))
                .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeAddButton": $0] }
                .onTapGesture(perform: onAddTapped)
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().stroke(
                                LinearGradient(
                                    colors: [Color(hex: "#FF9A76"), Color(hex: "#F4667A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                        )
                    Image("user")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .onTapGesture(perform: onProfileTapped)
            }
            .padding(.trailing, 4)
        }
    }
}

//
//  HomeTopBar.swift
//  Wishie
//

import SwiftUI

struct HomeTopBar: View {
    var firstName: String
    var subtitle: String
    var homeAppeared: Bool
    var onAddTapped: () -> Void
    var onProfileTapped: () -> Void
    var avatarUrl: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text(firstName.isEmpty ? "Hey there!" : "Hey, \(firstName)!")
                    .font(.wishiesDisplay(.extraBold, 32))
                    .foregroundStyle(Color.obInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(homeAppeared ? 1 : 0)
                    .offset(y: homeAppeared ? 0 : 26)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.05), value: homeAppeared)
                Text(subtitle)
                    .font(.wishies(.bold, 15))
                    .foregroundStyle(HomePalette.mutedText)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: subtitle)
                    .opacity(homeAppeared ? 1 : 0)
                    .offset(y: homeAppeared ? 0 : 26)
                    .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5).delay(0.12), value: homeAppeared)
            }
            Spacer(minLength: 12)
            HStack(spacing: 10) {
                Button(action: onAddTapped) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(width: 48, height: 48)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(HomePalette.accent))
                }
                .accessibilityLabel("Add or join a wishlist")
                .anchorPreference(key: CoachMarkBoundsKey.self, value: .bounds) { ["homeAddButton": $0] }

                Button(action: onProfileTapped) {
                    ZStack {
                        Circle().fill(HomePalette.avatarFill)
                        if !avatarUrl.isEmpty {
                            WishieWebImage(url: avatarUrl, placeholderSize: 44)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } else if let initial = firstName.first {
                            Text(String(initial).uppercased())
                                .font(.wishies(.bold, 18))
                                .foregroundStyle(Color.obInk)
                        } else {
                            Image(systemName: "person.fill")
                                .foregroundStyle(Color.obInk)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .padding(2)
                    .overlay(Circle().stroke(HomePalette.accent, lineWidth: 2))
                }
                .accessibilityLabel("Profile")
            }
        }
        .padding(.horizontal, 10)
    }
}

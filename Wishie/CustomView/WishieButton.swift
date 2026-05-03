//
//  WishieButton.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 30/12/25.
//


import SwiftUI

struct WishieButton: View {
    let title: String
    let enabled: Bool
    let fillColor: Color
    let titleColor: Color
    let width: CGFloat?
    let height: CGFloat?
    let verticalPadding: CGFloat?
    let horizontalPadding: CGFloat?
    let action: () -> Void
    init(title: String,
         enabled: Bool,
         filColor: Color = Color.lightYellow,
         titleColor: Color = .black,
         width: CGFloat = .infinity ,
         height: CGFloat = 60,
         verticalPadding: CGFloat? = 0,
         horizontalPadding: CGFloat? = 0,
         action: @escaping () -> Void
    ) {
        self.title = title
        self.enabled = enabled
        self.fillColor = filColor
        self.titleColor =  titleColor
        self.width = width
        self.height = height
        self.verticalPadding = verticalPadding
        self.horizontalPadding = horizontalPadding
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(enabled ? fillColor : fillColor.opacity(0.5))
                    .frame(height: height)
                    .frame(maxWidth: width )
                Text(title)
                    .font(.wishies(.bold, 20))
                    .foregroundStyle(
                        enabled ? titleColor : titleColor.opacity(0.5)
                    )
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .disabled(!enabled)
    }
}

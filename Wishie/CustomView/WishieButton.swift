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
    let systemImage: String?
    let cornerRadius: CGFloat
    let font: Font
    let action: () -> Void
    init(title: String,
         enabled: Bool,
         filColor: Color = Color.lightYellow,
         titleColor: Color = .black,
         width: CGFloat = .infinity ,
         height: CGFloat = 60,
         verticalPadding: CGFloat? = 0,
         horizontalPadding: CGFloat? = 0,
         systemImage: String? = nil,
         cornerRadius: CGFloat = 20,
         font: Font = .wishies(.bold, 20),
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
        self.systemImage = systemImage
        self.cornerRadius = cornerRadius
        self.font = font
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(enabled ? fillColor : fillColor.opacity(0.5))
                    .frame(height: height)
                    .frame(maxWidth: width )
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .bold))
                    }
                    Text(title)
                        .font(font)
                }
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

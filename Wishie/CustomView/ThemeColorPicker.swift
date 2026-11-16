//
//  ThemeColorPicker.swift
//  Wishie
//

import SwiftUI

struct ThemeColorPicker: View {
    @Binding var selectedTheme: GradientTheme?

    var body: some View {
        HStack(spacing: 15) {
            ForEach(GradientTheme.allCases, id: \.self) { theme in
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: theme.primary), Color(hex: theme.secondary)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: .gray.opacity(0.3), radius: 1, x: -5, y: 5)
                    .overlay {
                        ZStack {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(selectedTheme == theme ? .white : .clear)
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    selectedTheme == theme ? .black : .clear,
                                    lineWidth: 2
                                )
                        }
                    }
                    .background(content: {
                        if selectedTheme == theme{
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.lightYellow)
                                .padding(-3)
                        }
                    })
                    .onTapGesture {
                        selectedTheme = theme
                    }
            }
        }
    }
}

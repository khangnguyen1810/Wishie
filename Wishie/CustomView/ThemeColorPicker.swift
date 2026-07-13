//
//  ThemeColorPicker.swift
//  Wishie
//

import SwiftUI

struct ThemeColorPicker: View {
    @Binding var selectedTheme: GradientTheme?

    private let column = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]

    var body: some View {
        LazyVGrid(columns: column, spacing: 15) {
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
                    .shadow(color: .lightYellow, radius: 1, x: -5, y: 5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                selectedTheme == theme ? .wishiePink : .clear,
                                lineWidth: 3
                            )
                    }
                    .onTapGesture {
                        selectedTheme = theme
                    }
            }
        }
    }
}

#Preview {
    ThemeColorPicker(selectedTheme: .constant(.sunset))
        .padding()
}

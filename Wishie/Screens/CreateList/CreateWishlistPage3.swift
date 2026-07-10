//
//  CreateWishlistPage3.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import SwiftUI

struct CreateWishlistPage3: View {
    @State private var selectedFont: String = "Font"
    let column = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    @EnvironmentObject private var createWishlistViewModel: CreateWishlistViewModel

    var body: some View {
        VStack (alignment: .leading) {
//            Text("Choose your font")
//                .font(.wishies(.regular, 17))
//                .padding(.bottom, 40)
//            HStack {
//                Text(selectedFont)
//                    .font(.wishies(.bold, 17))
//                Spacer()
//                Image(systemName: "chevron.down")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 10)
//            }
//            .padding(.horizontal, 15)
//            .background {
//                RoundedRectangle(cornerRadius: 15).fill(.lightYellow)
//                    .frame(height: 56)
//            }
//            .padding(.bottom, 40)
            Text("Choose your theme color")
                .font(.wishies(.regular, 17))
                .padding(.bottom)
                .padding(.horizontal)
            ScrollView {
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
                                        createWishlistViewModel.selectedTheme == theme ? .wishiePink : .clear,
                                        lineWidth: 3
                                    )
                            }
                            .onTapGesture {
                                createWishlistViewModel.selectedTheme = theme
                            }
                    }
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
    }
}

//
//  CreateWishlistPage3.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 15/12/25.
//

import SwiftUI

struct CreateWishlistPage3: View {
    @State private var selectedFont: String = "Font"
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
                ThemeColorPicker(selectedTheme: $createWishlistViewModel.selectedTheme)
                    .padding()
            }
            .scrollIndicators(.hidden)
        }
    }
}

//
//  GiftProgressView.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 13/12/25.
//

import SwiftUI
struct GiftProgressView: View {
    var progress: Double
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.wishiePink, .lightYellow1],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: geo.size.height )
                }
            }
            .mask(
                Image("gift_img")
                    .resizable()
                    .scaledToFit()
            )
            Image("gift_img")
                .resizable()
                .scaledToFit()
                .mask(
                    GeometryReader { geo in
                        VStack {
                            Spacer()
                            
                            Rectangle()
                                .frame(height: geo.size.height * progress)
                        }
                    }
                )
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

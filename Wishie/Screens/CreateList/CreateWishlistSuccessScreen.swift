//
//  CreateWishlistSuccessScreen.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 30/12/25.
//

import SwiftUI
import DotLottie

struct CreateWishlistSuccessScreen: View {
    @Binding var path: NavigationPath
    @State private var showShare = false
    let wishlistId: String
    var body: some View {
        BaseWishieScreen {
            TopAppBar()
        } content: {
            VStack {
                DotLottieAnimation(
                    fileName: "Done",
                    config: AnimationConfig(autoplay: true, loop: true)
                )
                .view()
                .frame(width: 180, height: 180)
                .scaledToFit()
                Text("Success!")
                    .font(.wishies(.bold, 30))
                    .foregroundStyle(.black)
                Spacer()
                Text("You have created a new wishlist!")
                    .font(.wishies(.regular, 25))
                    .foregroundStyle(.black)
                VStack (spacing: 10) {
                    WishieButton(title: "Share it now!", enabled: true) {
                        path.append(Route.qrCodeScreen(wishlistId: wishlistId))
                    }
                    WishieButton(title: "Back to home page", enabled: true) {
                        path.removeLast(path.count)
                    }
                }
            }
            .padding(.vertical, 50)
            .padding(.horizontal,20)
        
        }
        
    }
}

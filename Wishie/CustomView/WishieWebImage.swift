//
//  WishieWebImage.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 24/5/26.
//

import SwiftUI
import SDWebImageSwiftUI
import DotLottie

struct WishieWebImage: View {
    var url: String
    var body: some View {
        WebImage(
            url: URL(string: url),
            content: { image in
                image
                    .resizable()
                    .scaledToFill()
            },
            placeholder: {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: 100, height: 100)
                    .overlay {
                        DotLottieAnimation(
                            fileName: "giftloading",
                            config: AnimationConfig(autoplay: true, loop: true)
                        )
                        .view()
                        .frame(width: 40)
                    }
            }
        )
    }
}

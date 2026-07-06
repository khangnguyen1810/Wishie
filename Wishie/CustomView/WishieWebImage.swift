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
    let url: String
    let contentMode: ContentMode
    let placeholderSize: CGFloat

    init(
        url: String,
        contentMode: ContentMode = .fill,
        placeholderSize: CGFloat = 100
    ) {
        self.url = url
        self.contentMode = contentMode
        self.placeholderSize = placeholderSize
    }

    var body: some View {
        WebImage(
            url: URL(string: url),
            content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            },
            placeholder: {
                Circle()
                    .fill(.lightYellow)
                    .frame(width: placeholderSize, height: placeholderSize)
                    .overlay {
                        DotLottieAnimation(
                            fileName: "giftloading",
                            config: AnimationConfig(
                                autoplay: true,
                                loop: true
                            )
                        )
                        .view()
                        .frame(width: placeholderSize * 0.4)
                    }
            }
        )
    }
}

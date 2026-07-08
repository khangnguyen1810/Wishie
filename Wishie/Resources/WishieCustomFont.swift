//
//  WishieCustomFont.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import Foundation
import SwiftUI
enum WishieFont: String {
    case regular = "Nunito-Regular"
    case medium = "Nunito-Medium"
    case bold = "Nunito-Bold"
    case light = "Nunito-Light"
    case italic = "Nunito-Italic"
}

extension Font {
    static func wishies(_ weight: WishieFont, _ size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}

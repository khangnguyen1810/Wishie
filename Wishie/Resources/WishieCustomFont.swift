//
//  WishieCustomFont.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import Foundation
import SwiftUI
enum WishieFont: String {
    case regular = "Fredoka-Regular"
    case medium = "Fredoka-Medium"
    case bold = "Fredoka-Bold"
    case light = "Fredoka-Light"
}

extension Font {
    static func wishies(_ weight: WishieFont, _ size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}

//
//  WishieCustomFont.swift
//  Wishie
//
//  Created by Nguyễn Khang Hữu on 5/10/25.
//

import Foundation
import SwiftUI
enum WishieFont: String {
    case regular = "WorkSans-Regular"
    case bold = "WorkSans-Bold"
    case light = "WorkSans-Light"
    case italic = "WorkSans-Italic"
}

extension Font {
    static func wishies(_ weight: WishieFont, _ size: CGFloat) -> Font {
        return .custom(weight.rawValue, size: size)
    }
}

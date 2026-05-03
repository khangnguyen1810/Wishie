//
//  TextHeightKey.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 29/3/26.
//

import Foundation
import SwiftUI

struct TextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

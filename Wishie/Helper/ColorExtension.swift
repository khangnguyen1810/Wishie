//
//  ColorExtension.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 31/3/26.
//

import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b, a: UInt64
        
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (1, 1, 1, 1) // fallback
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Blends the color toward white so it reads as a softer, less saturated surface
    /// while keeping its hue recognizable. `amount` is 0 (unchanged) to 1 (pure white).
    func lightened(by amount: CGFloat) -> Color {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(
            .sRGB,
            red: r + (1 - r) * amount,
            green: g + (1 - g) * amount,
            blue: b + (1 - b) * amount,
            opacity: a
        )
    }
}

//
//  GradientWishlishTheme.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 21/12/25.
//
import SwiftUI
enum GradientTheme: String, CaseIterable {
    case coral
    case mint
    case grape
    case gold
    case green

    var primary: String {
        switch self {
        case .coral:
            return "#E07856"
        case .mint:
            return "#3FC7A8"
        case .grape:
            return "#9C7FE8"
        case .gold:
            return "#C79A3D"
        case .green:
            return "#5E9A62"
        }
    }
    var secondary: String {
        primary
    }
    /// Softer tint of `primary`: the background of a compact Home card.
    var soft: String {
        switch self {
        case .coral: return "#F3B9A6"
        case .mint: return "#A9E6D6"
        case .grape: return "#CFC0F5"
        case .gold: return "#F2D9A2"
        case .green: return "#BCD8BD"
        }
    }
    /// Palest tint: empty or secondary tiles inside a Home card's item mosaic.
    var tile: String {
        switch self {
        case .coral: return "#FBE3DA"
        case .mint: return "#E6F8F3"
        case .grape: return "#EFE9FC"
        case .gold: return "#F8EACB"
        case .green: return "#E8F2E8"
        }
    }
    /// Dark text colour that reads on both `primary` and `soft`.
    var ink: String {
        switch self {
        case .coral: return "#4A1C0C"
        case .mint: return "#0E3A30"
        case .grape: return "#241552"
        case .gold: return "#4A3408"
        case .green: return "#16331A"
        }
    }
    var background: Color {
        switch self {
        case .coral:
            return Color(.sRGB, red: 232 / 255, green: 132 / 255, blue: 107 / 255, opacity: 0.15)
        case .mint:
            return Color(.sRGB, red: 63 / 255, green: 199 / 255, blue: 168 / 255, opacity: 0.18)
        case .grape:
            return Color(.sRGB, red: 156 / 255, green: 127 / 255, blue: 232 / 255, opacity: 0.18)
        case .gold:
            return Color(.sRGB, red: 242 / 255, green: 199 / 255, blue: 123 / 255, opacity: 0.25)
        case .green:
            return Color(.sRGB, red: 143 / 255, green: 174 / 255, blue: 139 / 255, opacity: 0.18)
        }
    }
    var imageName: String {
        switch self {
        case .coral:
            return "sunset"
        case .mint:
            return "forest"
        case .grape:
            return "purpleDream"
        case .gold:
            return "ocean"
        case .green:
            return "forest"
        }
    }
}

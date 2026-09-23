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

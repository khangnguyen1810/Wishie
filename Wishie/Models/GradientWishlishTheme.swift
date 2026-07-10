//
//  GradientWishlishTheme.swift
//  Wishie
//
//  Created by Khang Huu Nguyen on 21/12/25.
//
import SwiftUI
enum GradientTheme: String, CaseIterable {
    case sunset
    case ocean
    case forest
    case purpleDream

    var primary: String {
        switch self {
        case .sunset:
            return "#FF9A76"
        case .ocean:
            return "#6FE3D0"
        case .forest:
            return "#8DE0A0"
        case .purpleDream:
            return "#B79CF2"
        }
    }
    var secondary: String {
        switch self {
        case .sunset:
            return "#F4667A"
        case .ocean:
            return "#38B7B0"
        case .forest:
            return "#3FAE72"
        case .purpleDream:
            return "#9C7BE0"
        }
    }
    var imageName: String {
        switch self {
        case .sunset:
            return "sunset"
        case .ocean:
            return "ocean"
        case .forest:
            return "forest"
        case .purpleDream:
            return "purpleDream"
        }
    }
}

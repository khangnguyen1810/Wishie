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
            return "#FEF3D7"
        case .ocean:
            return "#cbf1f5"
        case .forest:
            return "#bcd9a2"
        case .purpleDream:
            return "F4EEFF"
        }
    }
    var secondary: String {
        switch self {
        case .sunset:
            return "#F1D790"
        case .ocean:
            return "#71c9ce"
        case .forest:
            return "91C788"
        case .purpleDream:
            return "#dcd6f7"
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

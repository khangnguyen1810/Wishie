//
//  HomePalette.swift
//  Wishie
//

import SwiftUI

/// Fixed (non-theme) colours of the Home moodboard, kept in one place.
enum HomePalette {
    /// Coral accent: add button, avatar ring, "your first wish" circle.
    static let accent = Color(hex: GradientTheme.coral.primary)
    /// Secondary text under the greeting and in empty states.
    static let mutedText = Color(hex: "#7A6548")
    /// Body text in empty states and unselected tabs.
    static let bodyText = Color(hex: "#5E4C33")
    /// Tab track and the empty placeholder card.
    static let track = Color(hex: "#F1E6D3")
    /// Pale tiles inside the empty placeholder card.
    static let emptyTile = Color(hex: "#F8F0E1")
    /// Grey bars standing in for text in the empty placeholder card.
    static let barStrong = Color(hex: "#E4D3B4")
    static let barSoft = Color(hex: "#EADCC2")
    /// Icon tint inside the empty placeholder card.
    static let placeholderIcon = Color(hex: "#9A8460")
    /// Profile avatar fallback background.
    static let avatarFill = Color(hex: "#E9DCC4")
    /// "Top wish" badge.
    static let topWish = Color(hex: "#F2C77B")
}

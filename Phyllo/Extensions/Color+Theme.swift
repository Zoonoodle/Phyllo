//
//  Color+Theme.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

extension Color {
    // Spotify-inspired dark theme colors
    static let phylloBackground = Color(hex: "121212") // Spotify's main background
    static let phylloElevated = Color(hex: "1E1E1E") // Spotify's elevated surface (cards)
    static let phylloSurface = Color(hex: "282828") // Higher elevation surface
    static let phylloAccent = Color(hex: "1DB954") // Spotify green
    static let phylloGreen = Color(hex: "1DB954") // Alias for accent color
    
    // Text colors
    static let phylloTextPrimary = Color.white
    static let phylloTextSecondary = Color.white.opacity(0.7)
    static let phylloTextTertiary = Color.white.opacity(0.5)
    
    // Border and divider
    static let phylloBorder = Color.white.opacity(0.1)
    static let phylloDivider = Color.white.opacity(0.08)
}

// Hex color initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
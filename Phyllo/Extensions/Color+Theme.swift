//
//  Color+Theme.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

extension Color {
    // Softer dark theme colors
    static let phylloBackground = Color(hex: "1A1A1A") // Softer dark background
    static let phylloElevated = Color(hex: "252525") // Softer elevated surface
    static let phylloSurface = Color(hex: "303030") // Softer higher elevation
    static let phylloAccent = Color(hex: "4ADE80") // Softer green
    static let phylloGreen = Color(hex: "4ADE80") // Alias for accent color
    
    // Secondary colors
    static let phylloSecondaryBackground = Color(hex: "1F1F1F") // Between background and elevated
    static let phylloTertiary = Color(hex: "2A2A2A") // Another elevation level
    
    // Text colors
    static let phylloTextPrimary = Color(hex: "FAFAFA") // Slightly off-white
    static let phylloTextSecondary = Color(hex: "FAFAFA").opacity(0.7)
    static let phylloTextTertiary = Color(hex: "FAFAFA").opacity(0.5)
    
    // Border and divider
    static let phylloBorder = Color(hex: "FAFAFA").opacity(0.08)
    static let phylloDivider = Color(hex: "FAFAFA").opacity(0.06)
    
    // Tab colors
    static let phylloTabInactive = Color(hex: "FAFAFA").opacity(0.3)
    static let phylloTabActive = Color.phylloAccent
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
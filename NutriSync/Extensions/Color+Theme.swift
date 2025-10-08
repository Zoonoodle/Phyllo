//
//  Color+Theme.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import SwiftUI

extension Color {
    // Softer dark theme colors
    static let nutriSyncBackground = Color(hex: "1A1A1A") // Softer dark background
    static let nutriSyncElevated = Color(hex: "252525") // Softer elevated surface
    static let nutriSyncSurface = Color(hex: "303030") // Softer higher elevation
    static let nutriSyncAccent = Color(hex: "C0FF73") // Signature lime green
    static let nutriSyncGreen = Color(hex: "C0FF73") // Alias for accent color
    
    // Secondary colors
    static let nutriSyncSecondaryBackground = Color(hex: "1F1F1F") // Between background and elevated
    static let nutriSyncTertiary = Color(hex: "2A2A2A") // Another elevation level
    
    // Text colors
    static let nutriSyncTextPrimary = Color(hex: "FAFAFA") // Slightly off-white
    static let nutriSyncTextSecondary = Color(hex: "FAFAFA").opacity(0.7)
    static let nutriSyncTextTertiary = Color(hex: "FAFAFA").opacity(0.5)
    
    // Border and divider
    static let nutriSyncBorder = Color(hex: "FAFAFA").opacity(0.08)
    static let nutriSyncDivider = Color(hex: "FAFAFA").opacity(0.06)
    
    // Tab colors
    static let nutriSyncTabInactive = Color(hex: "FAFAFA").opacity(0.3)
    static let nutriSyncTabActive = Color.nutriSyncAccent
    
    // Phyllo aliases for compatibility
    static let phylloBackground = nutriSyncBackground
    static let phylloCard = Color.white.opacity(0.03)
    static let phylloAccent = nutriSyncAccent // Uses #C0FF73
    static let phylloText = nutriSyncTextPrimary
    static let phylloTextSecondary = nutriSyncTextSecondary
    static let phylloTextTertiary = nutriSyncTextTertiary
    
    // Window state colors
    static let phylloFasted = Color.gray.opacity(0.6)  // Neutral gray for fasted
    static let phylloMissed = Color.red.opacity(0.8)   // Red for missed
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
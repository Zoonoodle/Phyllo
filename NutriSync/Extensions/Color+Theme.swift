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

    // MARK: - Window Purpose Gradient Colors
    // Premium gradient color stops for each window purpose
    // Using diverging colors for visible gradient effect

    // Pre-Workout: Warm energy, anticipation (orange → golden yellow)
    static let preWorkoutPrimary = Color(hex: "FF6B35")
    static let preWorkoutSecondary = Color(hex: "FFD93D")

    // Post-Workout: Cool restoration, accomplished (blue → teal)
    static let postWorkoutPrimary = Color(hex: "4361EE")
    static let postWorkoutSecondary = Color(hex: "4CC9F0")

    // Sustained Energy: Signature accent elevated (lime → cyan)
    static let sustainedEnergyPrimary = Color(hex: "AAFF00")
    static let sustainedEnergySecondary = Color(hex: "00F5D4")

    // Recovery: Gentle healing, nurturing (purple → pink)
    static let recoveryPrimary = Color(hex: "9B5DE5")
    static let recoverySecondary = Color(hex: "F15BB5")

    // Metabolic Boost: Controlled intensity (red → orange)
    static let metabolicBoostPrimary = Color(hex: "FF0054")
    static let metabolicBoostSecondary = Color(hex: "FF7A00")

    // Sleep Optimization: Deep night, restful (indigo → violet)
    static let sleepOptimizationPrimary = Color(hex: "5C4D9A")
    static let sleepOptimizationSecondary = Color(hex: "9D4EDD")

    // Focus Boost: Mental clarity, precision (signature lime → cyan)
    static let focusBoostPrimary = Color(hex: "C0FF73")
    static let focusBoostSecondary = Color(hex: "00E5FF")

    // Late Window: Warm amber urgency (amber → gold)
    static let lateWindowPrimary = Color(hex: "F59E0B")
    static let lateWindowSecondary = Color(hex: "FBBF24")

    // MARK: - Score Colors (1-10 Scale)

    /// Excellent score: 8.5-10.0 (signature accent)
    static let scoreExcellent = Color(hex: "C0FF73")
    /// Good score: 7.0-8.4 (green)
    static let scoreGood = Color(hex: "A8E063")
    /// Okay score: 5.0-6.9 (yellow)
    static let scoreOkay = Color(hex: "FFD93D")
    /// Poor score: 3.0-4.9 (orange)
    static let scorePoor = Color(hex: "FFA500")
    /// Bad score: 0.0-2.9 (red)
    static let scoreBad = Color(hex: "FF6B6B")

    /// Returns the appropriate color for a score on the 1-10 scale
    static func scoreColor(for score: Double) -> Color {
        switch score {
        case 8.5...10.0: return .scoreExcellent
        case 7.0..<8.5: return .scoreGood
        case 5.0..<7.0: return .scoreOkay
        case 3.0..<5.0: return .scorePoor
        default: return .scoreBad
        }
    }

    // MARK: - Factor Chip Colors

    /// Positive factor contribution (+X.X)
    static let factorPositive = Color(hex: "A8E063").opacity(0.9)
    /// Negative factor contribution (-X.X)
    static let factorNegative = Color(hex: "FF6B6B").opacity(0.9)
    /// Neutral factor (0.0)
    static let factorNeutral = Color.white.opacity(0.5)

    // MARK: - Component Backgrounds

    /// Chip background
    static let chipBackground = Color.white.opacity(0.05)
    /// Chip border
    static let chipBorder = Color.white.opacity(0.1)
    /// Insight box background
    static let insightBackground = Color.white.opacity(0.03)
    /// Insight box border
    static let insightBorder = Color.white.opacity(0.08)
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
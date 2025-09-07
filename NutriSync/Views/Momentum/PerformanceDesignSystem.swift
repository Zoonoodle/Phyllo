//
//  PerformanceDesignSystem.swift
//  NutriSync
//
//  Unified design system for Performance tab matching Schedule tab patterns
//

import SwiftUI

struct PerformanceDesignSystem {
    // Colors (from Schedule tab)
    static let background = Color(hex: "0a0a0a")
    static let cardBackground = Color(hex: "1A1A1A")
    static let cardBorder = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    
    // Contextual colors (muted)
    static let successMuted = Color(hex: "10b981").opacity(0.8)
    static let warningMuted = Color(hex: "eab308").opacity(0.8)
    static let errorMuted = Color(hex: "ef4444").opacity(0.8)
    
    // Layout
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let borderWidth: CGFloat = 1
    
    // Typography (from TimelineTypography)
    static let labelFont = Font.system(size: 11, weight: .medium)
    static let valueFont = Font.system(size: 24, weight: .bold)
    static let supportingFont = Font.system(size: 13, weight: .regular)
    static let trendFont = Font.system(size: 12, weight: .medium)
    
    // Animation
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    // Shadows
    static let cardShadow = Color.black.opacity(0.15)
    static let shadowRadius: CGFloat = 4
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 2
}

// MARK: - Performance Status Types
enum PerformanceStatus {
    case excellent
    case good
    case needsWork
    case critical
    
    var color: Color {
        switch self {
        case .excellent:
            return PerformanceDesignSystem.successMuted
        case .good:
            return PerformanceDesignSystem.textSecondary
        case .needsWork:
            return PerformanceDesignSystem.warningMuted
        case .critical:
            return PerformanceDesignSystem.errorMuted
        }
    }
    
    var description: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .needsWork:
            return "Needs attention"
        case .critical:
            return "Critical"
        }
    }
}

// MARK: - Trend Direction
enum TrendDirection {
    case up
    case down
    case stable
    
    var icon: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .down:
            return "arrow.down.right"
        case .stable:
            return "arrow.right"
        }
    }
    
    var color: Color {
        switch self {
        case .up:
            return PerformanceDesignSystem.successMuted
        case .down:
            return PerformanceDesignSystem.errorMuted
        case .stable:
            return PerformanceDesignSystem.textSecondary
        }
    }
}
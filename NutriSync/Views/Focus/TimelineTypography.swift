//
//  TimelineTypography.swift
//  NutriSync
//
//  Created by Claude on 2025-08-30.
//  Purpose: Centralized typography system for Timeline/Schedule view
//  Implements 1.25x scaling and +0.25 opacity boost for better legibility
//

import SwiftUI

struct TimelineTypography {
    // Hour markers (was 12px → 15px)
    static let hourLabel = Font.system(size: 15, weight: .medium)
    static let hourLabelCurrent = Font.system(size: 15, weight: .semibold)
    
    // Window headers (was 13-14px → 16-17px)
    static let windowTitle = Font.system(size: 17, weight: .semibold)
    static let windowTitleInactive = Font.system(size: 16, weight: .semibold)
    
    // Time ranges (was 11px → 14px)
    static let timeRange = Font.system(size: 14, weight: .medium)
    
    // Duration (was 10px → 12px minimum)
    static let duration = Font.system(size: 12, weight: .regular)
    
    // Calories (was 12-15px → 15-18px)
    static let caloriesLarge = Font.system(size: 18, weight: .bold)
    static let caloriesMedium = Font.system(size: 16, weight: .semibold)
    static let caloriesSmall = Font.system(size: 15, weight: .semibold)
    
    // Units (was 10-11px → 12-14px)
    static let calorieUnit = Font.system(size: 14, weight: .regular)
    static let calorieUnitSmall = Font.system(size: 12, weight: .regular)
    
    // Macros (was 9-10px → 12-14px)
    static let macroValue = Font.system(size: 14, weight: .medium)
    static let macroLabel = Font.system(size: 12, weight: .regular)
    
    // Food items (was 13px → 16px)
    static let foodName = Font.system(size: 16, weight: .medium)
    static let foodCalories = Font.system(size: 14, weight: .medium)
    
    // Timestamps (was 11px → 14px)
    static let timestamp = Font.system(size: 14, weight: .regular)
    
    // Status text (was 10-12px → 12-15px)
    static let statusLabel = Font.system(size: 14, weight: .medium)
    static let statusValue = Font.system(size: 15, weight: .semibold)
    
    // Progress (was 12px → 15px)
    static let progressPercentage = Font.system(size: 15, weight: .bold)
    static let progressLabel = Font.system(size: 12, weight: .medium)
}

struct TimelineOpacity {
    // Boosted by +0.25 from original values
    static let primary: Double = 1.0      // was 1.0
    static let secondary: Double = 0.95   // was 0.7
    static let tertiary: Double = 0.75    // was 0.5
    static let quaternary: Double = 0.55  // was 0.3
    
    // Special states
    static let inactive: Double = 0.75    // was 0.5
    static let disabled: Double = 0.55    // was 0.3
    static let currentHour: Double = 1.0  // was 0.8
    static let otherHour: Double = 0.75   // was 0.5
}
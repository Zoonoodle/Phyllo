//
//  FirstDayWindowService.swift
//  NutriSync
//
//  Created on 9/23/25.
//

import Foundation

/// Protocol defining first-day window generation capabilities
protocol FirstDayWindowGenerating {
    func shouldGenerateFirstDayWindows(profile: UserProfile) -> Bool
    func generateFirstDayWindows(
        for profile: UserProfile,
        completionTime: Date
    ) async throws -> [MealWindow]
    func calculateProRatedCalories(
        dailyCalories: Int,
        remainingHours: Double,
        totalWakingHours: Double
    ) -> Int
}

/// Service responsible for generating meal windows for user's first day after onboarding
@MainActor
class FirstDayWindowService: FirstDayWindowGenerating {
    
    // MARK: - Properties
    private let calendar = Calendar.current
    private let minimumWindowDuration: Double = 1.0 // hours
    private let minimumWindowSpacing: Double = 2.0 // hours
    private let bedtimeBufferHours: Int = 3 // No eating 3 hours before bed
    private let firstWindowDelayMinutes: Int = 30 // 30 min delay for first window
    
    // MARK: - Public Methods
    
    /// Determine if first-day windows should be generated for this profile
    nonisolated func shouldGenerateFirstDayWindows(profile: UserProfile) -> Bool {
        // Generate first-day windows if:
        // 1. User has completed onboarding (onboardingCompletedAt is set)
        // 2. First day has not been completed yet
        // 3. We're still on the same day as onboarding completion
        
        guard let onboardingDate = profile.onboardingCompletedAt else {
            return false
        }
        
        // Check if first day is already completed
        if profile.firstDayCompleted {
            return false
        }
        
        // Check if we're still on the same day as onboarding
        let now = Date()
        let onboardingDay = calendar.startOfDay(for: onboardingDate)
        let today = calendar.startOfDay(for: now)
        
        // Only generate first-day windows on the actual day of onboarding
        return onboardingDay == today
    }
    
    /// Generate meal windows for the remainder of the first day
    func generateFirstDayWindows(
        for profile: UserProfile,
        completionTime: Date
    ) async throws -> [MealWindow] {
        
        // Create configuration for first day
        let config = FirstDayConfiguration(
            completionTime: completionTime,
            profile: profile
        )
        
        // If it's too late or not enough time, return empty array
        // The UI should show tomorrow's plan message
        guard config.numberOfWindows > 0 else {
            return []
        }
        
        // Get window purposes, times, and calorie distribution
        let purposes = config.getWindowPurposes()
        let windowTimes = config.getWindowTimes()
        let calorieDistribution = config.getCalorieDistribution()
        
        // Generate windows
        var windows: [MealWindow] = []
        
        for i in 0..<config.numberOfWindows {
            let windowId = UUID()
            let purpose = purposes[i]
            let (startTime, endTime) = windowTimes[i]
            let calories = calorieDistribution[i]
            
            // Calculate macros based on window purpose
            let macros = calculateMacros(
                calories: calories,
                purpose: purpose,
                profile: profile
            )
            
            // Determine window name based on time and purpose
            let name = generateWindowName(
                index: i,
                totalWindows: config.numberOfWindows,
                startTime: startTime,
                purpose: purpose
            )
            
            let window = MealWindow(
                id: windowId,
                name: name,
                startTime: startTime,
                endTime: endTime,
                targetCalories: calories,
                targetProtein: macros.protein,
                targetCarbs: macros.carbs,
                targetFat: macros.fat,
                isFirstDay: true,
                date: completionTime
            )
            
            windows.append(window)
        }
        
        return windows
    }
    
    /// Calculate pro-rated calories based on remaining time in day
    nonisolated func calculateProRatedCalories(
        dailyCalories: Int,
        remainingHours: Double,
        totalWakingHours: Double
    ) -> Int {
        guard totalWakingHours > 0 else { return dailyCalories }
        
        let proRataFactor = remainingHours / totalWakingHours
        let proRatedCalories = Int(Double(dailyCalories) * proRataFactor)
        
        // Ensure minimum calories (at least 200) and maximum (not more than full day)
        return min(max(200, proRatedCalories), dailyCalories)
    }
    
    // MARK: - Private Methods
    
    /// Calculate macros for a window based on calories and purpose
    private func calculateMacros(
        calories: Int,
        purpose: FirstDayConfiguration.WindowPurpose,
        profile: UserProfile
    ) -> (protein: Int, carbs: Int, fat: Int) {
        
        let distribution = purpose.macroDistribution
        
        // Calculate grams from calories
        // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
        let proteinCalories = Double(calories) * distribution.proteinRatio
        let carbCalories = Double(calories) * distribution.carbRatio
        let fatCalories = Double(calories) * distribution.fatRatio
        
        let protein = Int(proteinCalories / 4)
        let carbs = Int(carbCalories / 4)
        let fat = Int(fatCalories / 9)
        
        return (protein, carbs, fat)
    }
    
    /// Generate appropriate window name based on time and purpose
    private func generateWindowName(
        index: Int,
        totalWindows: Int,
        startTime: Date,
        purpose: FirstDayConfiguration.WindowPurpose
    ) -> String {
        
        let hour = calendar.component(.hour, from: startTime)
        
        // For single window days
        if totalWindows == 1 {
            if hour < 15 {
                return "Lunch & Afternoon"
            } else if hour < 18 {
                return "Dinner"
            } else {
                return "Evening Meal"
            }
        }
        
        // For multiple windows
        switch index {
        case 0: // First window
            if hour < 12 {
                return "Late Breakfast"
            } else if hour < 15 {
                return "Lunch"
            } else if hour < 17 {
                return "Late Lunch"
            } else {
                return "Early Dinner"
            }
            
        case 1: // Second window
            if totalWindows == 2 {
                if hour < 18 {
                    return "Dinner"
                } else {
                    return "Evening Meal"
                }
            } else { // 3 windows
                if hour < 16 {
                    return "Afternoon Snack"
                } else if hour < 19 {
                    return "Dinner"
                } else {
                    return "Evening Meal"
                }
            }
            
        case 2: // Third window (only for 3-window days)
            if hour < 20 {
                return "Evening Snack"
            } else {
                return "Light Evening Meal"
            }
            
        default:
            return "Meal \(index + 1)"
        }
    }
    
    /// Create a message for when it's too late to generate windows
    func getTomorrowPlanMessage() -> String {
        return """
        Welcome to NutriSync! 🎉
        
        Since it's late in the day, we've prepared your meal windows for tomorrow.
        Get ready to start fresh in the morning with your personalized nutrition plan!
        
        Your first meal window will begin after you complete your morning check-in.
        """
    }
    
    /// Mark first day as completed in the user profile
    func markFirstDayCompleted(profile: inout UserProfile) {
        profile.firstDayCompleted = true
    }
}

// MARK: - Helper Extensions

extension FirstDayWindowService {
    
    /// Generate sample windows for testing/preview
    static func generateSampleWindows(
        for profile: UserProfile,
        at time: Date = Date()
    ) -> [MealWindow] {
        
        let service = FirstDayWindowService()
        let config = FirstDayConfiguration(
            completionTime: time,
            profile: profile
        )
        
        guard config.numberOfWindows > 0 else { return [] }
        
        let windowTimes = config.getWindowTimes()
        let calorieDistribution = config.getCalorieDistribution()
        
        var windows: [MealWindow] = []
        
        for i in 0..<config.numberOfWindows {
            let (start, end) = windowTimes[i]
            let calories = calorieDistribution[i]
            
            windows.append(MealWindow(
                id: UUID(),
                name: "Window \(i + 1)",
                startTime: start,
                endTime: end,
                targetCalories: calories,
                targetProtein: calories / 10, // Rough estimate
                targetCarbs: calories / 8,
                targetFat: calories / 20,
                isFirstDay: true,
                date: time
            ))
        }
        
        return windows
    }
}
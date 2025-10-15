//
//  FirstDayConfiguration.swift
//  NutriSync
//
//  Created on 9/23/25.
//

import Foundation

/// Configuration for generating meal windows on user's first day after onboarding
/// This handles partial day scenarios where users complete onboarding mid-day
struct FirstDayConfiguration: Codable {
    /// Time when onboarding was completed (start point for window generation)
    let completionTime: Date
    
    /// User's typical bedtime (from profile)
    let bedtime: Date
    
    /// Hours remaining until bedtime buffer (bedtime - 3 hours)
    let remainingHours: Double
    
    /// User's total waking hours for calorie calculation
    let totalWakingHours: Double
    
    /// Pro-rated calorie target for the partial day
    let proRatedCalories: Int
    
    /// Pro-rated macro targets
    let proRatedProtein: Int
    let proRatedCarbs: Int
    let proRatedFat: Int
    
    /// Number of windows to generate (1-3 based on remaining time)
    let numberOfWindows: Int
    
    /// First window start time (completion time + 30 minutes)
    let firstWindowStartTime: Date
    
    /// Flag indicating if tomorrow's plan should be shown instead
    let showTomorrowPlan: Bool
    
    // MARK: - Initializer
    init(
        completionTime: Date,
        profile: UserProfile,
        currentTime: Date? = nil
    ) {
        let now = currentTime ?? Date()
        self.completionTime = completionTime
        
        // Calculate bedtime for today
        let calendar = Calendar.current
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        var bedtimeComponents = calendar.dateComponents([.hour, .minute], from: profile.typicalSleepTime ?? Date())
        bedtimeComponents.year = todayComponents.year
        bedtimeComponents.month = todayComponents.month
        bedtimeComponents.day = todayComponents.day
        
        // If bedtime has already passed, use tomorrow's bedtime
        var calculatedBedtime = calendar.date(from: bedtimeComponents) ?? Date()
        if calculatedBedtime <= now {
            calculatedBedtime = calendar.date(byAdding: .day, value: 1, to: calculatedBedtime) ?? calculatedBedtime
        }
        self.bedtime = calculatedBedtime
        
        // Calculate bedtime buffer (3 hours before bedtime)
        let bedtimeBuffer = calendar.date(byAdding: .hour, value: -3, to: calculatedBedtime) ?? calculatedBedtime
        
        // Calculate remaining hours until bedtime buffer
        let remainingTimeInterval = bedtimeBuffer.timeIntervalSince(now)
        self.remainingHours = max(0, remainingTimeInterval / 3600.0)
        
        // Calculate total waking hours
        let wakeTime = profile.typicalWakeTime ?? Date()
        let sleepTime = profile.typicalSleepTime ?? Date()
        let wakingTimeInterval = sleepTime.timeIntervalSince(wakeTime)
        self.totalWakingHours = abs(wakingTimeInterval / 3600.0)
        
        // Determine if we should show tomorrow's plan
        let currentHour = calendar.component(.hour, from: now)
        self.showTomorrowPlan = currentHour >= 20 || remainingHours < 2.0
        
        // Calculate pro-rated calories and macros
        if !showTomorrowPlan && totalWakingHours > 0 {
            let proRataFactor = remainingHours / totalWakingHours
            self.proRatedCalories = Int(Double(profile.dailyCalorieTarget) * proRataFactor)
            self.proRatedProtein = Int(Double(profile.dailyProteinTarget) * proRataFactor)
            self.proRatedCarbs = Int(Double(profile.dailyCarbTarget) * proRataFactor)
            self.proRatedFat = Int(Double(profile.dailyFatTarget) * proRataFactor)
        } else {
            // Full day values for tomorrow
            self.proRatedCalories = profile.dailyCalorieTarget
            self.proRatedProtein = profile.dailyProteinTarget
            self.proRatedCarbs = profile.dailyCarbTarget
            self.proRatedFat = profile.dailyFatTarget
        }
        
        // Determine number of windows based on remaining time
        if showTomorrowPlan {
            self.numberOfWindows = 0 // Will generate full day tomorrow
        } else if remainingHours >= 6 {
            self.numberOfWindows = 3
        } else if remainingHours >= 4 {
            self.numberOfWindows = 2
        } else if remainingHours >= 2 {
            self.numberOfWindows = 1
        } else {
            self.numberOfWindows = 0 // Too late, show tomorrow
        }
        
        // Calculate first window start time (30 minutes from now)
        self.firstWindowStartTime = calendar.date(byAdding: .minute, value: 30, to: now) ?? now
    }
    
    // MARK: - Helper Methods
    
    /// Determine window purposes based on time of day and number of windows
    func getWindowPurposes() -> [WindowPurpose] {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: completionTime)
        
        switch numberOfWindows {
        case 3:
            if hour < 12 {
                return [.sustainedEnergy, .metabolicBoost, .recovery]
            } else {
                return [.metabolicBoost, .sustainedEnergy, .sleepOptimized]
            }
        case 2:
            if hour < 16 {
                return [.sustainedEnergy, .recovery]
            } else {
                return [.sustainedEnergy, .sleepOptimized]
            }
        case 1:
            if hour < 18 {
                return [.sustainedEnergy]
            } else {
                return [.sleepOptimized]
            }
        default:
            return []
        }
    }
    
    /// Calculate calorie distribution for each window
    func getCalorieDistribution() -> [Int] {
        guard numberOfWindows > 0 else { return [] }
        
        // Distribute calories based on window purposes
        let purposes = getWindowPurposes()
        var distribution: [Double] = []
        
        for purpose in purposes {
            switch purpose {
            case .sustainedEnergy:
                distribution.append(0.35) // 35% of calories
            case .metabolicBoost:
                distribution.append(0.30) // 30% of calories
            case .recovery:
                distribution.append(0.25) // 25% of calories
            case .sleepOptimized:
                distribution.append(0.20) // 20% of calories - lighter
            default:
                distribution.append(0.30) // Default 30%
            }
        }
        
        // Normalize to ensure sum equals 1.0
        let sum = distribution.reduce(0, +)
        if sum > 0 {
            distribution = distribution.map { $0 / sum }
        }
        
        // Convert to actual calories
        return distribution.map { Int(Double(proRatedCalories) * $0) }
    }
    
    /// Calculate window timing with appropriate spacing
    func getWindowTimes() -> [(start: Date, end: Date)] {
        guard numberOfWindows > 0 else { return [] }
        
        let calendar = Calendar.current
        var windowTimes: [(Date, Date)] = []
        var currentStart = firstWindowStartTime
        
        // Calculate window duration and spacing
        let totalAvailableHours = remainingHours
        let windowDuration = max(1.0, totalAvailableHours / Double(numberOfWindows + 1)) // Hours per window
        let spacing = max(2.0, windowDuration * 0.5) // At least 2 hours between windows
        
        for _ in 0..<numberOfWindows {
            let windowEnd = calendar.date(byAdding: .hour, value: Int(windowDuration), to: currentStart) ?? currentStart
            windowTimes.append((currentStart, windowEnd))
            
            // Next window starts after spacing
            currentStart = calendar.date(byAdding: .hour, value: Int(spacing), to: windowEnd) ?? windowEnd
        }
        
        return windowTimes
    }
}

// MARK: - Window Purpose Extension
extension FirstDayConfiguration {
    enum WindowPurpose: String, Codable {
        case preWorkout = "preWorkout"
        case postWorkout = "postWorkout"
        case sustainedEnergy = "sustainedEnergy"
        case recovery = "recovery"
        case metabolicBoost = "metabolicBoost"
        case sleepOptimized = "sleepOptimized"
        
        var displayName: String {
            switch self {
            case .preWorkout: return "Pre-Workout"
            case .postWorkout: return "Post-Workout"
            case .sustainedEnergy: return "Sustained Energy"
            case .recovery: return "Recovery"
            case .metabolicBoost: return "Metabolic Boost"
            case .sleepOptimized: return "Sleep Optimized"
            }
        }
        
        var macroDistribution: (proteinRatio: Double, carbRatio: Double, fatRatio: Double) {
            // These distributions match AIWindowGenerationService for consistency
            switch self {
            case .preWorkout:
                return (0.20, 0.60, 0.20) // Higher carbs for energy
            case .postWorkout:
                return (0.40, 0.45, 0.15) // High protein for recovery, moderate carbs
            case .sustainedEnergy:
                return (0.25, 0.45, 0.30) // Balanced for steady energy
            case .recovery:
                return (0.35, 0.40, 0.25) // High protein for tissue repair
            case .metabolicBoost:
                return (0.30, 0.40, 0.30) // Balanced with moderate protein boost
            case .sleepOptimized:
                return (0.30, 0.25, 0.45) // Higher fat and protein, lower carbs for sleep
            }
        }
    }
}
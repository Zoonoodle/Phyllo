//
//  MealWindow.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// MARK: - Meal Window

// WindowPurpose moved inside MealWindow struct

// Legacy compatibility mapping
typealias WindowPurpose = MealWindow.WindowPurpose
typealias WindowFlexibility = MealWindow.Flexibility

extension MealWindow.WindowPurpose {
    // Keep legacy display names
    var legacyDisplayName: String {
        switch self {
        case .preWorkout: return "Pre-Workout"
        case .postWorkout: return "Post-Workout"
        case .sustainedEnergy: return "Sustained Energy"
        case .recovery: return "Recovery"
        case .metabolicBoost: return "Metabolic Boost"
        case .sleepOptimization: return "Sleep Optimization"
        case .focusBoost: return "Focus Boost"
        }
    }
    
    var icon: String {
        switch self {
        case .preWorkout: return "figure.run"
        case .postWorkout: return "figure.strengthtraining.traditional"
        case .sustainedEnergy: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .metabolicBoost: return "flame.fill"
        case .sleepOptimization: return "moon.fill"
        case .focusBoost: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .preWorkout: return .orange
        case .postWorkout: return .blue
        case .sustainedEnergy: return .nutriSyncAccent
        case .recovery: return .purple
        case .metabolicBoost: return .red
        case .sleepOptimization: return .indigo
        case .focusBoost: return .cyan
        }
    }
}

extension MealWindow.Flexibility {
    var timeBuffer: TimeInterval {
        switch self {
        case .strict: return 15 * 60 // 15 minutes
        case .moderate: return 30 * 60 // 30 minutes
        case .flexible: return 60 * 60 // 1 hour
        }
    }
    
    var displayName: String {
        switch self {
        case .strict: return "Strict"
        case .moderate: return "Moderate"
        case .flexible: return "Flexible"
        }
    }
}

struct MacroTargets {
    let protein: Int
    let carbs: Int
    let fat: Int
    
    var totalCalories: Int {
        (protein * 4) + (carbs * 4) + (fat * 9)
    }
}

struct MealWindow: Identifiable, Codable {
    let id: String
    var name: String
    let date: Date // The day this window belongs to
    let startTime: Date
    let endTime: Date
    var targetCalories: Int
    var targetProtein: Int
    var targetCarbs: Int
    var targetFat: Int
    let mealType: MealType
    let purpose: WindowPurpose
    let flexibility: WindowFlexibility
    let type: WindowType
    let dayDate: Date // The day this window belongs to
    let isFirstDay: Bool
    
    // AI-generated fields
    var rationale: String?
    var foodSuggestions: [String]
    var micronutrientFocus: [String]
    var activityLinked: String?
    var tips: [String]?
    
    // Consumption tracking
    var consumed: ConsumedMacros
    
    // Adjusted values after redistribution
    var adjustedCalories: Int?
    var adjustedProtein: Int?
    var adjustedCarbs: Int?
    var adjustedFat: Int?
    var redistributionReason: WindowRedistributionManager.RedistributionReason?
    
    // Tracking fasting status
    var isMarkedAsFasted: Bool = false
    
    // New types for window generation
    enum WindowType: String, CaseIterable, Codable {
        case regular = "regular"
        case snack = "snack"
        case shake = "shake"
        case light = "light"
    }
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
    }
    
    enum WindowPurpose: String, CaseIterable, Codable {
        case preWorkout = "pre-workout"
        case postWorkout = "post-workout"
        case sustainedEnergy = "sustained-energy"
        case recovery = "recovery"
        case metabolicBoost = "metabolic-boost"
        case sleepOptimization = "sleep-optimization"
        case focusBoost = "focus-boost"
    }
    
    enum Flexibility: String, CaseIterable, Codable {
        case strict = "strict"
        case moderate = "moderate"
        case flexible = "flexible"
    }
    
    struct ConsumedMacros: Codable {
        var calories: Int = 0
        var protein: Int = 0
        var carbs: Int = 0
        var fat: Int = 0
    }
    
    // Computed properties
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // Display name - uses AI-generated name or falls back to purpose
    var displayName: String {
        name.isEmpty ? purpose.legacyDisplayName : name
    }
    
    // Macro helpers for backward compatibility
    var targetMacros: MacroTargets {
        MacroTargets(protein: targetProtein, carbs: targetCarbs, fat: targetFat)
    }
    
    var adjustedMacros: MacroTargets? {
        guard adjustedProtein != nil || adjustedCarbs != nil || adjustedFat != nil else {
            return nil
        }
        return MacroTargets(
            protein: adjustedProtein ?? targetProtein,
            carbs: adjustedCarbs ?? targetCarbs,
            fat: adjustedFat ?? targetFat
        )
    }
    
    // Get effective values (adjusted if available, otherwise original)
    var effectiveCalories: Int {
        adjustedCalories ?? targetCalories
    }
    
    var effectiveProtein: Int {
        adjustedProtein ?? targetProtein
    }
    
    var effectiveCarbs: Int {
        adjustedCarbs ?? targetCarbs
    }
    
    var effectiveFat: Int {
        adjustedFat ?? targetFat
    }
    
    var effectiveMacros: MacroTargets {
        MacroTargets(
            protein: effectiveProtein,
            carbs: effectiveCarbs,
            fat: effectiveFat
        )
    }
    
    var isActive: Bool {
        let now = TimeProvider.shared.currentTime
        return now >= startTime && now <= endTime
    }
    
    var timeRemaining: TimeInterval? {
        guard isActive else { return nil }
        return endTime.timeIntervalSince(TimeProvider.shared.currentTime)
    }
    
    var isUpcoming: Bool {
        TimeProvider.shared.currentTime < startTime
    }
    
    var isPast: Bool {
        TimeProvider.shared.currentTime > endTime
    }
    
    // Check if a timestamp falls within this window
    func contains(timestamp: Date) -> Bool {
        return timestamp >= startTime && timestamp <= endTime
    }
    
    // Check if window is "late but doable" - past but before the next window
    func isLateButDoable(nextWindow: MealWindow?) -> Bool {
        guard isPast else { return false }
        
        let now = TimeProvider.shared.currentTime
        
        // If there's a next window, check if we're before it
        if let nextWindow = nextWindow {
            return now < nextWindow.startTime
        }
        
        // If no next window, consider it doable if less than 2 hours late
        let timeSinceEnd = now.timeIntervalSince(endTime)
        return timeSinceEnd < 2 * 3600  // 2 hours
    }
    
    // Calculate how late this window is
    var hoursLate: Double? {
        guard isPast else { return nil }
        let timeSinceEnd = TimeProvider.shared.currentTime.timeIntervalSince(endTime)
        return timeSinceEnd / 3600
    }
    
    var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    // MARK: - Initializers
    
    // Primary initializer for window generation
    init(
        id: UUID = UUID(),
        name: String,
        startTime: Date,
        endTime: Date,
        targetCalories: Int,
        targetProtein: Int,
        targetCarbs: Int,
        targetFat: Int,
        purpose: WindowPurpose,
        flexibility: Flexibility,
        type: WindowType,
        foodSuggestions: [String] = [],
        micronutrientFocus: [String] = [],
        rationale: String? = nil,
        activityLinked: String? = nil,
        consumed: ConsumedMacros = ConsumedMacros()
    ) {
        self.id = id.uuidString
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.purpose = purpose
        self.flexibility = flexibility
        self.type = type
        self.foodSuggestions = foodSuggestions
        self.micronutrientFocus = micronutrientFocus
        self.rationale = rationale
        self.activityLinked = activityLinked
        self.consumed = consumed
        self.dayDate = Calendar.current.startOfDay(for: startTime)
        self.tips = nil
        self.adjustedCalories = nil
        self.adjustedProtein = nil
        self.adjustedCarbs = nil
        self.adjustedFat = nil
        self.redistributionReason = nil
        self.isMarkedAsFasted = false
    }
    
    // Legacy compatibility initializer
    init(
        startTime: Date,
        endTime: Date,
        targetCalories: Int,
        targetMacros: MacroTargets,
        purpose: WindowPurpose,
        flexibility: Flexibility,
        dayDate: Date
    ) {
        self.init(
            name: purpose.legacyDisplayName,
            startTime: startTime,
            endTime: endTime,
            targetCalories: targetCalories,
            targetProtein: targetMacros.protein,
            targetCarbs: targetMacros.carbs,
            targetFat: targetMacros.fat,
            purpose: purpose,
            flexibility: flexibility,
            type: .regular
        )
    }
    
    // Full initializer for Firestore/copy operations
    init(
        id: UUID,
        startTime: Date,
        endTime: Date,
        targetCalories: Int,
        targetMacros: MacroTargets,
        purpose: WindowPurpose,
        flexibility: WindowFlexibility,
        dayDate: Date,
        name: String?,
        rationale: String?,
        foodSuggestions: [String]?,
        micronutrientFocus: [String]?,
        tips: [String]?,
        type: String?,
        adjustedCalories: Int? = nil,
        adjustedMacros: MacroTargets? = nil,
        redistributionReason: WindowRedistributionManager.RedistributionReason? = nil,
        isMarkedAsFasted: Bool = false
    ) {
        self.id = id.uuidString
        self.name = name ?? purpose.legacyDisplayName
        self.startTime = startTime
        self.endTime = endTime
        self.targetCalories = targetCalories
        self.targetProtein = targetMacros.protein
        self.targetCarbs = targetMacros.carbs
        self.targetFat = targetMacros.fat
        self.purpose = purpose
        self.flexibility = flexibility
        
        // Handle type conversion
        if let typeString = type, let windowType = WindowType(rawValue: typeString) {
            self.type = windowType
        } else {
            self.type = .regular
        }
        
        self.dayDate = dayDate
        self.foodSuggestions = foodSuggestions ?? []
        self.micronutrientFocus = micronutrientFocus ?? []
        self.rationale = rationale
        self.activityLinked = nil
        self.tips = tips
        self.consumed = ConsumedMacros()
        
        // Handle adjusted values
        self.adjustedCalories = adjustedCalories
        if let adjustedMacros = adjustedMacros {
            self.adjustedProtein = adjustedMacros.protein
            self.adjustedCarbs = adjustedMacros.carbs
            self.adjustedFat = adjustedMacros.fat
        } else {
            self.adjustedProtein = nil
            self.adjustedCarbs = nil
            self.adjustedFat = nil
        }
        
        self.redistributionReason = redistributionReason
        self.isMarkedAsFasted = isMarkedAsFasted
    }
}

// MARK: - Midnight Crossover Handling

extension MealWindow {
    var crossesMidnight: Bool {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: startTime)
        let endDay = calendar.startOfDay(for: endTime)
        return startDay != endDay
    }
    
    func splitAtMidnight() -> [MealWindow] {
        guard crossesMidnight else { return [self] }
        
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: endTime)
        
        // Window before midnight
        let beforeMidnight = MealWindow(
            id: UUID(),
            name: "\(name) (Evening)",
            startTime: startTime,
            endTime: midnight,
            targetCalories: Int(Double(targetCalories) * (midnight.timeIntervalSince(startTime) / duration)),
            targetProtein: Int(Double(targetProtein) * (midnight.timeIntervalSince(startTime) / duration)),
            targetCarbs: Int(Double(targetCarbs) * (midnight.timeIntervalSince(startTime) / duration)),
            targetFat: Int(Double(targetFat) * (midnight.timeIntervalSince(startTime) / duration)),
            purpose: purpose,
            flexibility: flexibility,
            type: type,
            foodSuggestions: foodSuggestions,
            micronutrientFocus: micronutrientFocus,
            rationale: rationale,
            activityLinked: activityLinked,
            consumed: ConsumedMacros()
        )
        
        // Window after midnight  
        let afterMidnight = MealWindow(
            id: UUID(),
            name: "\(name) (Continued)",
            startTime: midnight,
            endTime: endTime,
            targetCalories: targetCalories - beforeMidnight.targetCalories,
            targetProtein: targetProtein - beforeMidnight.targetProtein,
            targetCarbs: targetCarbs - beforeMidnight.targetCarbs,
            targetFat: targetFat - beforeMidnight.targetFat,
            purpose: purpose,
            flexibility: flexibility,
            type: type,
            foodSuggestions: foodSuggestions,
            micronutrientFocus: micronutrientFocus,
            rationale: rationale,
            activityLinked: activityLinked,
            consumed: ConsumedMacros()
        )
        
        return [beforeMidnight, afterMidnight]
    }
}

// MARK: - Mock Data Generation

extension MealWindow {
    // Generate mock windows for different goals
    static func mockWindows(for goal: NutritionGoal) -> [MealWindow] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)  // Ensure dayDate is start of day for consistent queries
        let wakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        let sleepTime = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: now)!
        
        // Calculate ideal last meal time based on circadian rhythm (3 hours before sleep)
        let lastMealTime = calendar.date(byAdding: .hour, value: -3, to: sleepTime)!
        
        // Check if user has workouts scheduled
        let todayWorkouts: [Any] = [] // Removed exerciseSchedule as it's not in new UserProfile
        
        switch goal {
        case .weightLoss:
            // 16:8 intermittent fasting pattern with circadian optimization
            let firstMealTime = calendar.date(byAdding: .hour, value: 5, to: wakeTime)! // Break fast around noon
            let dinnerTime = min(
                calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                lastMealTime // Ensure dinner is 3 hours before sleep
            )
            
            return [
                MealWindow(
                    startTime: firstMealTime,
                    endTime: calendar.date(byAdding: .hour, value: 2, to: firstMealTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 40, carbs: 50, fat: 15),
                    purpose: .metabolicBoost,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 4, to: firstMealTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: firstMealTime)!,
                    targetCalories: 700,
                    targetMacros: MacroTargets(protein: 50, carbs: 70, fat: 20),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: -1, to: dinnerTime)!,
                    endTime: dinnerTime,
                    targetCalories: 400,
                    targetMacros: MacroTargets(protein: 30, carbs: 30, fat: 15), // Lower carbs for better sleep
                    purpose: .sleepOptimization,
                    flexibility: .strict,
                    dayDate: today
                )
            ]
            
        case .muscleGain:
            // 6 meal frequency for muscle building with workout timing
            var windows: [MealWindow] = []
            
            // Breakfast - always first
            windows.append(MealWindow(
                startTime: calendar.date(byAdding: .hour, value: 0, to: wakeTime)!,
                endTime: calendar.date(byAdding: .hour, value: 1, to: wakeTime)!,
                targetCalories: 400,
                targetMacros: MacroTargets(protein: 30, carbs: 50, fat: 10),
                purpose: .metabolicBoost,
                flexibility: .flexible,
                dayDate: today
            ))
            
            // If workout scheduled, add pre/post workout windows
            // Commented out - exerciseSchedule not available in new UserProfile
            /*if let workout = todayWorkouts.first {
                let workoutTime = workout.startTime
                
                // Pre-workout (1-2 hours before)
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: -2, to: workoutTime)!,
                    endTime: calendar.date(byAdding: .hour, value: -1, to: workoutTime)!,
                    targetCalories: 350,
                    targetMacros: MacroTargets(protein: 25, carbs: 50, fat: 8),
                    purpose: .preWorkout,
                    flexibility: .strict,
                    dayDate: today
                ))
                
                // Post-workout (immediately after)
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .minute, value: Int(workout.duration), to: workoutTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 1, to: calendar.date(byAdding: .minute, value: Int(workout.duration), to: workoutTime)!)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 50, carbs: 70, fat: 15),
                    purpose: .postWorkout,
                    flexibility: .strict,
                    dayDate: today
                ))
            }*/
                
                // Add mid-afternoon and evening meals
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 8, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 40, carbs: 50, fat: 15),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 12, to: wakeTime)!,
                    targetCalories: 450,
                    targetMacros: MacroTargets(protein: 35, carbs: 45, fat: 15),
                    purpose: .recovery,
                    flexibility: .flexible,
                    dayDate: today
                ))
            
            // Add remaining meal windows
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 3, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 4, to: wakeTime)!,
                    targetCalories: 350,
                    targetMacros: MacroTargets(protein: 25, carbs: 40, fat: 10),
                    purpose: .preWorkout,
                    flexibility: .moderate,
                    dayDate: today
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 50, carbs: 70, fat: 15),
                    purpose: .postWorkout,
                    flexibility: .strict,
                    dayDate: today
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 8, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 40, carbs: 50, fat: 15),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 12, to: wakeTime)!,
                    targetCalories: 450,
                    targetMacros: MacroTargets(protein: 35, carbs: 45, fat: 15),
                    purpose: .recovery,
                    flexibility: .flexible,
                    dayDate: today
                ))
            
            // Last meal with circadian optimization
            windows.append(MealWindow(
                startTime: calendar.date(byAdding: .hour, value: -1, to: lastMealTime)!,
                endTime: lastMealTime,
                targetCalories: 300,
                targetMacros: MacroTargets(protein: 30, carbs: 20, fat: 10),
                purpose: .sleepOptimization,
                flexibility: .moderate,
                dayDate: today
            ))
            
            // Sort windows by start time and remove duplicates
            return windows.sorted { $0.startTime < $1.startTime }
            
        case .performanceFocus:
            // Optimized for mental and physical performance
            return [
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 1, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 2, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 60, fat: 15),
                    purpose: .focusBoost,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 40, carbs: 70, fat: 20),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 10, to: wakeTime)!,
                    targetCalories: 400,
                    targetMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
                    purpose: .focusBoost,
                    flexibility: .flexible,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 13, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 14, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 18),
                    purpose: .sleepOptimization,
                    flexibility: .moderate,
                    dayDate: today
                )
            ]
            
        case .betterSleep:
            // Optimized for sleep with early dinner and no late eating
            let dinnerTime = calendar.date(byAdding: .hour, value: -4, to: sleepTime)! // 4 hours before sleep
            
            return [
                MealWindow(
                    startTime: wakeTime,
                    endTime: calendar.date(byAdding: .hour, value: 1, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 40, carbs: 70, fat: 20),
                    purpose: .metabolicBoost,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 4, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 18),
                    purpose: .focusBoost,
                    flexibility: .flexible,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 8, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 40, carbs: 60, fat: 20),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: -1, to: dinnerTime)!,
                    endTime: dinnerTime,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 40, fat: 20), // Lower carbs, higher fat for satiety
                    purpose: .sleepOptimization,
                    flexibility: .strict, // Strict to ensure early eating
                    dayDate: today
                )
            ]
            
        default:
            // Default balanced approach with circadian consideration
            return [
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 1, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 2, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 30, carbs: 60, fat: 15),
                    purpose: .metabolicBoost,
                    flexibility: .flexible,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: wakeTime)!,
                    targetCalories: 700,
                    targetMacros: MacroTargets(protein: 40, carbs: 80, fat: 25),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 10, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 35, carbs: 65, fat: 20),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: today
                ),
                MealWindow(
                    startTime: min(
                        calendar.date(byAdding: .hour, value: 13, to: wakeTime)!,
                        calendar.date(byAdding: .hour, value: -1, to: lastMealTime)!
                    ),
                    endTime: min(
                        calendar.date(byAdding: .hour, value: 14, to: wakeTime)!,
                        lastMealTime
                    ),
                    targetCalories: 400,
                    targetMacros: MacroTargets(protein: 25, carbs: 40, fat: 15),
                    purpose: .sleepOptimization,
                    flexibility: .flexible,
                    dayDate: today
                )
            ]
        }
    }
}
//
//  MealWindow.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// MARK: - Meal Window

enum WindowPurpose: String, CaseIterable, Codable {
    case preworkout = "Pre-Workout"
    case postworkout = "Post-Workout"
    case sustainedEnergy = "Sustained Energy"
    case recovery = "Recovery"
    case metabolicBoost = "Metabolic Boost"
    case sleepOptimization = "Sleep Optimization"
    case focusBoost = "Focus Boost"
    
    var icon: String {
        switch self {
        case .preworkout: return "figure.run"
        case .postworkout: return "figure.strengthtraining.traditional"
        case .sustainedEnergy: return "bolt.fill"
        case .recovery: return "heart.fill"
        case .metabolicBoost: return "flame.fill"
        case .sleepOptimization: return "moon.fill"
        case .focusBoost: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .preworkout: return .orange
        case .postworkout: return .blue
        case .sustainedEnergy: return .phylloAccent
        case .recovery: return .purple
        case .metabolicBoost: return .red
        case .sleepOptimization: return .indigo
        case .focusBoost: return .cyan
        }
    }
}

enum WindowFlexibility: String, CaseIterable, Codable {
    case strict = "Strict"
    case moderate = "Moderate"
    case flexible = "Flexible"
    
    var timeBuffer: TimeInterval {
        switch self {
        case .strict: return 15 * 60 // 15 minutes
        case .moderate: return 30 * 60 // 30 minutes
        case .flexible: return 60 * 60 // 1 hour
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

struct MealWindow: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let targetCalories: Int
    let targetMacros: MacroTargets
    let purpose: WindowPurpose
    let flexibility: WindowFlexibility
    let dayDate: Date // The day this window belongs to
    
    // Adjusted values after redistribution
    var adjustedCalories: Int?
    var adjustedMacros: MacroTargets?
    var redistributionReason: WindowRedistributionManager.RedistributionReason?
    
    // Tracking fasting status
    var isMarkedAsFasted: Bool = false
    
    // Computed properties
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    // Get effective values (adjusted if available, otherwise original)
    var effectiveCalories: Int {
        adjustedCalories ?? targetCalories
    }
    
    var effectiveMacros: MacroTargets {
        adjustedMacros ?? targetMacros
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
    
    // Primary initializer with optional ID (for loading from Firestore)
    init(
        id: UUID? = nil,
        startTime: Date,
        endTime: Date,
        targetCalories: Int,
        targetMacros: MacroTargets,
        purpose: WindowPurpose,
        flexibility: WindowFlexibility,
        dayDate: Date,
        adjustedCalories: Int? = nil,
        adjustedMacros: MacroTargets? = nil,
        redistributionReason: WindowRedistributionManager.RedistributionReason? = nil,
        isMarkedAsFasted: Bool = false
    ) {
        self.id = id ?? UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.targetCalories = targetCalories
        self.targetMacros = targetMacros
        self.purpose = purpose
        self.flexibility = flexibility
        self.dayDate = dayDate
        self.adjustedCalories = adjustedCalories
        self.adjustedMacros = adjustedMacros
        self.redistributionReason = redistributionReason
        self.isMarkedAsFasted = isMarkedAsFasted
    }
    
    // Convenience initializer for new windows (generates ID)
    init(
        startTime: Date,
        endTime: Date,
        targetCalories: Int,
        targetMacros: MacroTargets,
        purpose: WindowPurpose,
        flexibility: WindowFlexibility,
        dayDate: Date
    ) {
        self.init(
            id: nil,
            startTime: startTime,
            endTime: endTime,
            targetCalories: targetCalories,
            targetMacros: targetMacros,
            purpose: purpose,
            flexibility: flexibility,
            dayDate: dayDate
        )
    }
}

// MARK: - Mock Data Generation

extension MealWindow {
    // Generate mock windows for different goals
    static func mockWindows(for goal: NutritionGoal, checkIn: MorningCheckInData? = nil, userProfile: UserProfile? = nil) -> [MealWindow] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)  // Ensure dayDate is start of day for consistent queries
        let wakeTime = checkIn?.wakeTime ?? calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
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
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 4, to: firstMealTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: firstMealTime)!,
                    targetCalories: 700,
                    targetMacros: MacroTargets(protein: 50, carbs: 70, fat: 20),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: -1, to: dinnerTime)!,
                    endTime: dinnerTime,
                    targetCalories: 400,
                    targetMacros: MacroTargets(protein: 30, carbs: 30, fat: 15), // Lower carbs for better sleep
                    purpose: .sleepOptimization,
                    flexibility: .strict,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
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
                dayDate: today,
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
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
                    purpose: .preworkout,
                    flexibility: .strict,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
                
                // Post-workout (immediately after)
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .minute, value: Int(workout.duration), to: workoutTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 1, to: calendar.date(byAdding: .minute, value: Int(workout.duration), to: workoutTime)!)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 50, carbs: 70, fat: 15),
                    purpose: .postworkout,
                    flexibility: .strict,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
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
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 12, to: wakeTime)!,
                    targetCalories: 450,
                    targetMacros: MacroTargets(protein: 35, carbs: 45, fat: 15),
                    purpose: .recovery,
                    flexibility: .flexible,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
            
            // Add remaining meal windows
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 3, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 4, to: wakeTime)!,
                    targetCalories: 350,
                    targetMacros: MacroTargets(protein: 25, carbs: 40, fat: 10),
                    purpose: .preworkout,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 50, carbs: 70, fat: 15),
                    purpose: .postworkout,
                    flexibility: .strict,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 8, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 40, carbs: 50, fat: 15),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
                
                windows.append(MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 12, to: wakeTime)!,
                    targetCalories: 450,
                    targetMacros: MacroTargets(protein: 35, carbs: 45, fat: 15),
                    purpose: .recovery,
                    flexibility: .flexible,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ))
            
            // Last meal with circadian optimization
            windows.append(MealWindow(
                startTime: calendar.date(byAdding: .hour, value: -1, to: lastMealTime)!,
                endTime: lastMealTime,
                targetCalories: 300,
                targetMacros: MacroTargets(protein: 30, carbs: 20, fat: 10),
                purpose: .sleepOptimization,
                flexibility: .moderate,
                dayDate: today,
                adjustedCalories: nil,
                adjustedMacros: nil,
                redistributionReason: nil
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
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 40, carbs: 70, fat: 20),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 10, to: wakeTime)!,
                    targetCalories: 400,
                    targetMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
                    purpose: .focusBoost,
                    flexibility: .flexible,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 13, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 14, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 18),
                    purpose: .sleepOptimization,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
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
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 4, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 18),
                    purpose: .focusBoost,
                    flexibility: .flexible,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 8, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 9, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 40, carbs: 60, fat: 20),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: -1, to: dinnerTime)!,
                    endTime: dinnerTime,
                    targetCalories: 500,
                    targetMacros: MacroTargets(protein: 35, carbs: 40, fat: 20), // Lower carbs, higher fat for satiety
                    purpose: .sleepOptimization,
                    flexibility: .strict, // Strict to ensure early eating
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
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
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 5, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 6, to: wakeTime)!,
                    targetCalories: 700,
                    targetMacros: MacroTargets(protein: 40, carbs: 80, fat: 25),
                    purpose: .sustainedEnergy,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                ),
                MealWindow(
                    startTime: calendar.date(byAdding: .hour, value: 10, to: wakeTime)!,
                    endTime: calendar.date(byAdding: .hour, value: 11, to: wakeTime)!,
                    targetCalories: 600,
                    targetMacros: MacroTargets(protein: 35, carbs: 65, fat: 20),
                    purpose: .recovery,
                    flexibility: .moderate,
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
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
                    dayDate: today,
                    adjustedCalories: nil,
                    adjustedMacros: nil,
                    redistributionReason: nil
                )
            ]
        }
    }
}
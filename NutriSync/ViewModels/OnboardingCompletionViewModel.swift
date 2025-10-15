//
//  OnboardingCompletionViewModel.swift
//  NutriSync
//
//  View model for enhanced onboarding completion flow
//

import SwiftUI
import Foundation

enum CompletionScreen {
    case processing
    case visualization
    case explanation
    case nextSteps
}

// Data structures
struct PersonalizedProgram {
    let userId: String
    let createdAt: Date
    let goal: String
    let tdee: Int
    let bmr: Int
    let targetCalories: Int
    let deficit: Int
    let timeline: String
}

struct DayWindows {
    let dayName: String
    let windows: [MealWindow]
    let totalCalories: Int
    let sleepStart: Date
    let sleepEnd: Date
}

struct OnboardingMacroTargets {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    
    var proteinPercentage: Int {
        Int(Double(protein * 4) / Double(calories) * 100)
    }
    
    var carbPercentage: Int {
        Int(Double(carbs * 4) / Double(calories) * 100)
    }
    
    var fatPercentage: Int {
        Int(Double(fat * 9) / Double(calories) * 100)
    }
}

@Observable
@MainActor
class OnboardingCompletionViewModel {
    // State
    var currentScreen: CompletionScreen = .processing
    var processingMessage = "Creating your personalized schedule..."
    var processingComplete = false
    
    // Calculated data
    var program: PersonalizedProgram?
    var weeklyWindows: [DayWindows] = []
    var macroTargets: OnboardingMacroTargets?
    var insights: [String] = []
    
    var userGoal: String? {
        // Convert goal to simple format for WeeklyTargetsView
        guard let goal = program?.goal else { return "maintain" }
        if goal.lowercased().contains("lose") {
            return "lose"
        } else if goal.lowercased().contains("build") || goal.lowercased().contains("muscle") {
            return "gain"
        } else {
            return "maintain"
        }
    }
    
    // Message rotation
    private let messages = [
        "Creating your personalized schedule...",
        "Analyzing your circadian rhythm...",
        "Optimizing meal timing...",
        "Calculating macro targets..."
    ]
    
    private var messageTimer: Timer?
    private var messageIndex = 0
    
    func startProcessing(coordinator: NutriSyncOnboardingViewModel) async {
        // Start message rotation
        startMessageRotation()
        
        // Parallel processing
        async let windows = generateMealWindows(coordinator)
        async let macros = calculateMacros(coordinator)
        async let insights = generateInsights(coordinator)
        async let program = createProgram(coordinator)
        
        // Wait for all
        self.weeklyWindows = await windows
        self.macroTargets = await macros
        self.insights = await insights
        self.program = await program
        
        // Ensure minimum processing time
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            processingComplete = true
            stopMessageRotation()
            currentScreen = .visualization
        }
    }
    
    private func startMessageRotation() {
        messageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.messageIndex = (self.messageIndex + 1) % self.messages.count
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.processingMessage = self.messages[self.messageIndex]
                }
            }
        }
    }
    
    private func stopMessageRotation() {
        messageTimer?.invalidate()
        messageTimer = nil
    }
    
    private func generateMealWindows(_ coordinator: NutriSyncOnboardingViewModel) async -> [DayWindows] {
        // Generate weekly meal windows based on user data
        let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var windows: [DayWindows] = []
        
        for day in daysOfWeek {
            // Use coordinator data to create realistic windows
            let dayWindows = DayWindows(
                dayName: day,
                windows: createDayMealWindows(coordinator, for: day),
                totalCalories: calculateDailyCalories(coordinator),
                sleepStart: coordinator.bedTime,
                sleepEnd: coordinator.wakeTime
            )
            windows.append(dayWindows)
        }
        
        return windows
    }
    
    private func createDayMealWindows(_ coordinator: NutriSyncOnboardingViewModel, for day: String) -> [MealWindow] {
        var windows: [MealWindow] = []
        
        // Parse eating window - it's stored as "earlyBird", "balanced", or "nightOwl"
        let windowHours: Int = {
            switch coordinator.eatingWindow {
            case "earlyBird":
                return 8  // 1-9 hours after waking
            case "balanced":
                return 8  // 3-11 hours after waking
            case "nightOwl":
                return 8  // 5-13 hours after waking
            default:
                // Try to parse as "X hours" format for backward compatibility
                if let hours = Int(coordinator.eatingWindow.components(separatedBy: " ").first ?? "") {
                    return hours
                }
                return 8  // Default to 8-hour window
            }
        }()
        
        // Parse meal frequency from string format (e.g., "3 meals")
        let mealCountString = coordinator.mealFrequency.components(separatedBy: " ").first ?? "3"
        let mealCount = Int(mealCountString) ?? 3
        
        // Calculate proper meal timing based on sleep schedule
        let calendar = Calendar.current
        let wakeTime = coordinator.wakeTime
        let bedTime = coordinator.bedTime
        
        // Debug logging
        print("[MealWindows] Creating windows for \(day)")
        print("[MealWindows] Wake: \(formatTime(wakeTime)), Bed: \(formatTime(bedTime))")
        print("[MealWindows] Eating window: \(coordinator.eatingWindow) → \(windowHours) hours")
        print("[MealWindows] Meal frequency: \(coordinator.mealFrequency) → \(mealCount) meals")
        
        // First meal: 1 hour after wake
        let firstMealTime = calendar.date(byAdding: .hour, value: 1, to: wakeTime) ?? wakeTime
        
        // Last meal should END 3-4 hours before bed for optimal sleep
        let hoursBeforeBed = 3.5
        let lastMealEndTime = calendar.date(byAdding: .hour, value: -Int(hoursBeforeBed), to: bedTime) ?? bedTime
        
        // Calculate the actual eating window based on these constraints
        let actualWindowDuration = lastMealEndTime.timeIntervalSince(firstMealTime)
        
        // If we have more than 1 meal, distribute them evenly
        let mealSpacing = mealCount > 1 ? actualWindowDuration / Double(mealCount - 1) : 0
        
        for i in 0..<mealCount {
            let startTime: Date
            if i == 0 {
                // First meal
                startTime = firstMealTime
            } else if i == mealCount - 1 {
                // Last meal - work backwards from desired end time
                startTime = calendar.date(byAdding: .hour, value: -1, to: lastMealEndTime) ?? lastMealEndTime
            } else {
                // Middle meals - evenly spaced
                startTime = Date(timeInterval: mealSpacing * Double(i), since: firstMealTime)
            }
            
            let endTime = calendar.date(byAdding: .hour, value: 1, to: startTime) ?? startTime // 1 hour window
            
            let purpose: String = {
                switch i {
                case 0: return "metabolicBoost"
                case mealCount - 1: return "recovery"
                default: return "sustainedEnergy"
                }
            }()
            
            let windowPurpose: MealWindow.WindowPurpose = {
                switch purpose {
                case "metabolicBoost": return .metabolicBoost
                case "recovery": return .recovery
                case "sustainedEnergy": return .sustainedEnergy
                default: return .sustainedEnergy
                }
            }()
            
            let window = MealWindow(
                id: UUID(),
                name: getMealName(for: i, total: mealCount),
                startTime: startTime,
                endTime: endTime,
                targetCalories: calculateDailyCalories(coordinator) / mealCount,
                targetProtein: 25,
                targetCarbs: 40,
                targetFat: 15,
                purpose: windowPurpose,
                flexibility: .flexible,
                type: .regular
            )
            
            windows.append(window)
            
            // Debug: Log the created window
            print("[MealWindows] \(window.name): \(formatTime(startTime)) - \(formatTime(endTime))")
        }
        
        // Log summary
        if let first = windows.first, let last = windows.last {
            print("[MealWindows] Eating window: \(formatTime(first.startTime)) - \(formatTime(last.endTime))")
            let hoursBeforeBed = bedTime.timeIntervalSince(last.endTime) / 3600
            print("[MealWindows] Hours before bed: \(String(format: "%.1f", hoursBeforeBed))")
        }
        
        return windows
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getMealName(for index: Int, total: Int) -> String {
        switch index {
        case 0:
            return "Breakfast"
        case total - 1:
            return "Dinner"
        default:
            return "Meal \(index + 1)"
        }
    }
    
    private func getMealNotes(for index: Int, total: Int) -> String {
        switch index {
        case 0:
            return "High protein to kickstart metabolism"
        case total - 1:
            return "Light and nutrient-dense for recovery"
        default:
            return "Balanced macros for sustained energy"
        }
    }
    
    private func calculateMacros(_ coordinator: NutriSyncOnboardingViewModel) async -> OnboardingMacroTargets {
        let calories = calculateDailyCalories(coordinator)

        // Use user's chosen macro profile or get recommended profile for goal
        let macroProfile: MacroProfile = {
            // First, check if user customized their macros
            if let customProfile = coordinator.macroProfile {
                return customProfile
            }

            // Otherwise, get recommended profile based on goal
            let goal: UserGoals.Goal = switch coordinator.goal.lowercased() {
                case let g where g.contains("lose") || g.contains("weight loss"): .loseWeight
                case let g where g.contains("build") || g.contains("muscle"): .buildMuscle
                case let g where g.contains("performance"): .improvePerformance
                case let g where g.contains("sleep"): .betterSleep
                case let g where g.contains("maintain"): .maintainWeight
                default: .overallHealth
            }

            return MacroCalculationService.getProfile(for: goal)
        }()

        let macros = macroProfile.calculateGrams(calories: calories)

        return OnboardingMacroTargets(
            calories: calories,
            protein: macros.protein,
            carbs: macros.carbs,
            fat: macros.fat
        )
    }
    
    private func calculateDailyCalories(_ coordinator: NutriSyncOnboardingViewModel) -> Int {
        // Calculate TDEE using Mifflin-St Jeor equation
        let weight = coordinator.weight
        let height = coordinator.height
        let age = coordinator.age
        let isMale = coordinator.gender == "Male"
        
        // BMR calculation
        let bmr: Double
        if isMale {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
        
        // Use the coordinator's pre-calculated TDEE instead of recalculating
        // This ensures consistency with what was shown in the expenditure screen
        let tdee = Int(coordinator.tdee ?? bmr * 1.5)

        // Adjust for goal using user's specified rate (weightLossRate)
        // Convert lbs/week to calories/day: 1 lb = 3500 calories, divide by 7 days
        if let weeklyRate = coordinator.weightLossRate {
            let dailyAdjustment = Int((weeklyRate * 3500) / 7)

            switch coordinator.goal.lowercased() {
            case let goal where goal.contains("lose") || goal.contains("weight loss"):
                return tdee - dailyAdjustment // Deficit for weight loss
            case let goal where goal.contains("gain") || goal.contains("muscle") || goal.contains("build"):
                return tdee + dailyAdjustment // Surplus for weight/muscle gain
            case let goal where goal.contains("performance"):
                return tdee + (dailyAdjustment / 2) // Small surplus for performance
            default:
                return tdee
            }
        } else {
            // Fallback to fixed adjustments if rate wasn't specified
            switch coordinator.goal.lowercased() {
            case let goal where goal.contains("lose") || goal.contains("weight loss"):
                return tdee - 500
            case let goal where goal.contains("gain") || goal.contains("muscle") || goal.contains("build"):
                return tdee + 250
            case let goal where goal.contains("performance"):
                return tdee + 100
            default:
                return tdee
            }
        }
    }
    
    private func generateInsights(_ coordinator: NutriSyncOnboardingViewModel) async -> [String] {
        var insights: [String] = []
        
        // Parse eating window
        let windowHours = Int(coordinator.eatingWindow.components(separatedBy: " ").first ?? "10") ?? 10
        
        // Generate personalized insights
        insights.append("Your optimal eating window: \(windowHours) hours")
        
        if coordinator.exerciseFrequency != "Never" {
            insights.append("Pre-workout meal: 90 min before for energy")
            insights.append("Post-workout window: High protein priority")
        }
        
        insights.append("Last meal: 3 hours before bed for better sleep")
        
        return insights
    }
    
    private func createProgram(_ coordinator: NutriSyncOnboardingViewModel) async -> PersonalizedProgram {
        let tdee = calculateTDEE(coordinator)
        let bmr = calculateBMR(coordinator)
        let target = calculateDailyCalories(coordinator)
        
        let timeline: String = {
            switch coordinator.goal {
            case "Lose Weight": return "12 weeks"
            case "Build Muscle": return "16 weeks"
            case "Improve Performance": return "8 weeks"
            default: return "12 weeks"
            }
        }()
        
        return PersonalizedProgram(
            userId: "", // Will be set when user creates account
            createdAt: Date(),
            goal: coordinator.goal,
            tdee: tdee,
            bmr: bmr,
            targetCalories: target,
            deficit: tdee - target,
            timeline: timeline
        )
    }
    
    private func calculateBMR(_ coordinator: NutriSyncOnboardingViewModel) -> Int {
        let weight = coordinator.weight
        let height = coordinator.height
        let age = coordinator.age
        let isMale = coordinator.gender == "Male"
        
        let bmr: Double
        if isMale {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        } else {
            bmr = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
        
        return Int(bmr)
    }
    
    private func calculateTDEE(_ coordinator: NutriSyncOnboardingViewModel) -> Int {
        // Use the coordinator's pre-calculated TDEE for consistency
        if let tdee = coordinator.tdee {
            return Int(tdee)
        }

        // Fallback calculation if TDEE wasn't calculated yet
        let bmr = Double(calculateBMR(coordinator))

        let activityFactor: Double = {
            switch coordinator.dailyActivity.lowercased() {
            case let level where level.contains("sedentary"): return 1.2
            case let level where level.contains("lightly active"): return 1.375
            case let level where level.contains("moderately active"): return 1.55
            case let level where level.contains("very active"): return 1.725
            case let level where level.contains("extremely active"): return 1.9
            default: return 1.5
            }
        }()

        return Int(bmr * activityFactor)
    }
    
}
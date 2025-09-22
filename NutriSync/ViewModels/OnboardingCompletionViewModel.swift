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
        
        // Parse eating window (e.g., "10 hours")
        let windowHours = Int(coordinator.eatingWindow.components(separatedBy: " ").first ?? "10") ?? 10
        
        // Parse meal frequency
        let mealCount = coordinator.mealFrequency == "2 meals" ? 2 : 
                       coordinator.mealFrequency == "3 meals" ? 3 : 
                       coordinator.mealFrequency == "4 meals" ? 4 : 3
        
        // Calculate window distribution
        let calendar = Calendar.current
        let wakeTime = coordinator.wakeTime
        let firstMealTime = calendar.date(byAdding: .hour, value: 1, to: wakeTime) ?? wakeTime
        
        let mealInterval = TimeInterval(windowHours * 3600) / TimeInterval(mealCount)
        
        for i in 0..<mealCount {
            let startTime = Date(timeInterval: mealInterval * Double(i), since: firstMealTime)
            let endTime = Date(timeInterval: 3600, since: startTime) // 1 hour window
            
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
        }
        
        return windows
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
        
        // Calculate protein based on goal and weight
        let weightInLbs = coordinator.weight * 2.20462
        let proteinPerLb: Double = {
            switch coordinator.goal {
            case "Build Muscle": return 1.0
            case "Improve Performance": return 0.9
            case "Lose Weight": return 0.8
            default: return 0.85
            }
        }()
        let protein = Int(weightInLbs * proteinPerLb)
        
        // Calculate fat (25-30% of calories)
        let fatCalories = Int(Double(calories) * 0.28)
        let fat = fatCalories / 9
        
        // Calculate carbs (remaining calories)
        let proteinCalories = protein * 4
        let remainingCalories = calories - proteinCalories - fatCalories
        let carbs = remainingCalories / 4
        
        return OnboardingMacroTargets(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
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
        
        // Activity factor
        let activityFactor: Double = {
            switch coordinator.dailyActivity {
            case "Low Active": return 1.375
            case "Active": return 1.55
            case "Very Active": return 1.725
            default: return 1.5
            }
        }()
        
        let tdee = Int(bmr * activityFactor)
        
        // Adjust for goal
        switch coordinator.goal {
        case "Lose Weight":
            return tdee - 550 // ~1 lb/week deficit
        case "Build Muscle":
            return tdee + 300 // Moderate surplus
        case "Improve Performance":
            return tdee + 100 // Slight surplus
        default:
            return tdee
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
        let bmr = Double(calculateBMR(coordinator))
        
        let activityFactor: Double = {
            switch coordinator.dailyActivity {
            case "Low Active": return 1.375
            case "Active": return 1.55
            case "Very Active": return 1.725
            default: return 1.5
            }
        }()
        
        return Int(bmr * activityFactor)
    }
    
}
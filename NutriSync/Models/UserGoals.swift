//
//  UserGoals.swift
//  NutriSync
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// MARK: - User Goals Model

struct UserGoals: Codable {
    var primaryGoal: Goal
    var activityLevel: ActivityLevel
    var dailyCalories: Int?
    var dailyProtein: Int?
    var dailyCarbs: Int?
    var dailyFat: Int?
    var targetWeight: Double?
    var timeline: Int? // weeks

    // NEW: Specific goals with priority ranking
    var rankedSpecificGoals: [RankedGoal]?

    // NEW: Goal-specific preferences (only for rank 1-2)
    var sleepPreferences: SleepOptimizationPreferences?
    var energyPreferences: EnergyManagementPreferences?
    var musclePreferences: MuscleGainPreferences?
    var performancePreferences: PerformancePreferences?
    var metabolicPreferences: MetabolicHealthPreferences?

    enum Goal: String, CaseIterable, Codable {
        case loseWeight = "Weight Loss"
        case buildMuscle = "Build Muscle"
        case maintainWeight = "Maintain Weight"
        case improvePerformance = "Performance"
        case betterSleep = "Better Sleep"
        case overallHealth = "Overall Health"
    }

    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case athlete = "Athlete"

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .lightlyActive: return 1.375
            case .moderatelyActive: return 1.55
            case .veryActive: return 1.725
            case .athlete: return 1.9
            }
        }
    }

    // COMPUTED PROPERTIES
    var topPriorityGoal: SpecificGoal? {
        rankedSpecificGoals?.first?.goal
    }

    var hasMultipleGoals: Bool {
        (rankedSpecificGoals?.count ?? 0) > 1
    }

    func priorityRank(for goal: SpecificGoal) -> Int? {
        rankedSpecificGoals?.firstIndex(where: { $0.goal == goal })
    }

    // Default goals for new users
    static let defaultGoals = UserGoals(
        primaryGoal: .overallHealth,
        activityLevel: .moderatelyActive,
        dailyCalories: 2000,
        dailyProtein: 150,
        dailyCarbs: 250,
        dailyFat: 67,
        targetWeight: nil,
        timeline: nil,
        rankedSpecificGoals: nil,
        sleepPreferences: nil,
        energyPreferences: nil,
        musclePreferences: nil,
        performancePreferences: nil,
        metabolicPreferences: nil
    )
}

// MARK: - Ranked Goal & Specific Goals

/// Ranked goal wrapper - tracks priority order
struct RankedGoal: Codable, Identifiable, Hashable {
    let id: UUID
    let goal: SpecificGoal
    var rank: Int  // 0 = highest priority

    init(goal: SpecificGoal, rank: Int) {
        self.id = UUID()
        self.goal = goal
        self.rank = rank
    }
}

/// Specific nutrition goals
enum SpecificGoal: String, CaseIterable, Codable, Identifiable, Hashable {
    case weightManagement = "Weight Management"
    case muscleGain = "Build Muscle & Recover"
    case steadyEnergy = "Steady Energy Levels"
    case betterSleep = "Better Sleep Quality"
    case athleticPerformance = "Athletic Performance"
    case metabolicHealth = "Metabolic Health"

    var id: String { rawValue }

    // SF Symbol icon names (professional, no emojis)
    var icon: String {
        switch self {
        case .weightManagement: return "figure.cooldown"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .steadyEnergy: return "bolt.fill"
        case .betterSleep: return "moon.stars.fill"
        case .athleticPerformance: return "figure.run"
        case .metabolicHealth: return "heart.text.square.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .weightManagement: return "Reach and maintain your target weight"
        case .muscleGain: return "Optimize protein timing and recovery windows"
        case .steadyEnergy: return "Avoid crashes and stay energized all day"
        case .betterSleep: return "Optimize meal timing for better rest"
        case .athleticPerformance: return "Fuel your workouts effectively"
        case .metabolicHealth: return "Support blood sugar and metabolic function"
        }
    }

    var primaryWindowPurposes: [MealWindow.WindowPurpose] {
        switch self {
        case .weightManagement: return [.sustainedEnergy, .metabolicBoost]
        case .muscleGain: return [.recovery, .postWorkout]
        case .steadyEnergy: return [.sustainedEnergy, .focusBoost]
        case .betterSleep: return [.sleepOptimization]
        case .athleticPerformance: return [.preWorkout, .postWorkout]
        case .metabolicHealth: return [.metabolicBoost]
        }
    }
}

// MARK: - Preference Structures

/// Sleep optimization preferences (for Rank 1-2 only)
struct SleepOptimizationPreferences: Codable, Hashable {
    var typicalBedtime: Date  // Time component only
    var hoursBeforeBed: Int  // 2, 3, or 4 hours
    var avoidLateCarbs: Bool
    var sleepQualitySensitivity: String  // "Low", "Medium", "High"

    static let defaultForRank3Plus = SleepOptimizationPreferences(
        typicalBedtime: Date.from(hour: 22, minute: 0),  // 10 PM default
        hoursBeforeBed: 3,
        avoidLateCarbs: true,
        sleepQualitySensitivity: "Medium"
    )
}

/// Energy management preferences (for Rank 1-2 only)
struct EnergyManagementPreferences: Codable, Hashable {
    var crashTimes: [CrashTime]  // When user experiences crashes
    var snackingPreference: SnackingPreference  // How they prefer to handle snacking
    var caffeineSensitivity: String  // "Low", "Medium", "High"

    enum CrashTime: String, CaseIterable, Codable, Hashable {
        case midMorning = "Mid-Morning (9-11 AM)"
        case afternoon = "Afternoon (2-4 PM)"
        case evening = "Evening (6-8 PM)"
        case none = "No specific pattern"
    }

    enum SnackingPreference: String, CaseIterable, Codable, Hashable {
        case noSnacks = "No snacks - structured meals only"
        case lightSnacks = "Light snacks between meals"
        case frequentSnacks = "Frequent small snacks throughout day"

        var displayName: String {
            switch self {
            case .noSnacks: return "No Snacks"
            case .lightSnacks: return "Light Snacking"
            case .frequentSnacks: return "Frequent Snacking"
            }
        }

        var description: String {
            switch self {
            case .noSnacks: return "Prefer structured meals without snacking"
            case .lightSnacks: return "Occasional healthy snacks between meals"
            case .frequentSnacks: return "Grazing pattern with frequent small bites"
            }
        }
    }

    static let defaultForRank3Plus = EnergyManagementPreferences(
        crashTimes: [.afternoon],
        snackingPreference: .lightSnacks,
        caffeineSensitivity: "Medium"
    )
}

/// Muscle gain preferences (for Rank 1-2 only)
struct MuscleGainPreferences: Codable, Hashable {
    var trainingDaysPerWeek: Int  // 3-7
    var trainingStyle: TrainingStyle
    var proteinDistribution: String  // "Even", "Post-Workout Focus", "Maximum"
    var supplementProtein: Bool  // Do they use protein powder?

    enum TrainingStyle: String, CaseIterable, Codable, Hashable {
        case strength = "Strength Training"
        case hypertrophy = "Hypertrophy/Bodybuilding"
        case powerlifting = "Powerlifting"
        case generalFitness = "General Fitness"
    }

    static let defaultForRank3Plus = MuscleGainPreferences(
        trainingDaysPerWeek: 4,
        trainingStyle: .generalFitness,
        proteinDistribution: "Even",
        supplementProtein: false
    )
}

/// Performance preferences (for Rank 1-2 only)
struct PerformancePreferences: Codable, Hashable {
    var typicalWorkoutTime: Date  // Time component only
    var workoutDuration: Int  // Minutes (30, 45, 60, 90, 120)
    var preworkoutMealDesired: Bool
    var postworkoutMealDesired: Bool
    var workoutIntensity: String  // "Light", "Moderate", "Intense"

    static let defaultForRank3Plus = PerformancePreferences(
        typicalWorkoutTime: Date.from(hour: 17, minute: 0),  // 5 PM default
        workoutDuration: 60,
        preworkoutMealDesired: true,
        postworkoutMealDesired: true,
        workoutIntensity: "Moderate"
    )
}

/// Metabolic health preferences (for Rank 1-2 only)
struct MetabolicHealthPreferences: Codable, Hashable {
    var fastingWindowHours: Int  // 12, 14, 16, 18
    var bloodSugarConcern: Bool
    var preferLowerCarbs: Bool
    var mealTimingConsistency: String  // "Flexible", "Consistent", "Very Strict"

    static let defaultForRank3Plus = MetabolicHealthPreferences(
        fastingWindowHours: 14,
        bloodSugarConcern: false,
        preferLowerCarbs: false,
        mealTimingConsistency: "Consistent"
    )
}

// MARK: - Firestore Extensions
extension UserGoals {
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "primaryGoal": primaryGoal.rawValue,
            "activityLevel": activityLevel.rawValue
        ]
        
        if let calories = dailyCalories { data["dailyCalories"] = calories }
        if let protein = dailyProtein { data["dailyProtein"] = protein }
        if let carbs = dailyCarbs { data["dailyCarbs"] = carbs }
        if let fat = dailyFat { data["dailyFat"] = fat }
        if let weight = targetWeight { data["targetWeight"] = weight }
        if let time = timeline { data["timeline"] = time }
        
        return data
    }
    
    static func fromFirestore(_ data: [String: Any]) -> UserGoals? {
        guard let goalString = data["primaryGoal"] as? String,
              let goal = Goal(rawValue: goalString),
              let activityString = data["activityLevel"] as? String,
              let activity = ActivityLevel(rawValue: activityString) else {
            return nil
        }
        
        return UserGoals(
            primaryGoal: goal,
            activityLevel: activity,
            dailyCalories: data["dailyCalories"] as? Int,
            dailyProtein: data["dailyProtein"] as? Int,
            dailyCarbs: data["dailyCarbs"] as? Int,
            dailyFat: data["dailyFat"] as? Int,
            targetWeight: data["targetWeight"] as? Double,
            timeline: data["timeline"] as? Int
        )
    }
}

// MARK: - Legacy Nutrition Goal (for compatibility)

enum NutritionGoal: Identifiable, Codable {
    case weightLoss(targetPounds: Double, timeline: Int)
    case muscleGain(targetPounds: Double, timeline: Int)
    case maintainWeight
    case performanceFocus // Mental clarity & physical energy
    case betterSleep // Sleep quality improvement
    case overallWellbeing // Holistic health
    case athleticPerformance(sport: String)
    
    var id: String {
        switch self {
        case .weightLoss: return "weightLoss"
        case .muscleGain: return "muscleGain"
        case .maintainWeight: return "maintainWeight"
        case .performanceFocus: return "performanceFocus"
        case .betterSleep: return "betterSleep"
        case .overallWellbeing: return "overallWellbeing"
        case .athleticPerformance: return "athleticPerformance"
        }
    }
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .muscleGain: return "Muscle Gain"
        case .maintainWeight: return "Maintain Weight"
        case .performanceFocus: return "Performance Focus"
        case .betterSleep: return "Better Sleep"
        case .overallWellbeing: return "Overall Wellbeing"
        case .athleticPerformance: return "Athletic Performance"
        }
    }
    
    var icon: String {
        switch self {
        case .weightLoss: return "arrow.down.circle.fill"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .maintainWeight: return "equal.circle.fill"
        case .performanceFocus: return "brain.head.profile"
        case .betterSleep: return "moon.fill"
        case .overallWellbeing: return "heart.circle.fill"
        case .athleticPerformance: return "figure.run"
        }
    }
    
    var color: Color {
        switch self {
        case .weightLoss: return Color(red: 1.0, green: 0.4, blue: 0.4) // Coral
        case .muscleGain: return Color(red: 0.4, green: 0.4, blue: 1.0) // Blue
        case .maintainWeight: return .nutriSyncAccent
        case .performanceFocus: return Color(red: 0.0, green: 1.0, blue: 0.4) // Electric green
        case .betterSleep: return Color(red: 0.3, green: 0.2, blue: 0.7) // Deep purple
        case .overallWellbeing: return Color(red: 0.2, green: 0.8, blue: 0.8) // Teal
        case .athleticPerformance: return Color(red: 1.0, green: 0.5, blue: 0.2) // Orange
        }
    }
    
    // For generating default goals
    static var defaultExamples: [NutritionGoal] {
        [
            .weightLoss(targetPounds: 10, timeline: 8),
            .muscleGain(targetPounds: 5, timeline: 12),
            .maintainWeight,
            .performanceFocus,
            .betterSleep,
            .overallWellbeing,
            .athleticPerformance(sport: "Running")
        ]
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case type
        case targetPounds
        case timeline
        case sport
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "weightLoss":
            let targetPounds = try container.decode(Double.self, forKey: .targetPounds)
            let timeline = try container.decode(Int.self, forKey: .timeline)
            self = .weightLoss(targetPounds: targetPounds, timeline: timeline)
        case "muscleGain":
            let targetPounds = try container.decode(Double.self, forKey: .targetPounds)
            let timeline = try container.decode(Int.self, forKey: .timeline)
            self = .muscleGain(targetPounds: targetPounds, timeline: timeline)
        case "maintainWeight":
            self = .maintainWeight
        case "performanceFocus":
            self = .performanceFocus
        case "betterSleep":
            self = .betterSleep
        case "overallWellbeing":
            self = .overallWellbeing
        case "athleticPerformance":
            let sport = try container.decode(String.self, forKey: .sport)
            self = .athleticPerformance(sport: sport)
        default:
            self = .maintainWeight
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .weightLoss(let targetPounds, let timeline):
            try container.encode("weightLoss", forKey: .type)
            try container.encode(targetPounds, forKey: .targetPounds)
            try container.encode(timeline, forKey: .timeline)
        case .muscleGain(let targetPounds, let timeline):
            try container.encode("muscleGain", forKey: .type)
            try container.encode(targetPounds, forKey: .targetPounds)
            try container.encode(timeline, forKey: .timeline)
        case .maintainWeight:
            try container.encode("maintainWeight", forKey: .type)
        case .performanceFocus:
            try container.encode("performanceFocus", forKey: .type)
        case .betterSleep:
            try container.encode("betterSleep", forKey: .type)
        case .overallWellbeing:
            try container.encode("overallWellbeing", forKey: .type)
        case .athleticPerformance(let sport):
            try container.encode("athleticPerformance", forKey: .type)
            try container.encode(sport, forKey: .sport)
        }
    }
}

// MARK: - Macro Configuration
// DEPRECATED: MacroConfiguration has been replaced by MacroCalculationService
// See MacroCalculationService.swift for the new centralized macro calculation system
// This comment left for reference - the old struct has been removed
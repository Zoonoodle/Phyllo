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
    
    // Default goals for new users
    static let defaultGoals = UserGoals(
        primaryGoal: .overallHealth,
        activityLevel: .moderatelyActive,
        dailyCalories: 2000,
        dailyProtein: 150,
        dailyCarbs: 250,
        dailyFat: 67,
        targetWeight: nil,
        timeline: nil
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
struct MacroConfiguration: Codable {
    var carbPercentage: Double
    var proteinPercentage: Double
    var fatPercentage: Double
    
    // Common presets
    static let balanced = MacroConfiguration(carbPercentage: 0.40, proteinPercentage: 0.30, fatPercentage: 0.30)
    static let highProtein = MacroConfiguration(carbPercentage: 0.30, proteinPercentage: 0.40, fatPercentage: 0.30)
    static let lowCarb = MacroConfiguration(carbPercentage: 0.20, proteinPercentage: 0.35, fatPercentage: 0.45)
    static let athleteTraining = MacroConfiguration(carbPercentage: 0.50, proteinPercentage: 0.25, fatPercentage: 0.25)
    
    var totalPercentage: Double {
        carbPercentage + proteinPercentage + fatPercentage
    }
    
    // Calculate macros in grams from calorie target
    func calculateMacros(for calories: Int) -> (protein: Int, carbs: Int, fat: Int) {
        let proteinCalories = Double(calories) * proteinPercentage
        let carbCalories = Double(calories) * carbPercentage
        let fatCalories = Double(calories) * fatPercentage
        
        return (
            protein: Int(proteinCalories / 4),  // 4 calories per gram of protein
            carbs: Int(carbCalories / 4),        // 4 calories per gram of carbs
            fat: Int(fatCalories / 9)            // 9 calories per gram of fat
        )
    }
}
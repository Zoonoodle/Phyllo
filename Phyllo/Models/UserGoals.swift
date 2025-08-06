//
//  UserGoals.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import Foundation
import SwiftUI

// MARK: - Nutrition Goals

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
        case .maintainWeight: return .phylloAccent
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
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown goal type")
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

// MARK: - Supporting Types

enum WorkSchedule: String, CaseIterable {
    case traditional = "9-5 Office"
    case shiftWork = "Shift Work"
    case remote = "Remote/Flexible"
    case irregular = "Irregular Hours"
}

struct ExerciseWindow: Identifiable {
    let id = UUID()
    let dayOfWeek: Int // 1-7
    let startTime: Date
    let duration: TimeInterval
    let type: String
}

enum FastingProtocol: String, CaseIterable {
    case sixteen8 = "16:8"
    case eighteen6 = "18:6"
    case twenty4 = "20:4"
    case omad = "OMAD"
    case custom = "Custom"
}

// MARK: - Morning Check-In Data

struct MorningCheckInData: Identifiable {
    let id = UUID()
    let date: Date
    let wakeTime: Date
    let sleepQuality: Int // 1-10
    let sleepDuration: TimeInterval
    let energyLevel: Int // 1-5
    let plannedActivities: [String]
    let hungerLevel: Int // 1-5
    
    static var mockData: MorningCheckInData {
        MorningCheckInData(
            date: Date(),
            wakeTime: Calendar.current.date(bySettingHour: 6, minute: 45, second: 0, of: Date())!,
            sleepQuality: 8,
            sleepDuration: 7.5 * 3600, // 7.5 hours
            energyLevel: 4,
            plannedActivities: ["Morning Run", "Important Meeting"],
            hungerLevel: 3
        )
    }
}
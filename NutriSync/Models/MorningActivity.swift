//
//  MorningActivity.swift
//  NutriSync
//
//  Actionable activity categories for morning check-in
//

import Foundation
import SwiftUI

enum MorningActivity: String, CaseIterable, Codable {
    case workout = "Workout"
    case cardio = "Cardio"
    case weightTraining = "Weight Training"
    case work = "Work"
    case meeting = "Meeting"
    case commute = "Commute"
    case mealEvent = "Meal Event"
    case socialEvent = "Social Event"
    case travel = "Travel"
    case rest = "Rest Day"
    
    var icon: String {
        switch self {
        case .workout: return "figure.run"
        case .cardio: return "heart.fill"
        case .weightTraining: return "dumbbell.fill"
        case .work: return "laptopcomputer"
        case .meeting: return "person.3.fill"
        case .commute: return "car.fill"
        case .mealEvent: return "fork.knife"
        case .socialEvent: return "person.2.fill"
        case .travel: return "airplane"
        case .rest: return "bed.double.fill"
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .workout, .weightTraining: return 60
        case .cardio: return 30
        case .work: return 240
        case .meeting: return 60
        case .commute: return 30
        case .mealEvent: return 90
        case .socialEvent: return 120
        case .travel: return 180
        case .rest: return 0
        }
    }
    
    var color: Color {
        switch self {
        case .workout, .cardio, .weightTraining: return .orange
        case .work, .meeting: return .blue
        case .commute, .travel: return .purple
        case .mealEvent: return .green
        case .socialEvent: return .pink
        case .rest: return .gray
        }
    }
    
    var description: String {
        switch self {
        case .workout: return "General exercise session"
        case .cardio: return "Running, cycling, or cardio workout"
        case .weightTraining: return "Strength training session"
        case .work: return "Work or productive time"
        case .meeting: return "Scheduled meeting or appointment"
        case .commute: return "Travel to/from work or activities"
        case .mealEvent: return "Dining out or special meal"
        case .socialEvent: return "Time with friends or family"
        case .travel: return "Extended travel time"
        case .rest: return "Recovery or rest day"
        }
    }
}
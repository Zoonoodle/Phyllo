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
    case socialEvent = "Social Event"
    case travel = "Travel"
    case study = "Study"
    case outdoor = "Outdoor"
    case errands = "Errands"
    case selfCare = "Self Care"
    
    var icon: String {
        switch self {
        case .workout: return "figure.run"
        case .cardio: return "heart.fill"
        case .weightTraining: return "dumbbell.fill"
        case .work: return "laptopcomputer"
        case .meeting: return "person.3.fill"
        case .commute: return "car.fill"
        case .socialEvent: return "person.2.fill"
        case .travel: return "airplane"
        case .study: return "book.fill"
        case .outdoor: return "sun.max.fill"
        case .errands: return "checklist"
        case .selfCare: return "heart.circle.fill"
        }
    }
    
    var defaultDuration: Int {
        switch self {
        case .workout, .weightTraining: return 60
        case .cardio: return 30
        case .work: return 240
        case .meeting: return 60
        case .commute: return 30
        case .socialEvent: return 120
        case .travel: return 180
        case .study: return 90
        case .outdoor: return 60
        case .errands: return 45
        case .selfCare: return 60
        }
    }
    
    var color: Color {
        switch self {
        case .workout, .cardio, .weightTraining: return .orange
        case .work, .meeting: return .blue
        case .commute, .travel: return .purple
        case .socialEvent: return .pink
        case .study: return .indigo
        case .outdoor: return .yellow
        case .errands: return .teal
        case .selfCare: return .mint
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
        case .socialEvent: return "Time with friends or family"
        case .travel: return "Extended travel time"
        case .study: return "Study or learning session"
        case .outdoor: return "Outdoor activities"
        case .errands: return "Shopping or tasks"
        case .selfCare: return "Personal wellness time"
        }
    }
}
//
//  MorningCheckInViewModel.swift
//  NutriSync
//
//  Observable ViewModel for morning check-in flow
//

import SwiftUI
import Observation

@Observable
class MorningCheckInViewModel {
    // Navigation state
    var currentStep: Int = 0
    var totalSteps: Int = 6
    
    // User data (replacing @State variables from old MorningCheckInView)
    var wakeTime: Date = Date()
    var plannedBedtime: Date = {
        // Default to 10 PM tonight
        let calendar = Calendar.current
        let tonight = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .hour, value: 22, to: tonight) ?? Date()
    }()
    var sleepQuality: Int = 5
    var energyLevel: Int = 5
    var hungerLevel: Int = 5
    var plannedActivities: [String] = []
    var windowPreference: MorningCheckIn.WindowPreference = .auto
    var hasRestrictions: Bool = false
    var restrictions: [String] = []
    var dayFocus: Set<MorningCheckIn.DayFocus> = []
    
    // New properties for improved UI
    var selectedActivities: [MorningActivity] = []
    var activityDurations: [MorningActivity: Int] = [:]
    
    // Navigation methods
    func nextStep() {
        if currentStep < totalSteps - 1 {
            currentStep += 1
        }
    }
    
    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }
    
    func canGoNext() -> Bool {
        switch currentStep {
        case 0: // Wake time
            return true // Wake time is already set to a default
        case 1: // Sleep quality
            return true // Slider has default value
        case 2: // Energy level
            return true // Slider has default value
        case 3: // Hunger level
            return true // Slider has default value
        case 4: // Activities
            return true // Activities are optional
        case 5: // Planned bedtime
            return true // Bedtime has default value
        default:
            return true
        }
    }
    
    func completeCheckIn() {
        saveCheckIn()
        // Move to the next step after the last one to trigger dismissal
        currentStep += 1
    }
    
    func saveCheckIn() {
        // Convert selectedActivities to plannedActivities strings
        plannedActivities = selectedActivities.map { $0.rawValue }
        
        // Convert selectedActivities to dayFocus if needed (compatibility)
        // Map activity types to closest matching focus categories
        dayFocus = Set(selectedActivities.compactMap { activity in
            switch activity {
            case .work, .meeting: return MorningCheckIn.DayFocus.work
            case .selfCare: return MorningCheckIn.DayFocus.relaxing
            case .socialEvent: return MorningCheckIn.DayFocus.friends
            default: return nil
            }
        })
        
        let checkIn = MorningCheckIn(
            date: Date(),
            wakeTime: wakeTime,
            plannedBedtime: plannedBedtime,
            sleepQuality: sleepQuality,
            energyLevel: energyLevel,
            hungerLevel: hungerLevel,
            dayFocus: dayFocus,
            morningMood: nil, // Can be added later if needed
            plannedActivities: plannedActivities,
            windowPreference: windowPreference,
            hasRestrictions: hasRestrictions,
            restrictions: restrictions
        )
        
        // Save to CheckInManager
        CheckInManager.shared.saveMorningCheckIn(checkIn)
        
        // Window generation will be triggered by the view that handles check-in completion
        // The AIScheduleView already handles this when the sheet dismisses
    }
}
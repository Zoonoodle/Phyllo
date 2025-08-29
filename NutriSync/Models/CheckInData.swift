//
//  CheckInData.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import Foundation

// MARK: - Check-In Types
enum CheckInType {
    case morning
    case postMeal(mealId: String)
}

// Type alias for backward compatibility
typealias MorningCheckInData = MorningCheckIn

// MARK: - Morning Check-In Data
struct MorningCheckIn: Identifiable, Codable {
    let id: UUID
    let date: Date
    let wakeTime: Date
    let plannedBedtime: Date  // When user plans to go to bed tonight
    let sleepQuality: Int  // 0-10 scale
    let energyLevel: Int   // 0-10 scale
    let hungerLevel: Int   // 0-10 scale
    let dayFocus: Set<DayFocus>
    let morningMood: MoodLevel?
    let plannedActivities: [String]  // e.g., ["Workout 5:30pm-6:30pm", "Lunch meeting 12:30pm-1:30pm"]
    let windowPreference: WindowPreference
    let hasRestrictions: Bool
    let restrictions: [String]  // e.g., ["vegan", "gluten-free"]
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        date: Date,
        wakeTime: Date,
        plannedBedtime: Date,
        sleepQuality: Int,
        energyLevel: Int,
        hungerLevel: Int,
        dayFocus: Set<DayFocus>,
        morningMood: MoodLevel?,
        plannedActivities: [String],
        windowPreference: WindowPreference,
        hasRestrictions: Bool,
        restrictions: [String],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.wakeTime = wakeTime
        self.plannedBedtime = plannedBedtime
        self.sleepQuality = sleepQuality
        self.energyLevel = energyLevel
        self.hungerLevel = hungerLevel
        self.dayFocus = dayFocus
        self.morningMood = morningMood
        self.plannedActivities = plannedActivities
        self.windowPreference = windowPreference
        self.hasRestrictions = hasRestrictions
        self.restrictions = restrictions
        self.timestamp = timestamp
    }
    
    enum SleepQuality: Int, CaseIterable, Codable {
        case terrible = 1
        case poor = 2  
        case fair = 3
        case good = 4
        case excellent = 5
        
        var label: String {
            switch self {
            case .terrible: return "Terrible"
            case .poor: return "Poor"
            case .fair: return "Fair"
            case .good: return "Good"
            case .excellent: return "Excellent"
            }
        }
        
        var emoji: String {
            switch self {
            case .terrible: return "😫"
            case .poor: return "😞"
            case .fair: return "😐"
            case .good: return "😊"
            case .excellent: return "😄"
            }
        }
    }
    
    enum WindowPreference: Codable, Equatable {
        case specific(Int)  // Specific number of windows
        case range(Int, Int)  // Min and max windows
        case auto  // Let AI decide
        
        var description: String {
            switch self {
            case .specific(let count):
                return "\(count) windows"
            case .range(let min, let max):
                return "\(min)-\(max) windows"
            case .auto:
                return "Auto-decide"
            }
        }
        
        // For JSON encoding
        var jsonValue: String {
            switch self {
            case .specific(let count):
                return String(count)
            case .range(let min, let max):
                return "\(min)-\(max)"
            case .auto:
                return "auto"
            }
        }
    }
    
    enum DayFocus: String, CaseIterable, Codable {
        case work = "Work"
        case relaxing = "Relaxing"
        case family = "Family"
        case friends = "Friends"
        case date = "Date"
        case pets = "Pets"
        case fitness = "Fitness"
        case selfCare = "Self-care"
        case partner = "Partner"
        case reading = "Reading"
        case learning = "Learning"
        case travel = "Travel"
        
        var icon: String {
            switch self {
            case .work: return "briefcase.fill"
            case .relaxing: return "sun.max.fill"
            case .family: return "house.fill"
            case .friends: return "person.2.fill"
            case .date: return "heart.fill"
            case .pets: return "pawprint.fill"
            case .fitness: return "figure.run"
            case .selfCare: return "crown.fill"
            case .partner: return "person.fill"
            case .reading: return "book.fill"
            case .learning: return "graduationcap.fill"
            case .travel: return "airplane"
            }
        }
    }
    
    // Helper struct for activity input
    struct PlannedActivity: Identifiable {
        let id = UUID()
        var type: ActivityType
        var startTime: String  // "3:00pm"
        var endTime: String    // "4:00pm"
        
        enum ActivityType: String, CaseIterable {
            case workout = "Workout"
            case cardio = "Cardio"
            case weights = "Weight Training"
            case meal = "Meal Event"
            case meeting = "Meeting"
            case social = "Social Event"
            case work = "Work Event"
            case travel = "Travel"
            
            var icon: String {
                switch self {
                case .workout, .cardio, .weights: return "figure.run"
                case .meal: return "fork.knife"
                case .meeting, .work: return "briefcase.fill"
                case .social: return "person.2.fill"
                case .travel: return "car.fill"
                }
            }
        }
        
        // Convert to string format for AI
        var formattedString: String {
            "\(type.rawValue) \(startTime)-\(endTime)"
        }
    }
}

// MARK: - Post-Meal Check-In Data
struct PostMealCheckIn: Identifiable, Codable {
    let id: UUID
    let mealId: String
    let mealName: String
    let energyLevel: EnergyLevel
    let fullnessLevel: FullnessLevel
    let moodFocus: MoodLevel
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        mealId: String,
        mealName: String,
        energyLevel: EnergyLevel,
        fullnessLevel: FullnessLevel,
        moodFocus: MoodLevel,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.mealId = mealId
        self.mealName = mealName
        self.energyLevel = energyLevel
        self.fullnessLevel = fullnessLevel
        self.moodFocus = moodFocus
        self.timestamp = timestamp
    }
    
    enum EnergyLevel: Int, CaseIterable, Codable {
        case crashed = 1
        case low = 2
        case moderate = 3
        case good = 4
        case energized = 5
        
        var label: String {
            switch self {
            case .crashed: return "Crashed"
            case .low: return "Low"
            case .moderate: return "Moderate"
            case .good: return "Good"
            case .energized: return "Energized"
            }
        }
        
        var color: String {
            switch self {
            case .crashed: return "FF3B30" // Red
            case .low: return "FF9500" // Orange
            case .moderate: return "FFCC00" // Yellow
            case .good: return "34C759" // Green
            case .energized: return "00C7BE" // Teal
            }
        }
    }
    
    enum FullnessLevel: Int, CaseIterable, Codable {
        case stillHungry = 1
        case satisfied = 2
        case full = 3
        case tooFull = 4
        case stuffed = 5
        
        var label: String {
            switch self {
            case .stillHungry: return "Still Hungry"
            case .satisfied: return "Satisfied"
            case .full: return "Full"
            case .tooFull: return "Too Full"
            case .stuffed: return "Stuffed"
            }
        }
        
        var icon: String {
            switch self {
            case .stillHungry: return "circle.dashed"
            case .satisfied: return "circle.lefthalf.filled"
            case .full: return "circle.fill"
            case .tooFull: return "circle.inset.filled"
            case .stuffed: return "circle.hexagongrid.fill"
            }
        }
    }
}

// MARK: - Shared Mood Level
enum MoodLevel: Int, CaseIterable, Codable {
    case veryLow = 1
    case low = 2
    case neutral = 3
    case good = 4
    case excellent = 5
    
    var label: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .neutral: return "Neutral"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryLow: return "😔"
        case .low: return "😕"
        case .neutral: return "😐"
        case .good: return "😊"
        case .excellent: return "😄"
        }
    }
}

// MARK: - Check-In Manager
class CheckInManager: ObservableObject {
    @Published var morningCheckIns: [MorningCheckIn] = []
    @Published var postMealCheckIns: [PostMealCheckIn] = []
    @Published var hasCompletedMorningCheckIn = false
    @Published var pendingPostMealCheckIns: [String] = [] // Meal IDs waiting for check-in
    
    static let shared = CheckInManager()
    
    private init() {
        // Check if morning check-in is needed
        checkMorningCheckInStatus()
    }
    
    func checkMorningCheckInStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        hasCompletedMorningCheckIn = morningCheckIns.contains { checkIn in
            calendar.isDate(checkIn.date, inSameDayAs: today)
        }
    }
    
    func saveMorningCheckIn(_ checkIn: MorningCheckIn) {
        morningCheckIns.append(checkIn)
        hasCompletedMorningCheckIn = true
    }
    
    func savePostMealCheckIn(_ checkIn: PostMealCheckIn) {
        postMealCheckIns.append(checkIn)
        pendingPostMealCheckIns.removeAll { $0 == checkIn.mealId }
    }
    
    func addPendingMealCheckIn(mealId: String) {
        pendingPostMealCheckIns.append(mealId)
    }
    
    func getLatestMorningCheckIn() -> MorningCheckIn? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return morningCheckIns.first { checkIn in
            calendar.isDate(checkIn.date, inSameDayAs: today)
        }
    }
}
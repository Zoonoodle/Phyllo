//
//  DailySyncData.swift
//  NutriSync
//
//  Simplified daily sync model replacing morning check-in
//

import Foundation

// MARK: - Sync Context
enum SyncContext: String, Codable {
    case earlyMorning    // 4am-8am: Fresh start
    case lateMorning     // 8am-11am: May have eaten breakfast
    case midday          // 11am-2pm: Likely eaten 1-2 meals
    case afternoon       // 2pm-5pm: Multiple meals consumed
    case evening         // 5pm-9pm: Most meals done
    case lateNight       // 9pm-4am: Night shift or irregular schedule
    
    var greeting: String {
        switch self {
        case .earlyMorning:
            return "Good morning! Let's plan your nutrition"
        case .lateMorning:
            return "Good morning! Let's sync your day"
        case .midday:
            return "Let's optimize your remaining meals"
        case .afternoon:
            return "Good afternoon! Let's adjust your nutrition"
        case .evening:
            return "Good evening! Let's plan your night"
        case .lateNight:
            return "Working late? Let's adapt your schedule"
        }
    }
    
    var shouldAskAboutEatenMeals: Bool {
        self != .earlyMorning
    }
    
    static func current() -> SyncContext {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<8: return .earlyMorning
        case 8..<11: return .lateMorning
        case 11..<14: return .midday
        case 14..<17: return .afternoon
        case 17..<21: return .evening
        default: return .lateNight
        }
    }
}

// MARK: - Simplified Energy Level
enum SimpleEnergyLevel: String, CaseIterable, Codable {
    case low = "Need fuel"
    case good = "Feeling good"
    case high = "High energy"
    
    var emoji: String {
        switch self {
        case .low: return "😴"
        case .good: return "😊"
        case .high: return "⚡"
        }
    }
    
    var nutritionImpact: String {
        switch self {
        case .low:
            return "Schedule quick energy boost"
        case .good:
            return "Maintain steady nutrition"
        case .high:
            return "Focus on sustained energy"
        }
    }
}

// MARK: - Quick Meal for Already Eaten
struct QuickMeal: Identifiable, Codable {
    let id: UUID
    let name: String
    let time: Date
    let estimatedCalories: Int?
    let photoPath: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        time: Date,
        estimatedCalories: Int? = nil,
        photoPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.time = time
        self.estimatedCalories = estimatedCalories
        self.photoPath = photoPath
    }
}

// MARK: - Time Range for Schedule
struct TimeRange: Codable {
    let start: Date
    let end: Date
    
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
    
    var formattedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Special Event
struct SpecialEvent: Codable {
    let type: EventType
    let time: Date
    let duration: TimeInterval
    
    enum EventType: String, Codable {
        case workout = "Workout"
        case meeting = "Meeting"  
        case social = "Social"
        case travel = "Travel"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .workout: return "figure.run"
            case .meeting: return "briefcase.fill"
            case .social: return "person.2.fill"
            case .travel: return "airplane"
            case .other: return "calendar"
            }
        }
    }
}

// MARK: - Main Daily Sync Model
struct DailySync: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let syncContext: SyncContext
    let alreadyConsumed: [QuickMeal]
    let workSchedule: TimeRange?
    let workoutTime: Date?
    let currentEnergy: SimpleEnergyLevel
    let specialEvents: [SpecialEvent]
    
    // Computed properties
    var needsWindowRegeneration: Bool {
        !alreadyConsumed.isEmpty || syncContext != .earlyMorning
    }
    
    var remainingMealsCount: Int {
        // Calculate based on time of day and what's already eaten
        let totalPlanned = 5 // Default
        return max(0, totalPlanned - alreadyConsumed.count)
    }
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        syncContext: SyncContext = .current(),
        alreadyConsumed: [QuickMeal] = [],
        workSchedule: TimeRange? = nil,
        workoutTime: Date? = nil,
        currentEnergy: SimpleEnergyLevel = .good,
        specialEvents: [SpecialEvent] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.syncContext = syncContext
        self.alreadyConsumed = alreadyConsumed
        self.workSchedule = workSchedule
        self.workoutTime = workoutTime
        self.currentEnergy = currentEnergy
        self.specialEvents = specialEvents
    }
    
    // Convert to Firebase format
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "timestamp": timestamp,
            "syncContext": syncContext.rawValue,
            "currentEnergy": currentEnergy.rawValue,
            "alreadyConsumed": alreadyConsumed.map { meal in
                [
                    "id": meal.id.uuidString,
                    "name": meal.name,
                    "time": meal.time,
                    "estimatedCalories": meal.estimatedCalories as Any
                ]
            }
        ]
        
        if let workSchedule = workSchedule {
            data["workSchedule"] = [
                "start": workSchedule.start,
                "end": workSchedule.end
            ]
        }
        
        if let workoutTime = workoutTime {
            data["workoutTime"] = workoutTime
        }
        
        if !specialEvents.isEmpty {
            data["specialEvents"] = specialEvents.map { event in
                [
                    "type": event.type.rawValue,
                    "time": event.time,
                    "duration": event.duration
                ]
            }
        }
        
        return data
    }
    
    // Create from Firebase
    static func fromFirestore(_ data: [String: Any]) -> DailySync? {
        guard let id = data["id"] as? String,
              let timestamp = data["timestamp"] as? Date,
              let syncContextRaw = data["syncContext"] as? String,
              let syncContext = SyncContext(rawValue: syncContextRaw),
              let energyRaw = data["currentEnergy"] as? String,
              let currentEnergy = SimpleEnergyLevel(rawValue: energyRaw) else {
            return nil
        }
        
        // Parse already consumed meals
        let alreadyConsumed: [QuickMeal]
        if let mealsData = data["alreadyConsumed"] as? [[String: Any]] {
            alreadyConsumed = mealsData.compactMap { mealData in
                guard let mealId = mealData["id"] as? String,
                      let name = mealData["name"] as? String,
                      let time = mealData["time"] as? Date else {
                    return nil
                }
                return QuickMeal(
                    id: UUID(uuidString: mealId) ?? UUID(),
                    name: name,
                    time: time,
                    estimatedCalories: mealData["estimatedCalories"] as? Int
                )
            }
        } else {
            alreadyConsumed = []
        }
        
        // Parse work schedule
        let workSchedule: TimeRange?
        if let scheduleData = data["workSchedule"] as? [String: Any],
           let start = scheduleData["start"] as? Date,
           let end = scheduleData["end"] as? Date {
            workSchedule = TimeRange(start: start, end: end)
        } else {
            workSchedule = nil
        }
        
        // Parse special events
        let specialEvents: [SpecialEvent]
        if let eventsData = data["specialEvents"] as? [[String: Any]] {
            specialEvents = eventsData.compactMap { eventData in
                guard let typeRaw = eventData["type"] as? String,
                      let type = SpecialEvent.EventType(rawValue: typeRaw),
                      let time = eventData["time"] as? Date,
                      let duration = eventData["duration"] as? TimeInterval else {
                    return nil
                }
                return SpecialEvent(type: type, time: time, duration: duration)
            }
        } else {
            specialEvents = []
        }
        
        return DailySync(
            id: UUID(uuidString: id) ?? UUID(),
            timestamp: timestamp,
            syncContext: syncContext,
            alreadyConsumed: alreadyConsumed,
            workSchedule: workSchedule,
            workoutTime: data["workoutTime"] as? Date,
            currentEnergy: currentEnergy,
            specialEvents: specialEvents
        )
    }
}

// MARK: - Daily Sync Manager
class DailySyncManager: ObservableObject {
    @Published var todaySync: DailySync?
    @Published var hasCompletedDailySync = false
    @Published var pendingQuickMeals: [QuickMeal] = []
    
    static let shared = DailySyncManager()
    
    private init() {
        checkDailySyncStatus()
    }
    
    func checkDailySyncStatus() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if we have a sync for today
        if let sync = todaySync {
            hasCompletedDailySync = calendar.isDate(sync.timestamp, inSameDayAs: today)
        } else {
            hasCompletedDailySync = false
        }
    }
    
    func saveDailySync(_ sync: DailySync) {
        todaySync = sync
        hasCompletedDailySync = true
        
        // Convert quick meals to logged meals if needed
        if !sync.alreadyConsumed.isEmpty {
            // TODO: Process quick meals into proper logged meals
        }
    }
    
    func shouldPromptForSync() -> Bool {
        // Don't prompt if already completed today
        if hasCompletedDailySync { return false }
        
        // Smart timing based on context
        let context = SyncContext.current()
        switch context {
        case .earlyMorning, .lateMorning:
            return true // Always prompt in morning
        case .midday, .afternoon:
            // Only if no meals logged today
            return pendingQuickMeals.isEmpty
        case .evening, .lateNight:
            // Optional, user-initiated
            return false
        }
    }
    
    func getLatestSync() -> DailySync? {
        todaySync
    }
}
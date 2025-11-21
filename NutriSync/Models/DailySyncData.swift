//
//  DailySyncData.swift
//  NutriSync
//
//  Simplified daily sync model replacing morning check-in
//

import Foundation
import FirebaseFirestore

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
    
    var icon: String {
        switch self {
        case .earlyMorning:
            return "sun.max.fill"
        case .lateMorning:
            return "sun.haze.fill"
        case .midday:
            return "sun.max"
        case .afternoon:
            return "sun.haze"
        case .evening:
            return "moon.stars.fill"
        case .lateNight:
            return "moon.zzz.fill"
        }
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
    let specialEvents: [SpecialEvent]
    let dailyContextDescription: String?  // NEW: Free-form voice/text daily context

    // Computed properties
    // Note: Remaining meal count is determined by user's mealsPerDay preference in profile
    // and current alreadyConsumed count, calculated dynamically during window generation

    // NEW: Infer energy level from context for backward compatibility
    var inferredEnergyLevel: SimpleEnergyLevel? {
        guard let context = dailyContextDescription?.lowercased() else { return nil }

        // Parse context for energy indicators
        if context.contains("tired") || context.contains("exhausted") ||
           context.contains("low energy") || context.contains("drained") ||
           context.contains("didn't sleep") || context.contains("sleepy") {
            return .low
        } else if context.contains("great") || context.contains("high energy") ||
                  context.contains("energized") || context.contains("pumped") ||
                  context.contains("feeling good") || context.contains("refreshed") {
            return .high
        } else {
            return .good  // Default/neutral
        }
    }

    var hasDetailedContext: Bool {
        guard let context = dailyContextDescription else { return false }
        return !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        syncContext: SyncContext = .current(),
        alreadyConsumed: [QuickMeal] = [],
        workSchedule: TimeRange? = nil,
        workoutTime: Date? = nil,
        specialEvents: [SpecialEvent] = [],
        dailyContextDescription: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.syncContext = syncContext
        self.alreadyConsumed = alreadyConsumed
        self.workSchedule = workSchedule
        self.workoutTime = workoutTime
        self.specialEvents = specialEvents
        self.dailyContextDescription = dailyContextDescription
    }
    
    // Convert to Firebase format
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "timestamp": timestamp,
            "syncContext": syncContext.rawValue,
            "alreadyConsumed": alreadyConsumed.map { meal in
                [
                    "id": meal.id.uuidString,
                    "name": meal.name,
                    "time": meal.time,
                    "estimatedCalories": meal.estimatedCalories as Any
                ]
            }
        ]

        // NEW: Add daily context if present
        if let context = dailyContextDescription {
            data["dailyContextDescription"] = context
        }

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
              let syncContextRaw = data["syncContext"] as? String,
              let syncContext = SyncContext(rawValue: syncContextRaw) else {
            return nil
        }

        // Handle Firestore Timestamp conversion
        guard let timestamp = (data["timestamp"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["timestamp"] as? Date) else {
            return nil
        }

        // NEW: Parse daily context description
        let dailyContextDescription = data["dailyContextDescription"] as? String
        
        // Parse already consumed meals
        let alreadyConsumed: [QuickMeal]
        if let mealsData = data["alreadyConsumed"] as? [[String: Any]] {
            alreadyConsumed = mealsData.compactMap { mealData in
                guard let mealId = mealData["id"] as? String,
                      let name = mealData["name"] as? String else {
                    return nil
                }
                // Handle Firestore Timestamp for meal time
                guard let time = (mealData["time"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (mealData["time"] as? Date) else {
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
        if let scheduleData = data["workSchedule"] as? [String: Any] {
            // Handle Firestore Timestamp for schedule times
            let start = (scheduleData["start"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (scheduleData["start"] as? Date)
            let end = (scheduleData["end"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (scheduleData["end"] as? Date)
            if let start = start, let end = end {
                workSchedule = TimeRange(start: start, end: end)
            } else {
                workSchedule = nil
            }
        } else {
            workSchedule = nil
        }
        
        // Parse special events
        let specialEvents: [SpecialEvent]
        if let eventsData = data["specialEvents"] as? [[String: Any]] {
            specialEvents = eventsData.compactMap { eventData in
                guard let typeRaw = eventData["type"] as? String,
                      let type = SpecialEvent.EventType(rawValue: typeRaw),
                      let duration = eventData["duration"] as? TimeInterval else {
                    return nil
                }
                // Handle Firestore Timestamp for event time
                guard let time = (eventData["time"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (eventData["time"] as? Date) else {
                    return nil
                }
                return SpecialEvent(type: type, time: time, duration: duration)
            }
        } else {
            specialEvents = []
        }
        
        // Parse workout time with Firestore Timestamp handling
        let workoutTime = (data["workoutTime"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["workoutTime"] as? Date)

        return DailySync(
            id: UUID(uuidString: id) ?? UUID(),
            timestamp: timestamp,
            syncContext: syncContext,
            alreadyConsumed: alreadyConsumed,
            workSchedule: workSchedule,
            workoutTime: workoutTime,
            specialEvents: specialEvents,
            dailyContextDescription: dailyContextDescription  // NEW
        )
    }
}

// MARK: - Daily Sync Manager
@MainActor
class DailySyncManager: ObservableObject {
    @Published var todaySync: DailySync?
    @Published var hasCompletedDailySync = false
    @Published var pendingQuickMeals: [QuickMeal] = []

    // Check-in frequency configuration
    private let checkInFrequencyDays = 4  // Trigger once every 4 days
    @Published var lastCheckInDate: Date?

    static let shared = DailySyncManager()

    private init() {
        loadLastCheckInDate()
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

    private func loadLastCheckInDate() {
        // Load last check-in date from UserDefaults
        if let timestamp = UserDefaults.standard.object(forKey: "lastCheckInDate") as? Date {
            lastCheckInDate = timestamp
        }
    }

    private func saveLastCheckInDate(_ date: Date) {
        lastCheckInDate = date
        UserDefaults.standard.set(date, forKey: "lastCheckInDate")
    }

    private func daysSinceLastCheckIn() -> Int {
        guard let lastDate = lastCheckInDate else {
            return checkInFrequencyDays // Return frequency days if never checked in
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: lastDate, to: Date())
        return components.day ?? checkInFrequencyDays
    }
    
    func saveDailySync(_ sync: DailySync) async {
        print("📝 DailySyncManager.saveDailySync called - timestamp: \(sync.timestamp)")
        todaySync = sync
        hasCompletedDailySync = true

        // Save last check-in date (for 4-day frequency tracking)
        saveLastCheckInDate(sync.timestamp)

        // Save to Firebase
        do {
            print("💾 Attempting to save Daily Sync to Firebase...")
            try await FirebaseDataProvider.shared.saveDailySync(sync)
            print("✅ Daily Sync saved successfully")

            // ALWAYS trigger window generation after Daily Sync
            // The whole point of Daily Sync is to generate personalized windows for the day
            print("🔄 Generating windows after Daily Sync completion...")
            await triggerWindowGeneration(for: sync)

            // Process already consumed meals through AI analysis
            if !sync.alreadyConsumed.isEmpty {
                print("🍽️ Processing \(sync.alreadyConsumed.count) already consumed meals...")
                await processAlreadyConsumedMeals(sync.alreadyConsumed)
            }
        } catch {
            print("❌ Failed to save daily sync: \(error)")
        }
    }
    
    private func triggerWindowGeneration(for sync: DailySync) async {
        print("🔄 Triggering window generation based on user preferences and daily context")
        
        do {
            // Get user profile
            guard let profile = try await FirebaseDataProvider.shared.getUserProfile() else {
                print("❌ No user profile found")
                return
            }
            
            // Convert DailySync to MorningCheckInData for compatibility
            // TODO: Update window generation to use DailySync directly
            let checkInData = convertToCheckInData(sync)
            
            // Generate windows through Firebase
            let windows = try await FirebaseDataProvider.shared.generateDailyWindows(
                for: Date(),
                profile: profile,
                checkIn: checkInData
            )
            
            print("✅ Generated \(windows.count) windows after Daily Sync")
            
            // Schedule notifications
            await NotificationManager.shared.scheduleWindowNotifications(for: windows)
            
        } catch {
            print("❌ Failed to generate windows: \(error)")
        }
    }
    
    private func convertToCheckInData(_ sync: DailySync) -> MorningCheckInData? {
        // Convert DailySync to MorningCheckInData for backward compatibility
        // This is temporary until we update the window generation to use DailySync directly
        
        // Calculate wake time based on work schedule or default to 7am
        let calendar = Calendar.current
        var wakeComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        wakeComponents.hour = 7
        wakeComponents.minute = 0
        let wakeTime = calendar.date(from: wakeComponents) ?? Date()
        
        // Calculate bedtime based on work schedule or default to 11pm
        var bedComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        bedComponents.hour = 23
        bedComponents.minute = 0
        let plannedBedtime = calendar.date(from: bedComponents) ?? Date().addingTimeInterval(16 * 3600)
        
        // Convert energy level (inferred from context if available)
        let energyLevel: Int
        if let inferredEnergy = sync.inferredEnergyLevel {
            energyLevel = inferredEnergy == .high ? 8 : (inferredEnergy == .good ? 6 : 4)
        } else {
            energyLevel = 6  // Default to "good"
        }
        
        // Build activities list from sync data
        var activities: [String] = []
        if let workout = sync.workoutTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            activities.append("Workout \(formatter.string(from: workout))")
        }
        if let work = sync.workSchedule {
            activities.append("Work \(work.formattedString)")
        }
        
        return MorningCheckIn(
            date: Date(),
            wakeTime: wakeTime,
            plannedBedtime: plannedBedtime,
            sleepQuality: 7, // Default to good
            energyLevel: energyLevel,
            hungerLevel: 5, // Default to moderate
            dayFocus: [], // Empty for now
            morningMood: nil,
            plannedActivities: activities,
            windowPreference: .auto, // Let AI decide based on sync data
            hasRestrictions: false,
            restrictions: []
        )
    }

    /// Process already consumed meals from DailySync through AI analysis
    /// This converts QuickMeal entries into fully analyzed LoggedMeal objects
    private func processAlreadyConsumedMeals(_ meals: [QuickMeal]) async {
        guard !meals.isEmpty else { return }

        print("🍽️ Processing \(meals.count) already consumed meals from Daily Sync...")

        // Process each meal through the meal capture service
        // This handles: AI analysis, window assignment, saving to Firebase, and redistribution
        for (index, quickMeal) in meals.enumerated() {
            do {
                print("📍 [\(index + 1)/\(meals.count)] Analyzing: '\(quickMeal.name)' eaten at \(quickMeal.time)")

                // Use MealCaptureService which handles the complete meal analysis pipeline:
                // 1. Finds closest window based on meal time
                // 2. Creates AnalyzingMeal and saves to Firebase
                // 3. Triggers AI analysis (Gemini) with the meal description
                // 4. Completes analysis and saves as LoggedMeal
                // 5. Automatically triggers redistribution if needed
                _ = try await MealCaptureService.shared.startMealAnalysis(
                    image: nil,                    // No photo for quick-added meals
                    voiceTranscript: quickMeal.name, // Use meal name as description for AI
                    barcode: nil,                  // No barcode
                    timestamp: quickMeal.time      // Use the time they actually ate it
                )

                print("✅ [\(index + 1)/\(meals.count)] Successfully started analysis for: '\(quickMeal.name)'")

            } catch {
                print("❌ [\(index + 1)/\(meals.count)] Failed to process meal '\(quickMeal.name)': \(error.localizedDescription)")
                // Continue with next meal even if one fails
                // This ensures partial success rather than all-or-nothing
            }
        }

        print("✅ Finished processing \(meals.count) already consumed meals")
        print("   Note: Meals are analyzed in background and will appear as they complete")
    }

    func shouldPromptForSync() -> Bool {
        // Check if 4 days have passed since last check-in
        let daysSince = daysSinceLastCheckIn()
        if daysSince < checkInFrequencyDays {
            print("⏳ Only \(daysSince) days since last check-in. Waiting for \(checkInFrequencyDays) days.")
            return false
        }

        // Don't prompt if already completed today
        if hasCompletedDailySync { return false }

        // Smart timing based on context
        let context = SyncContext.current()
        switch context {
        case .earlyMorning, .lateMorning:
            return true // Always prompt in morning (if 4 days passed)
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
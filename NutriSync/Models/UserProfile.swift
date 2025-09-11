//
//  UserProfile.swift
//  NutriSync
//
//  Created on 8/6/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Work Schedule
enum WorkSchedule: String, CaseIterable, Codable {
    case standard = "standard"        // 9-5
    case earlyMorning = "earlyMorning" // Before 9am start
    case evening = "evening"          // After 5pm start
    case night = "night"              // Night shift
    case flexible = "flexible"        // Variable schedule
    case remote = "remote"            // Work from home
    
    var displayName: String {
        switch self {
        case .standard: return "Standard (9-5)"
        case .earlyMorning: return "Early Morning"
        case .evening: return "Evening"
        case .night: return "Night Shift"
        case .flexible: return "Flexible"
        case .remote: return "Remote/WFH"
        }
    }
    
    var defaultMealHours: (earliest: Int, latest: Int) {
        switch self {
        case .standard, .remote:
            return (earliest: 6, latest: 20)  // 6am - 8pm
        case .earlyMorning:
            return (earliest: 5, latest: 19)  // 5am - 7pm
        case .evening:
            return (earliest: 10, latest: 23)  // 10am - 11pm
        case .night:
            return (earliest: 18, latest: 8)   // 6pm - 8am (next day)
        case .flexible:
            return (earliest: 6, latest: 21)  // 6am - 9pm
        }
    }
}

// MARK: - Fasting Protocol
enum FastingProtocol: String, CaseIterable, Codable {
    case none = "none"
    case sixteen8 = "16:8"            // 16 hour fast, 8 hour eating
    case eighteen6 = "18:6"           // 18 hour fast, 6 hour eating
    case twenty4 = "20:4"             // 20 hour fast, 4 hour eating
    case omad = "OMAD"                // One meal a day
    case fiveTwoDay = "5:2"           // 5 days normal, 2 days restricted
    case eatStopEat = "eatStopEat"    // 24 hour fasts 1-2 times per week
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .none: return "No Fasting"
        case .sixteen8: return "16:8"
        case .eighteen6: return "18:6"
        case .twenty4: return "20:4"
        case .omad: return "OMAD"
        case .fiveTwoDay: return "5:2 Diet"
        case .eatStopEat: return "Eat-Stop-Eat"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Activity Level
enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary = "sedentary"
    case lightlyActive = "lightlyActive"
    case moderatelyActive = "moderatelyActive"
    case veryActive = "veryActive"
    case extremelyActive = "extremelyActive"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }
}


// MARK: - User Profile
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var gender: Gender
    var height: Double // in inches
    var weight: Double // in pounds
    var activityLevel: ActivityLevel
    var primaryGoal: NutritionGoal
    var dietaryPreferences: [String]
    var dietaryRestrictions: [String]
    var dailyCalorieTarget: Int
    var dailyProteinTarget: Int
    var dailyCarbTarget: Int
    var dailyFatTarget: Int
    var preferredMealTimes: [String]
    var micronutrientPriorities: [String]
    
    // Schedule preferences for dynamic timeline
    var earliestMealHour: Int?      // Earliest hour user typically eats
    var latestMealHour: Int?        // Latest hour user typically eats
    var workSchedule: WorkSchedule = .standard
    var typicalWakeTime: Date?
    var typicalSleepTime: Date?
    var fastingProtocol: FastingProtocol = .none
    var lastBulkLogDate: Date?      // Track when we last prompted for missed meals
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        gender: Gender,
        height: Double,
        weight: Double,
        activityLevel: ActivityLevel,
        primaryGoal: NutritionGoal,
        dietaryPreferences: [String],
        dietaryRestrictions: [String],
        dailyCalorieTarget: Int,
        dailyProteinTarget: Int,
        dailyCarbTarget: Int,
        dailyFatTarget: Int,
        preferredMealTimes: [String],
        micronutrientPriorities: [String],
        earliestMealHour: Int? = nil,
        latestMealHour: Int? = nil,
        workSchedule: WorkSchedule = .standard,
        typicalWakeTime: Date? = nil,
        typicalSleepTime: Date? = nil,
        fastingProtocol: FastingProtocol = .none,
        lastBulkLogDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.activityLevel = activityLevel
        self.primaryGoal = primaryGoal
        self.dietaryPreferences = dietaryPreferences
        self.dietaryRestrictions = dietaryRestrictions
        self.dailyCalorieTarget = dailyCalorieTarget
        self.dailyProteinTarget = dailyProteinTarget
        self.dailyCarbTarget = dailyCarbTarget
        self.dailyFatTarget = dailyFatTarget
        self.preferredMealTimes = preferredMealTimes
        self.micronutrientPriorities = micronutrientPriorities
        self.earliestMealHour = earliestMealHour
        self.latestMealHour = latestMealHour
        self.workSchedule = workSchedule
        self.typicalWakeTime = typicalWakeTime
        self.typicalSleepTime = typicalSleepTime
        self.fastingProtocol = fastingProtocol
        self.lastBulkLogDate = lastBulkLogDate
    }
    
    // MARK: - Firestore Conversion
    private func primaryGoalForFirestore() -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(primaryGoal)
            let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return dict ?? [:]
        } catch {
            return [:]
        }
    }
    
    private static func nutritionGoalFromFirestore(_ data: [String: Any]) -> NutritionGoal? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(NutritionGoal.self, from: jsonData)
        } catch {
            return nil
        }
    }
    
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "age": age,
            "gender": gender.rawValue,
            "height": height,
            "weight": weight,
            "activityLevel": activityLevel.rawValue,
            "primaryGoal": primaryGoalForFirestore(),
            "dietaryPreferences": dietaryPreferences,
            "dietaryRestrictions": dietaryRestrictions,
            "dailyCalorieTarget": dailyCalorieTarget,
            "dailyProteinTarget": dailyProteinTarget,
            "dailyCarbTarget": dailyCarbTarget,
            "dailyFatTarget": dailyFatTarget,
            "preferredMealTimes": preferredMealTimes,
            "micronutrientPriorities": micronutrientPriorities,
            "workSchedule": workSchedule.rawValue,
            "fastingProtocol": fastingProtocol.rawValue
        ]
        
        // Only add optional values if they're not nil
        if let earliestMealHour = earliestMealHour {
            data["earliestMealHour"] = earliestMealHour
        }
        if let latestMealHour = latestMealHour {
            data["latestMealHour"] = latestMealHour
        }
        
        // Safely convert dates to Firebase Timestamps
        // Firebase Timestamps require dates after year 1 AD (Unix epoch - 62135596800 seconds)
        if let typicalWakeTime = typicalWakeTime,
           typicalWakeTime.timeIntervalSince1970 > -62135596800 {
            data["typicalWakeTime"] = Timestamp(date: typicalWakeTime)
        }
        if let typicalSleepTime = typicalSleepTime,
           typicalSleepTime.timeIntervalSince1970 > -62135596800 {
            data["typicalSleepTime"] = Timestamp(date: typicalSleepTime)
        }
        if let lastBulkLogDate = lastBulkLogDate,
           lastBulkLogDate.timeIntervalSince1970 > -62135596800 {
            data["lastBulkLogDate"] = Timestamp(date: lastBulkLogDate)
        }
        
        return data
    }
    
    static func fromFirestore(_ data: [String: Any]) -> UserProfile? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let age = data["age"] as? Int,
              let genderString = data["gender"] as? String,
              let gender = Gender(rawValue: genderString),
              let height = data["height"] as? Double,
              let weight = data["weight"] as? Double,
              let activityLevelString = data["activityLevel"] as? String,
              let activityLevel = ActivityLevel(rawValue: activityLevelString),
              let primaryGoalData = data["primaryGoal"] as? [String: Any],
              let primaryGoal = nutritionGoalFromFirestore(primaryGoalData),
              let dailyCalorieTarget = data["dailyCalorieTarget"] as? Int,
              let dailyProteinTarget = data["dailyProteinTarget"] as? Int,
              let dailyCarbTarget = data["dailyCarbTarget"] as? Int,
              let dailyFatTarget = data["dailyFatTarget"] as? Int else {
            return nil
        }
        
        let dietaryPreferences = data["dietaryPreferences"] as? [String] ?? []
        let dietaryRestrictions = data["dietaryRestrictions"] as? [String] ?? []
        let preferredMealTimes = data["preferredMealTimes"] as? [String] ?? []
        let micronutrientPriorities = data["micronutrientPriorities"] as? [String] ?? []
        
        // Parse new schedule fields
        let earliestMealHour = data["earliestMealHour"] as? Int
        let latestMealHour = data["latestMealHour"] as? Int
        let workSchedule = WorkSchedule(rawValue: data["workSchedule"] as? String ?? "standard") ?? .standard
        let fastingProtocol = FastingProtocol(rawValue: data["fastingProtocol"] as? String ?? "none") ?? .none
        
        // Handle Date fields
        let typicalWakeTime = (data["typicalWakeTime"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["typicalWakeTime"] as? Date)
        let typicalSleepTime = (data["typicalSleepTime"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["typicalSleepTime"] as? Date)
        let lastBulkLogDate = (data["lastBulkLogDate"] as? FirebaseFirestore.Timestamp)?.dateValue() ?? (data["lastBulkLogDate"] as? Date)
        
        var profile = UserProfile(
            id: id,
            name: name,
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            activityLevel: activityLevel,
            primaryGoal: primaryGoal,
            dietaryPreferences: dietaryPreferences,
            dietaryRestrictions: dietaryRestrictions,
            dailyCalorieTarget: dailyCalorieTarget,
            dailyProteinTarget: dailyProteinTarget,
            dailyCarbTarget: dailyCarbTarget,
            dailyFatTarget: dailyFatTarget,
            preferredMealTimes: preferredMealTimes,
            micronutrientPriorities: micronutrientPriorities
        )
        
        // Set optional schedule fields
        profile.earliestMealHour = earliestMealHour
        profile.latestMealHour = latestMealHour
        profile.workSchedule = workSchedule
        profile.typicalWakeTime = typicalWakeTime
        profile.typicalSleepTime = typicalSleepTime
        profile.fastingProtocol = fastingProtocol
        profile.lastBulkLogDate = lastBulkLogDate
        
        return profile
    }
    
    // MARK: - Default Profile
    static var defaultProfile: UserProfile {
        UserProfile(
            id: UUID(),
            name: "User",
            age: 30,
            gender: .male,
            height: 70, // 5'10"
            weight: 170,
            activityLevel: .moderatelyActive,
            primaryGoal: .performanceFocus,
            dietaryPreferences: [],
            dietaryRestrictions: [],
            dailyCalorieTarget: 2400,
            dailyProteinTarget: 110,
            dailyCarbTarget: 270,
            dailyFatTarget: 85,
            preferredMealTimes: [],
            micronutrientPriorities: ["Vitamin D", "Magnesium", "Omega-3"]
        )
    }
}
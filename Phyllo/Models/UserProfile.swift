//
//  UserProfile.swift
//  Phyllo
//
//  Created on 8/6/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Activity Level
enum ActivityLevel: String, CaseIterable, Codable {
    case sedentary = "sedentary"
    case lightlyActive = "lightlyActive"
    case moderate = "moderate"
    case veryActive = "veryActive"
    case extremelyActive = "extremelyActive"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderate: return "Moderately Active"
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
        return [
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
            "earliestMealHour": earliestMealHour as Any,
            "latestMealHour": latestMealHour as Any,
            "workSchedule": workSchedule.rawValue,
            "typicalWakeTime": typicalWakeTime as Any,
            "typicalSleepTime": typicalSleepTime as Any,
            "fastingProtocol": fastingProtocol.rawValue,
            "lastBulkLogDate": lastBulkLogDate as Any
        ]
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
            activityLevel: .moderate,
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
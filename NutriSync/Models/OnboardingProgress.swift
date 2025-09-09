//
//  OnboardingProgress.swift
//  NutriSync
//
//  Tracks user progress through onboarding
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct OnboardingProgress: Codable {
    let userId: String
    var currentSection: Int
    var currentStep: Int
    var completedSections: Set<Int>
    
    // Section 1: Basic Info
    var name: String?
    var age: Int?
    var biologicalSex: Gender?
    var heightCM: Double?
    var weightKG: Double?
    var activityLevel: UserGoals.ActivityLevel?
    var bodyFatPercentage: Double?
    
    // Section 2: Goals
    var primaryGoal: UserGoals.Goal?
    var targetWeightKG: Double?
    var weeklyWeightChangeKG: Double?
    var minimumCalories: Int?
    
    // Section 3: Lifestyle
    var wakeTime: Date?
    var bedTime: Date?
    var mealsPerDay: Int?
    var eatingWindowHours: Int?
    var breakfastPreference: Bool?
    var dietaryRestrictions: [String]?
    var dietType: String?
    
    // Section 4: Training
    var workoutsPerWeek: Int?
    var workoutDays: [Int]?
    var workoutTimes: [Date]?
    var trainingType: String?
    
    // Section 5: Optimization
    var energyPatterns: [String: Int]?
    var scheduleFlexibility: Int?
    var notificationSettings: NotificationSettings?
    
    // Metadata
    var lastUpdated: Date
    var isComplete: Bool
    
    init(userId: String = Auth.auth().currentUser?.uid ?? "",
         currentSection: Int = 1,
         currentStep: Int = 1,
         completedSections: Set<Int> = [],
         lastUpdated: Date = Date(),
         isComplete: Bool = false) {
        self.userId = userId
        self.currentSection = currentSection
        self.currentStep = currentStep
        self.completedSections = completedSections
        self.lastUpdated = lastUpdated
        self.isComplete = isComplete
    }
    
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "currentSection": currentSection,
            "currentStep": currentStep,
            "completedSections": Array(completedSections),
            "lastUpdated": Timestamp(date: lastUpdated),
            "isComplete": isComplete
        ]
        
        // Add optional fields if present
        if let name = name { dict["name"] = name }
        if let age = age { dict["age"] = age }
        if let biologicalSex = biologicalSex { dict["biologicalSex"] = biologicalSex.rawValue }
        if let heightCM = heightCM { dict["heightCM"] = heightCM }
        if let weightKG = weightKG { dict["weightKG"] = weightKG }
        if let activityLevel = activityLevel { dict["activityLevel"] = activityLevel.rawValue }
        if let bodyFatPercentage = bodyFatPercentage { dict["bodyFatPercentage"] = bodyFatPercentage }
        
        if let primaryGoal = primaryGoal { dict["primaryGoal"] = primaryGoal.rawValue }
        if let targetWeightKG = targetWeightKG { dict["targetWeightKG"] = targetWeightKG }
        if let weeklyWeightChangeKG = weeklyWeightChangeKG { dict["weeklyWeightChangeKG"] = weeklyWeightChangeKG }
        if let minimumCalories = minimumCalories { dict["minimumCalories"] = minimumCalories }
        
        if let wakeTime = wakeTime { dict["wakeTime"] = Timestamp(date: wakeTime) }
        if let bedTime = bedTime { dict["bedTime"] = Timestamp(date: bedTime) }
        if let mealsPerDay = mealsPerDay { dict["mealsPerDay"] = mealsPerDay }
        if let eatingWindowHours = eatingWindowHours { dict["eatingWindowHours"] = eatingWindowHours }
        if let breakfastPreference = breakfastPreference { dict["breakfastPreference"] = breakfastPreference }
        if let dietaryRestrictions = dietaryRestrictions { dict["dietaryRestrictions"] = dietaryRestrictions }
        if let dietType = dietType { dict["dietType"] = dietType }
        
        if let workoutsPerWeek = workoutsPerWeek { dict["workoutsPerWeek"] = workoutsPerWeek }
        if let workoutDays = workoutDays { dict["workoutDays"] = workoutDays }
        if let workoutTimes = workoutTimes { 
            dict["workoutTimes"] = workoutTimes.map { Timestamp(date: $0) }
        }
        if let trainingType = trainingType { dict["trainingType"] = trainingType }
        
        if let energyPatterns = energyPatterns { dict["energyPatterns"] = energyPatterns }
        if let scheduleFlexibility = scheduleFlexibility { dict["scheduleFlexibility"] = scheduleFlexibility }
        // NotificationSettings would need custom serialization
        
        return dict
    }
    
    static func fromFirestore(_ data: [String: Any]) -> OnboardingProgress? {
        guard let userId = data["userId"] as? String else { return nil }
        
        var progress = OnboardingProgress(userId: userId)
        
        if let currentSection = data["currentSection"] as? Int {
            progress.currentSection = currentSection
        }
        if let currentStep = data["currentStep"] as? Int {
            progress.currentStep = currentStep
        }
        if let completedSections = data["completedSections"] as? [Int] {
            progress.completedSections = Set(completedSections)
        }
        if let lastUpdated = data["lastUpdated"] as? Timestamp {
            progress.lastUpdated = lastUpdated.dateValue()
        }
        if let isComplete = data["isComplete"] as? Bool {
            progress.isComplete = isComplete
        }
        
        // Parse optional fields
        progress.name = data["name"] as? String
        progress.age = data["age"] as? Int
        if let sexString = data["biologicalSex"] as? String {
            progress.biologicalSex = Gender(rawValue: sexString)
        }
        progress.heightCM = data["heightCM"] as? Double
        progress.weightKG = data["weightKG"] as? Double
        if let activityString = data["activityLevel"] as? String {
            progress.activityLevel = UserGoals.ActivityLevel(rawValue: activityString)
        }
        progress.bodyFatPercentage = data["bodyFatPercentage"] as? Double
        
        if let goalString = data["primaryGoal"] as? String {
            progress.primaryGoal = UserGoals.Goal(rawValue: goalString)
        }
        progress.targetWeightKG = data["targetWeightKG"] as? Double
        progress.weeklyWeightChangeKG = data["weeklyWeightChangeKG"] as? Double
        progress.minimumCalories = data["minimumCalories"] as? Int
        
        if let wakeTime = data["wakeTime"] as? Timestamp {
            progress.wakeTime = wakeTime.dateValue()
        }
        if let bedTime = data["bedTime"] as? Timestamp {
            progress.bedTime = bedTime.dateValue()
        }
        progress.mealsPerDay = data["mealsPerDay"] as? Int
        progress.eatingWindowHours = data["eatingWindowHours"] as? Int
        progress.breakfastPreference = data["breakfastPreference"] as? Bool
        progress.dietaryRestrictions = data["dietaryRestrictions"] as? [String]
        progress.dietType = data["dietType"] as? String
        
        progress.workoutsPerWeek = data["workoutsPerWeek"] as? Int
        progress.workoutDays = data["workoutDays"] as? [Int]
        if let workoutTimes = data["workoutTimes"] as? [Timestamp] {
            progress.workoutTimes = workoutTimes.map { $0.dateValue() }
        }
        progress.trainingType = data["trainingType"] as? String
        
        progress.energyPatterns = data["energyPatterns"] as? [String: Int]
        progress.scheduleFlexibility = data["scheduleFlexibility"] as? Int
        
        return progress
    }
}

// Notification settings from onboarding
struct NotificationSettings: Codable {
    var windowStart: Bool = true
    var windowEnd: Bool = true
    var checkInReminders: Bool = true
    var minutesBefore: Int = 15
    
    init(windowStart: Bool = true, windowEnd: Bool = true, checkInReminders: Bool = true, minutesBefore: Int = 15) {
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.checkInReminders = checkInReminders
        self.minutesBefore = minutesBefore
    }
}
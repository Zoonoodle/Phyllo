//
//  OnboardingCoordinator.swift
//  Phyllo
//
//  Isolated onboarding flow coordinator
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case goals
    // Split profile into focused atomic steps
    case age
    case height
    case weight
    case gender
    case activity
    case schedule
    case dietary
    case challenges
    case habits
    case nudges
    case preview
    case permissions
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to Phyllo"
        case .goals: return "Your Goals"
        case .age: return "Your Age"
        case .height: return "Your Height"
        case .weight: return "Your Weight"
        case .gender: return "Your Gender"
        case .activity: return "Activity Level"
        case .schedule: return "Daily Schedule"
        case .dietary: return "Dietary Preferences"
        case .challenges: return "Current Challenges"
        case .habits: return "Your Habits"
        case .nudges: return "Nudges & Devices"
        case .preview: return "Your Plan"
        case .permissions: return "Enable Features"
        }
    }
    
    var progress: Double {
        Double(self.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
    
    var canSkip: Bool {
        switch self {
        case .welcome, .goals, .age, .height, .weight, .gender, .schedule: return false
        case .activity, .dietary, .challenges, .habits, .nudges, .preview, .permissions: return true
        }
    }
}

@Observable
class OnboardingCoordinator {
    var currentStep: OnboardingStep = .welcome
    var onboardingData = OnboardingData()
    var isCompleted = false
    var shouldShowOnboarding = true
    
    // Navigation
    func next() {
        guard let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = nextStep
        }
    }
    
    func previous() {
        guard currentStep.rawValue > 0 else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .welcome
        }
    }
    
    func skip() {
        guard currentStep.canSkip else { return }
        next()
    }
    
    func goToStep(_ step: OnboardingStep) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = step
        }
    }
    
    private func completeOnboarding() {
        // Persist and bootstrap plan generation
        saveOnboardingData()
        
        withAnimation(.easeOut(duration: 0.3)) {
            isCompleted = true
            shouldShowOnboarding = false
        }
    }
    
    private func saveOnboardingData() {
        // Build a UserProfile and generate initial windows
        guard
            let age = onboardingData.age,
            let gender = onboardingData.gender,
            let height = onboardingData.height,
            let weight = onboardingData.currentWeight,
            let primaryGoal = onboardingData.primaryGoal
        else {
            print("⚠️ Incomplete onboarding data; skipping persistence")
            return
        }
        
        // Calculate nutrition targets using the goal calculator
        let goalType: GoalCalculationService.GoalType
        switch primaryGoal {
        case .weightLoss(let targetPounds, let timeline):
            goalType = .specificWeightTarget(
                currentWeight: weight,
                targetWeight: max(80, weight - targetPounds),
                weeks: timeline
            )
        case .muscleGain(let targetPounds, let timeline):
            goalType = .specificWeightTarget(
                currentWeight: weight,
                targetWeight: weight + targetPounds,
                weeks: timeline
            )
        case .maintainWeight:
            goalType = .performanceOptimization(currentWeight: weight, activityLevel: onboardingData.activityLevel)
        case .performanceFocus, .betterSleep:
            goalType = .performanceOptimization(currentWeight: weight, activityLevel: onboardingData.activityLevel)
        case .overallWellbeing:
            goalType = .performanceOptimization(currentWeight: weight, activityLevel: onboardingData.activityLevel)
        case .athleticPerformance:
            goalType = .bodyComposition(currentWeight: weight, currentBF: nil, targetBF: nil, focus: .leanMuscleGain)
        }
        
        let targets = GoalCalculationService.shared.calculateTargets(
            for: goalType,
            height: height,
            age: age,
            gender: gender,
            activityLevel: onboardingData.activityLevel
        )
        
        // Build profile
        let profile = UserProfile(
            id: UUID(),
            name: onboardingData.name.isEmpty ? "User" : onboardingData.name,
            age: age,
            gender: gender,
            height: height,
            weight: weight,
            activityLevel: onboardingData.activityLevel,
            primaryGoal: primaryGoal,
            dietaryPreferences: [onboardingData.eatingStyle.rawValue],
            dietaryRestrictions: Array(onboardingData.dietaryRestrictions.map { $0.rawValue }),
            dailyCalorieTarget: targets.dailyCalories,
            dailyProteinTarget: targets.protein,
            dailyCarbTarget: targets.carbs,
            dailyFatTarget: targets.fat,
            preferredMealTimes: {
                var times: [String] = []
                if let first = onboardingData.firstMealTime { times.append(first.formatted(date: .omitted, time: .shortened)) }
                if let last = onboardingData.lastMealTime { times.append(last.formatted(date: .omitted, time: .shortened)) }
                return times
            }(),
            micronutrientPriorities: []
        )
        
        Task {
            // Persist profile if provider supports it
            try? await DataSourceProvider.shared.provider.saveUserProfile(profile)
            
            // Seed notification preferences from onboarding choices
            await MainActor.run {
                var prefs = NotificationManager.shared.notificationPreferences
                switch onboardingData.notificationPreference {
                case .all:
                    prefs.windowReminders = true
                    prefs.checkInReminders = true
                    prefs.goalProgress = true
                    prefs.coachingTips = true
                case .important:
                    prefs.windowReminders = true
                    prefs.checkInReminders = true
                    prefs.goalProgress = false
                    prefs.coachingTips = false
                case .minimal:
                    prefs.windowReminders = true
                    prefs.checkInReminders = false
                    prefs.goalProgress = false
                    prefs.coachingTips = false
                case .none:
                    prefs.windowReminders = false
                    prefs.checkInReminders = false
                    prefs.goalProgress = false
                    prefs.coachingTips = false
                }
                prefs.quietHoursEnabled = onboardingData.quietHoursEnabled
                prefs.quietHoursStart = onboardingData.quietHoursStart
                prefs.quietHoursEnd = onboardingData.quietHoursEnd
                NotificationManager.shared.notificationPreferences = prefs
                NotificationManager.shared.savePreferences()
            }

            // Generate initial windows
            let checkIn: MorningCheckInData? = {
                guard let wake = onboardingData.wakeTime else { return nil }
                return MorningCheckInData(
                    date: Date(),
                    wakeTime: wake,
                    sleepQuality: 7,
                    sleepDuration: 7.5 * 3600,
                    energyLevel: onboardingData.energyBaseline,
                    plannedActivities: [],
                    hungerLevel: 3
                )
            }()
            
            let windows = try? await DataSourceProvider.shared.provider.generateDailyWindows(
                for: Date(),
                profile: profile,
                checkIn: checkIn
            )
            
            if let windows = windows {
                await NotificationManager.shared.scheduleWindowNotifications(for: windows)
            }
        }
    }
    
    // Validation
    func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .goals:
            return onboardingData.primaryGoal != nil
        case .age:
            return onboardingData.age != nil
        case .height:
            return onboardingData.height != nil
        case .weight:
            return onboardingData.currentWeight != nil
        case .gender:
            return onboardingData.gender != nil
        case .schedule:
            return onboardingData.wakeTime != nil &&
                   onboardingData.sleepTime != nil &&
                   onboardingData.workSchedule != nil
        case .activity:
            return true
        case .dietary:
            return true
        case .challenges:
            return true
        case .habits:
            return true
        case .nudges:
            return true
        case .preview:
            return true
        case .permissions:
            return true
        }
    }
}

// MARK: - Onboarding Data Model

struct OnboardingData {
    // Goals
    var primaryGoal: NutritionGoal?
    var secondaryGoals: [NutritionGoal] = []
    
    // Profile
    var name: String = ""
    var email: String = ""
    var age: Int?
    var gender: Gender?
    var height: Double? // in inches
    var currentWeight: Double? // in pounds
    var targetWeight: Double? // in pounds
    
    // Schedule
    var wakeTime: Date?
    var sleepTime: Date?
    var workSchedule: WorkSchedule?
    
    // Activity
    var activityLevel: ActivityLevel = .moderate
    var workoutDays: Set<Int> = [] // 0 = Sunday, 6 = Saturday
    var preferredWorkoutTime: WorkoutTime?
    
    // Dietary
    var dietaryRestrictions: Set<DietaryRestriction> = []
    var allergies: Set<FoodAllergy> = []
    var eatingStyle: EatingStyle = .noRestrictions
    
    // Challenges
    var currentChallenges: Set<HealthChallenge> = []
    
    // Preferences
    var preferredMealCount: Int = 3
    var fastingProtocol: FastingProtocol?
    var notificationPreference: NotificationPreference = .important
    // Quiet hours seed from schedule
    var quietHoursEnabled: Bool = true
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 7
    
    // Habits Baseline
    var firstMealTime: Date?
    var lastMealTime: Date?
    var waterIntake: WaterIntake = .moderate
    var caffeineLevel: CaffeineLevel = .none
    var alcoholFrequency: AlcoholFrequency = .never
    var energyBaseline: Int = 5 // 1-10
    var stressLevel: StressLevel = .moderate
    
    // Devices & Privacy
    var wearables: Set<Wearable> = []
    var privacyPreference: PrivacyPreference = .privateOnly
    
    // Computed properties
    var heightInCm: Double? {
        guard let height = height else { return nil }
        return height * 2.54
    }
    
    var weightInKg: Double? {
        guard let weight = currentWeight else { return nil }
        return weight * 0.453592
    }
    
    var bmi: Double? {
        guard let weight = weightInKg, let height = heightInCm else { return nil }
        let heightInM = height / 100
        return weight / (heightInM * heightInM)
    }
}

// MARK: - Supporting Types

enum WorkoutTime: String, CaseIterable {
    case earlyMorning = "Early Morning (5-7 AM)"
    case morning = "Morning (7-9 AM)"
    case midday = "Midday (11 AM-1 PM)"
    case afternoon = "Afternoon (3-5 PM)"
    case evening = "Evening (5-7 PM)"
    case night = "Night (7-9 PM)"
    case varies = "Varies"
}

enum DietaryRestriction: String, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case paleo = "Paleo"
    case mediterranean = "Mediterranean"
    case lowCarb = "Low Carb"
    case glutenFree = "Gluten Free"
    case dairyFree = "Dairy Free"
}

enum FoodAllergy: String, CaseIterable {
    case gluten = "Gluten"
    case dairy = "Dairy"
    case nuts = "Tree Nuts"
    case peanuts = "Peanuts"
    case shellfish = "Shellfish"
    case eggs = "Eggs"
    case soy = "Soy"
    case fish = "Fish"
}

enum EatingStyle: String, CaseIterable {
    case noRestrictions = "No Restrictions"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case paleo = "Paleo"
    case mediterranean = "Mediterranean"
    case other = "Other"
}

enum HealthChallenge: String, CaseIterable {
    case afternoonCrashes = "Afternoon energy crashes"
    case poorSleep = "Poor sleep quality"
    case irregularMeals = "Irregular meal times"
    case emotionalEating = "Emotional eating"
    case slowMetabolism = "Slow metabolism"
    case digestiveIssues = "Digestive issues"
    case cravings = "Food cravings"
    case lackOfTime = "Lack of time for meal prep"
    case weightLoss = "Difficulty losing weight"
    case weightGain = "Difficulty gaining weight"
    case brainFog = "Brain fog"
}

enum NotificationPreference: String, CaseIterable {
    case all = "All nudges"
    case important = "Important only"
    case minimal = "Minimal"
    case none = "None"
}

// MARK: - New Supporting Types (Habits & Preferences)

enum WaterIntake: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
}

enum CaffeineLevel: String, CaseIterable {
    case none = "None"
    case oneTwo = "1-2 cups"
    case threeFour = "3-4 cups"
    case fivePlus = "5+ cups"
}

enum AlcoholFrequency: String, CaseIterable {
    case never = "Never"
    case occasional = "Occasionally"
    case weekly = "Weekly"
    case daily = "Daily"
}

enum StressLevel: String, CaseIterable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case veryHigh = "Very High"
}

enum Wearable: String, CaseIterable, Hashable {
    case appleWatch = "Apple Watch"
    case fitbit = "Fitbit"
    case whoop = "Whoop"
    case oura = "Oura"
    case garmin = "Garmin"
}

enum PrivacyPreference: String, CaseIterable {
    case publicSharing = "Share publicly"
    case anonymousOnly = "Anonymous only"
    case privateOnly = "Keep private"
}
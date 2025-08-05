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
    case profile
    case schedule
    case activity
    case dietary
    case challenges
    case preview
    case permissions
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to Phyllo"
        case .goals: return "Your Goals"
        case .profile: return "About You"
        case .schedule: return "Daily Schedule"
        case .activity: return "Activity Level"
        case .dietary: return "Dietary Preferences"
        case .challenges: return "Current Challenges"
        case .preview: return "Your Plan"
        case .permissions: return "Enable Features"
        }
    }
    
    var progress: Double {
        Double(self.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }
    
    var canSkip: Bool {
        switch self {
        case .welcome, .goals, .profile, .schedule: return false
        case .activity, .dietary, .challenges, .preview, .permissions: return true
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
        // Save to UserDefaults or Firebase
        saveOnboardingData()
        
        withAnimation(.easeOut(duration: 0.3)) {
            isCompleted = true
            shouldShowOnboarding = false
        }
    }
    
    private func saveOnboardingData() {
        // In a real app, this would save to Firebase or UserDefaults
        print("Saving onboarding data...")
        print("Primary goal: \(onboardingData.primaryGoal?.displayName ?? "None")")
        print("Profile: \(onboardingData.name ?? ""), \(onboardingData.age ?? 0) years old")
    }
    
    // Validation
    func canProceedFromCurrentStep() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .goals:
            return onboardingData.primaryGoal != nil
        case .profile:
            return !onboardingData.name.isEmpty &&
                   onboardingData.age != nil &&
                   onboardingData.gender != nil &&
                   onboardingData.height != nil &&
                   onboardingData.currentWeight != nil
        case .schedule:
            return onboardingData.wakeTime != nil &&
                   onboardingData.sleepTime != nil &&
                   onboardingData.workSchedule != nil
        case .activity:
            return true // Optional but should have activity level
        case .dietary:
            return true // Optional
        case .challenges:
            return true // Optional
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
    var activityLevel: ActivityLevel = .moderatelyActive
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

enum Gender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"
}

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
//
//  OnboardingCoordinator.swift
//  NutriSync
//
//  Main coordinator for NutriSync onboarding flow
//

import SwiftUI

@Observable
class NutriSyncOnboardingViewModel {
    // Navigation state
    var currentSection: NutriSyncOnboardingSection = .basics
    var currentScreenIndex: Int = 0
    var completedSections: Set<NutriSyncOnboardingSection> = []
    var showingSectionIntro: Bool = true
    
    // User data
    var weight: Double = 0
    var bodyFatPercentage: Double? = nil
    var exerciseFrequency: String = ""
    var activityLevel: String = ""
    var tdee: Double? = nil
    var goal: String = ""
    var targetWeight: Double? = nil
    var weightLossRate: Double? = nil
    var dietPreference: String = ""
    var calorieFloor: Int? = nil
    var trainingPlan: String = ""
    
    // Meal timing data
    var wakeTime: Date = Date()
    var bedTime: Date = Date()
    var mealFrequency: String = ""
    var breakfastHabit: String = ""
    var eatingWindow: String = ""
    
    // Workout data
    var workoutDays: Set<String> = []
    var workoutTime: Date = Date()
    var preworkoutTiming: String = ""
    var postworkoutTiming: String = ""
    
    // Lifestyle data
    var workSchedule: String = ""
    var socialMealsPerWeek: Double = 2
    var travelFrequency: String = ""
    
    // Nutrition preferences
    var dietaryRestrictions: Set<String> = []
    var foodSensitivities: String = ""
    var macroPreference: String = ""
    
    // Circadian data
    var energyPeak: String = ""
    var caffeineSensitivity: String = ""
    var largerMealPreference: String = ""
    
    // Window preferences
    var flexibilityLevel: String = ""
    var autoAdjustWindows: Bool = true
    var weekendDifferent: Bool = false
    
    // Notifications
    var windowStartNotifications: Bool = true
    var windowEndNotifications: Bool = true
    var checkInReminders: Bool = true
    var notificationMinutesBefore: Int = 15
    
    // Computed properties
    var currentSectionScreens: [String] {
        NutriSyncOnboardingFlow.screens(for: currentSection)
    }
    
    var isLastScreenInSection: Bool {
        currentScreenIndex >= currentSectionScreens.count - 1
    }
    
    var isLastSection: Bool {
        currentSection == .finish
    }
    
    // Navigation methods
    func nextScreen() {
        if showingSectionIntro {
            showingSectionIntro = false
            currentScreenIndex = 0
        } else if isLastScreenInSection {
            completeSection()
        } else {
            currentScreenIndex += 1
        }
    }
    
    func previousScreen() {
        if currentScreenIndex > 0 {
            currentScreenIndex -= 1
        } else if showingSectionIntro {
            // Go to previous section
            if let currentIndex = NutriSyncOnboardingSection.allCases.firstIndex(of: currentSection),
               currentIndex > 0 {
                let previousSection = NutriSyncOnboardingSection.allCases[currentIndex - 1]
                currentSection = previousSection
                let screens = NutriSyncOnboardingFlow.screens(for: previousSection)
                currentScreenIndex = screens.count - 1
                showingSectionIntro = false
            }
        } else {
            // Show section intro
            showingSectionIntro = true
        }
    }
    
    private func completeSection() {
        completedSections.insert(currentSection)
        
        // Move to next section
        if let currentIndex = NutriSyncOnboardingSection.allCases.firstIndex(of: currentSection),
           currentIndex < NutriSyncOnboardingSection.allCases.count - 1 {
            currentSection = NutriSyncOnboardingSection.allCases[currentIndex + 1]
            showingSectionIntro = true
            currentScreenIndex = 0
        }
    }
}

struct NutriSyncOnboardingCoordinator: View {
    @State private var viewModel = NutriSyncOnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            if viewModel.showingSectionIntro {
                SectionIntroView(
                    section: viewModel.currentSection,
                    completedSections: viewModel.completedSections,
                    onContinue: {
                        viewModel.nextScreen()
                    }
                )
                .transition(.opacity)
            } else {
                currentScreenView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreenIndex)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingSectionIntro)
    }
    
    @ViewBuilder
    private func currentScreenView() -> some View {
        let screenName = viewModel.currentSectionScreens[safe: viewModel.currentScreenIndex] ?? ""
        
        switch screenName {
        // Basics Section
        case "Basic Info":
            BasicInfoView()
        case "Weight":
            WeightView()
        case "Body Fat":
            BodyFatLevelView()
        case "Exercise":
            ExerciseFrequencyView()
        case "Activity":
            ActivityLevelView()
        case "Expenditure":
            ExpenditureView()
            
        // Notice Section
        case "Health Disclaimer":
            HealthDisclaimerView()
        case "Not to Worry":
            NotToWorryView()
            
        // Goal Setting Section
        case "Goal Intro":
            GoalSettingIntroView()
        case "Goal Selection":
            GoalSelectionView()
        case "Target Weight":
            TargetWeightView()
        case "Weight Loss Rate":
            WeightLossRateView()
        case "Workout Schedule":
            WorkoutScheduleView()
        case "Workout Nutrition":
            WorkoutNutritionView()
            
        // Program Section
        case "Almost There":
            AlmostThereView()
        case "Diet Preference":
            DietPreferenceView()
        case "Training Plan":
            TrainingPlanView()
        case "Calorie Floor":
            CalorieFloorView()
        case "Calorie Distribution":
            CalorieDistributionView()
            
        // New Meal Timing Screens
        case "Sleep Schedule":
            SleepScheduleView()
        case "Meal Frequency":
            MealFrequencyView()
        case "Breakfast Habit":
            BreakfastHabitView()
        case "Eating Window":
            EatingWindowView()
        case "Lifestyle Factors":
            LifestyleFactorsView()
        case "Dietary Restrictions":
            DietaryRestrictionsView()
        case "Nutrition Preferences":
            NutritionPreferencesView()
        case "Energy Patterns":
            EnergyPatternsView()
        case "Meal Timing":
            MealTimingPreferenceView()
        case "Window Flexibility":
            WindowFlexibilityView()
        case "Notification Preferences":
            NotificationPreferencesView()
            
        // Finish Section
        case "Review Program":
            ReviewProgramView()
            
        default:
            Text("Screen not found: \(screenName)")
                .foregroundColor(.white)
        }
    }
}

// MARK: - Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
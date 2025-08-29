//
//  MFOnboardingCoordinator.swift
//  NutriSync
//
//  Main coordinator for MacroFactor-style onboarding flow
//

import SwiftUI

@Observable
class MFOnboardingViewModel {
    // Navigation state
    var currentSection: MFOnboardingSection = .basics
    var currentScreenIndex: Int = 0
    var completedSections: Set<MFOnboardingSection> = []
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
    
    // Computed properties
    var currentSectionScreens: [String] {
        MFOnboardingFlow.screens(for: currentSection)
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
            if let currentIndex = MFOnboardingSection.allCases.firstIndex(of: currentSection),
               currentIndex > 0 {
                let previousSection = MFOnboardingSection.allCases[currentIndex - 1]
                currentSection = previousSection
                let screens = MFOnboardingFlow.screens(for: previousSection)
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
        if let currentIndex = MFOnboardingSection.allCases.firstIndex(of: currentSection),
           currentIndex < MFOnboardingSection.allCases.count - 1 {
            currentSection = MFOnboardingSection.allCases[currentIndex + 1]
            showingSectionIntro = true
            currentScreenIndex = 0
        }
    }
}

struct MFOnboardingCoordinator: View {
    @State private var viewModel = MFOnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            if viewModel.showingSectionIntro {
                MFSectionIntroView(
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
        case "Weight":
            MFWeightView()
        case "Body Fat":
            MFBodyFatLevelView()
        case "Exercise":
            MFExerciseFrequencyView()
        case "Activity":
            MFActivityLevelView()
        case "Expenditure":
            MFExpenditureView()
            
        // Notice Section
        case "Health Disclaimer":
            MFHealthDisclaimerView()
        case "Not to Worry":
            MFNotToWorryView()
            
        // Goal Setting Section
        case "Goal Intro":
            MFGoalSettingIntroView()
        case "Goal Selection":
            MFGoalSelectionView()
        case "Target Weight":
            MFTargetWeightView()
        case "Weight Loss Rate":
            MFWeightLossRateView()
            
        // Program Section
        case "Almost There":
            MFAlmostThereView()
        case "Diet Preference":
            MFDietPreferenceView()
        case "Training Plan":
            MFTrainingPlanView()
        case "Calorie Floor":
            MFCalorieFloorView()
        case "Calorie Distribution":
            MFCalorieDistributionView()
            
        // New Meal Timing Screens
        case "Sleep Schedule":
            MFSleepScheduleView()
        case "Meal Frequency":
            MFMealFrequencyView()
        case "Breakfast Habit":
            MFBreakfastHabitView()
        case "Eating Window":
            MFEatingWindowView()
            
        // Finish Section
        case "Review Program":
            MFReviewProgramView()
            
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
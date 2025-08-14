//
//  OnboardingContainerView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background - matching Schedule view
            Color(hex: "0A0A0A")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar (MacroFactor-inspired)
                OnboardingSectionProgress(
                    currentSection: viewModel.currentSection,
                    currentStep: viewModel.currentStep
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)
                
                // Content
                TabView(selection: $viewModel.currentScreen) {
                    ForEach(OnboardingScreen.allCases, id: \.self) { screen in
                        OnboardingScreenView(
                            screen: screen,
                            viewModel: viewModel
                        )
                        .tag(screen)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentScreen)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Section Progress View
struct OnboardingSectionProgress: View {
    let currentSection: OnboardingSection
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(OnboardingSection.allCases, id: \.self) { section in
                SectionDot(
                    section: section,
                    currentSection: currentSection,
                    isCompleted: section.rawValue < currentSection.rawValue
                )
            }
        }
    }
}

struct SectionDot: View {
    let section: OnboardingSection
    let currentSection: OnboardingSection
    let isCompleted: Bool
    
    private var isActive: Bool {
        section == currentSection
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if section != .welcome {
                Rectangle()
                    .fill(dotColor)
                    .frame(width: 16, height: 1)
            }
            
            ZStack {
                Circle()
                    .fill(dotColor)
                    .frame(width: isActive ? 10 : 8, height: isActive ? 10 : 8)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(Color(hex: "0A0A0A"))
                }
            }
            
            if section != .setup {
                Rectangle()
                    .fill(dotColor)
                    .frame(width: 16, height: 1)
            }
        }
        .animation(.spring(response: 0.3), value: isActive)
        .animation(.spring(response: 0.3), value: isCompleted)
    }
    
    private var dotColor: Color {
        if isCompleted || isActive {
            return Color(hex: "00D26A")
        }
        return Color.white.opacity(0.2)
    }
}

// MARK: - Enums
enum OnboardingSection: Int, CaseIterable {
    case welcome = 0
    case profile = 1
    case goals = 2
    case schedule = 3
    case setup = 4
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profile: return "Profile"
        case .goals: return "Goals"
        case .schedule: return "Schedule"
        case .setup: return "Setup"
        }
    }
}

enum OnboardingScreen: CaseIterable {
    // Welcome Section
    case permissions
    case welcome
    case impactCalculator
    case goodNews
    
    // Profile Section
    case basicInfo
    case bodyMetrics
    case bodyComposition
    
    // Goals Section
    case primaryGoal
    case weightGoal
    case secondaryGoals
    
    // Schedule Section
    case scheduleIntro
    case dailyRoutine
    case activityPatterns
    case mealFrequency
    case schedulePreview
    
    // Setup Section
    case dietaryPreferences
    case calculatingPlan
    case planSummary
    case notifications
    case accountCreation
    case success
    
    var section: OnboardingSection {
        switch self {
        case .permissions, .welcome, .impactCalculator, .goodNews:
            return .welcome
        case .basicInfo, .bodyMetrics, .bodyComposition:
            return .profile
        case .primaryGoal, .weightGoal, .secondaryGoals:
            return .goals
        case .scheduleIntro, .dailyRoutine, .activityPatterns, .mealFrequency, .schedulePreview:
            return .schedule
        case .dietaryPreferences, .calculatingPlan, .planSummary, .notifications, .accountCreation, .success:
            return .setup
        }
    }
}

// MARK: - View Model
class OnboardingViewModel: ObservableObject {
    @Published var currentScreen: OnboardingScreen = .permissions
    @Published var userData = OnboardingUserData()
    
    var currentSection: OnboardingSection {
        currentScreen.section
    }
    
    var currentStep: Int {
        OnboardingScreen.allCases.firstIndex(of: currentScreen) ?? 0
    }
    
    func nextScreen() {
        guard let currentIndex = OnboardingScreen.allCases.firstIndex(of: currentScreen),
              currentIndex < OnboardingScreen.allCases.count - 1 else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = OnboardingScreen.allCases[currentIndex + 1]
        }
    }
    
    func previousScreen() {
        guard let currentIndex = OnboardingScreen.allCases.firstIndex(of: currentScreen),
              currentIndex > 0 else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentScreen = OnboardingScreen.allCases[currentIndex - 1]
        }
    }
}

// MARK: - User Data Model
struct OnboardingUserData {
    // Profile
    var name: String = ""
    var birthDate = Date()
    var biologicalSex: BiologicalSex = .female
    var height: Double = 170 // cm
    var weight: Double = 70 // kg
    var bodyFatPercentage: Double = 25
    
    // Goals
    var primaryGoal: PrimaryGoal = .improveEnergy
    var targetWeight: Double = 65
    var weightPace: WeightPace = .moderate
    var secondaryGoals: Set<SecondaryGoal> = []
    
    // Schedule
    var wakeTime = DateComponents(hour: 6, minute: 0)
    var lunchTime = DateComponents(hour: 12, minute: 0)
    var workEndTime = DateComponents(hour: 17, minute: 0)
    var bedTime = DateComponents(hour: 22, minute: 0)
    var activityLevel: OnboardingActivityLevel = .active
    var exerciseFrequency: Int = 3
    var mealFrequency: MealFrequency = .three
    
    // Preferences
    var dietaryPreferences: Set<DietaryPreference> = []
    var foodsToAvoid: [String] = []
    
    // Impact
    var currentEnergyLevel: Int = 5
}

// MARK: - Enums for User Data
enum BiologicalSex: String, CaseIterable {
    case female = "Female"
    case male = "Male"
}

enum PrimaryGoal: String, CaseIterable {
    case loseWeight = "Lose Weight"
    case buildMuscle = "Build Muscle"
    case improveEnergy = "Improve Energy"
    case athleticPerformance = "Athletic Performance"
    case generalHealth = "General Health"
    
    var description: String {
        switch self {
        case .loseWeight: return "Sustainable fat loss while preserving muscle"
        case .buildMuscle: return "Gain lean mass with minimal fat"
        case .improveEnergy: return "Optimize meal timing for consistent energy"
        case .athleticPerformance: return "Fuel training and enhance recovery"
        case .generalHealth: return "Balance nutrition for overall wellness"
        }
    }
}

enum WeightPace: String, CaseIterable {
    case relaxed = "Relaxed"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
    
    var rate: String {
        switch self {
        case .relaxed: return "0.5 lb/week"
        case .moderate: return "1 lb/week"
        case .aggressive: return "1.5 lb/week"
        }
    }
}

enum SecondaryGoal: String, CaseIterable {
    case betterSleep = "Better Sleep"
    case improvedFocus = "Improved Focus"
    case stableMood = "Stable Mood"
    case reducedCravings = "Reduced Cravings"
    case betterDigestion = "Better Digestion"
    case moreEnergy = "More Energy"
    case athleticRecovery = "Athletic Recovery"
}

enum OnboardingActivityLevel: String, CaseIterable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case active = "Active"
    case veryActive = "Very Active"
    
    var description: String {
        switch self {
        case .sedentary: return "Less than 5,000 steps/day"
        case .lightlyActive: return "5,000-10,000 steps/day"
        case .active: return "10,000-15,000 steps/day"
        case .veryActive: return "More than 15,000 steps/day"
        }
    }
}

enum MealFrequency: String, CaseIterable {
    case two = "2 Meals/Day"
    case three = "3 Meals/Day"
    case fourToFive = "4-5 Meals/Day"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .two: return "16:8 Intermittent Fasting"
        case .three: return "Traditional eating pattern"
        case .fourToFive: return "Frequent feeding"
        case .custom: return "Design your own schedule"
        }
    }
    
    var benefits: String {
        switch self {
        case .two: return "Best for: Fat loss, simplicity"
        case .three: return "Best for: Sustained energy"
        case .fourToFive: return "Best for: Muscle gain, athletes"
        case .custom: return "Best for: Specific needs"
        }
    }
}

enum DietaryPreference: String, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case keto = "Keto"
    case paleo = "Paleo"
}

// MARK: - Screen Router
struct OnboardingScreenView: View {
    let screen: OnboardingScreen
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        Group {
            switch screen {
            case .permissions:
                PermissionsView(viewModel: viewModel)
            case .welcome:
                WelcomeView(viewModel: viewModel)
            case .impactCalculator:
                ImpactCalculatorView(viewModel: viewModel)
            case .goodNews:
                GoodNewsView(viewModel: viewModel)
            default:
                // Placeholder for other screens
                Text("Screen: \(String(describing: screen))")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Preview
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
    }
}
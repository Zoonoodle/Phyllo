//
//  OnboardingCoordinator.swift
//  NutriSync
//
//  Main coordinator for NutriSync onboarding flow
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@Observable
class NutriSyncOnboardingViewModel {
    // Navigation state
    var currentSection: NutriSyncOnboardingSection = .basics
    var currentScreenIndex: Int = 0
    var completedSections: Set<NutriSyncOnboardingSection> = []
    var showingSectionIntro: Bool = true
    
    // Firebase integration
    var isSaving: Bool = false
    var saveError: Error?
    var showSaveError: Bool = false
    private var dataProvider = FirebaseDataProvider.shared
    
    // Progress tracking
    var progress: OnboardingProgress?
    
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
        
        // Save progress after each section completion
        Task {
            await saveProgressToFirebase()
        }
        
        // Move to next section
        if let currentIndex = NutriSyncOnboardingSection.allCases.firstIndex(of: currentSection),
           currentIndex < NutriSyncOnboardingSection.allCases.count - 1 {
            currentSection = NutriSyncOnboardingSection.allCases[currentIndex + 1]
            showingSectionIntro = true
            currentScreenIndex = 0
        }
    }
    
    // MARK: - Firebase Integration
    
    @MainActor
    func saveProgressToFirebase() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("[OnboardingCoordinator] No authenticated user for saving progress")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        // Build progress object
        let progress = buildProgressObject(userId: userId)
        
        do {
            try await dataProvider.saveOnboardingProgress(progress)
            print("[OnboardingCoordinator] Progress saved successfully for section: \(currentSection)")
        } catch {
            print("[OnboardingCoordinator] Failed to save progress: \(error.localizedDescription)")
            saveError = error
            showSaveError = true
        }
    }
    
    func buildProgressObject(userId: String) -> OnboardingProgress {
        var progress = OnboardingProgress(
            userId: userId,
            currentSection: NutriSyncOnboardingSection.allCases.firstIndex(of: currentSection) ?? 0,
            currentStep: currentScreenIndex,
            completedSections: Set(completedSections.compactMap { NutriSyncOnboardingSection.allCases.firstIndex(of: $0) }),
            lastUpdated: Date(),
            isComplete: false
        )
        
        // Section 1: Basic Info
        if weight > 0 { progress.weightKG = weight }
        progress.bodyFatPercentage = bodyFatPercentage
        if !activityLevel.isEmpty { progress.activityLevel = UserGoals.ActivityLevel(rawValue: activityLevel) }
        
        // Section 2: Goals
        if !goal.isEmpty { progress.primaryGoal = UserGoals.Goal(rawValue: goal) }
        progress.targetWeightKG = targetWeight
        progress.weeklyWeightChangeKG = weightLossRate
        progress.minimumCalories = calorieFloor
        
        // Section 3: Lifestyle
        progress.wakeTime = wakeTime
        progress.bedTime = bedTime
        if !mealFrequency.isEmpty { progress.mealsPerDay = Int(mealFrequency) ?? 3 }
        if !eatingWindow.isEmpty { progress.eatingWindowHours = Int(eatingWindow.components(separatedBy: " ").first ?? "16") ?? 16 }
        if !breakfastHabit.isEmpty { progress.breakfastPreference = breakfastHabit == "yes" }
        if !dietaryRestrictions.isEmpty { progress.dietaryRestrictions = Array(dietaryRestrictions) }
        if !dietPreference.isEmpty { progress.dietType = dietPreference }
        
        // Section 4: Training
        if !workoutDays.isEmpty { progress.workoutsPerWeek = workoutDays.count }
        progress.workoutDays = workoutDays.compactMap { dayString in
            ["Monday": 1, "Tuesday": 2, "Wednesday": 3, "Thursday": 4, "Friday": 5, "Saturday": 6, "Sunday": 0][dayString]
        }
        progress.workoutTimes = [workoutTime]
        if !trainingPlan.isEmpty { progress.trainingType = trainingPlan }
        
        // Section 5: Optimization
        if !energyPeak.isEmpty {
            progress.energyPatterns = ["peak": energyPeak == "morning" ? 0 : (energyPeak == "afternoon" ? 1 : 2)]
        }
        if !flexibilityLevel.isEmpty { progress.scheduleFlexibility = flexibilityLevel == "flexible" ? 2 : (flexibilityLevel == "moderate" ? 1 : 0) }
        progress.notificationSettings = NotificationSettings(
            windowStart: windowStartNotifications,
            windowEnd: windowEndNotifications,
            checkInReminders: checkInReminders,
            minutesBefore: notificationMinutesBefore
        )
        
        return progress
    }
    
    func loadExistingProgress(_ existingProgress: OnboardingProgress) {
        print("[OnboardingCoordinator] Loading existing progress from section \(existingProgress.currentSection)")
        
        // Restore navigation state
        if existingProgress.currentSection < NutriSyncOnboardingSection.allCases.count {
            currentSection = NutriSyncOnboardingSection.allCases[existingProgress.currentSection]
        }
        currentScreenIndex = existingProgress.currentStep
        completedSections = Set(existingProgress.completedSections.compactMap { index in
            index < NutriSyncOnboardingSection.allCases.count ? NutriSyncOnboardingSection.allCases[index] : nil
        })
        
        // Restore user data
        if let weight = existingProgress.weightKG { self.weight = weight }
        self.bodyFatPercentage = existingProgress.bodyFatPercentage
        if let activityLevel = existingProgress.activityLevel { self.activityLevel = activityLevel.rawValue }
        
        if let goal = existingProgress.primaryGoal { self.goal = goal.rawValue }
        self.targetWeight = existingProgress.targetWeightKG
        self.weightLossRate = existingProgress.weeklyWeightChangeKG
        self.calorieFloor = existingProgress.minimumCalories
        
        if let wakeTime = existingProgress.wakeTime { self.wakeTime = wakeTime }
        if let bedTime = existingProgress.bedTime { self.bedTime = bedTime }
        if let mealsPerDay = existingProgress.mealsPerDay { self.mealFrequency = String(mealsPerDay) }
        if let eatingWindowHours = existingProgress.eatingWindowHours { self.eatingWindow = "\(eatingWindowHours) hours" }
        if let breakfastPreference = existingProgress.breakfastPreference { self.breakfastHabit = breakfastPreference ? "yes" : "no" }
        if let dietaryRestrictions = existingProgress.dietaryRestrictions { self.dietaryRestrictions = Set(dietaryRestrictions) }
        if let dietType = existingProgress.dietType { self.dietPreference = dietType }
        
        self.progress = existingProgress
    }
    
    @MainActor
    func completeOnboarding() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw DataProviderError.notAuthenticated
        }
        
        print("[OnboardingCoordinator] Starting profile creation process")
        
        // Build UserProfile and UserGoals from collected data
        let profile = buildUserProfile()
        let goals = buildUserGoals()
        
        // Save atomically to Firebase
        try await dataProvider.createUserProfile(
            profile: profile,
            goals: goals,
            deleteProgress: true
        )
        
        // Generate initial windows
        try await dataProvider.generateInitialWindows()
        
        print("[OnboardingCoordinator] Onboarding completed successfully")
    }
    
    private func buildUserProfile() -> UserProfile {
        // Convert weight from kg to pounds for UserProfile
        let weightInPounds = weight * 2.20462
        
        // Convert height from cm to inches (assuming average height for now)
        let heightInInches = 68.0 // This should be collected in a future update
        
        // Map goal string to NutritionGoal enum
        let nutritionGoal: NutritionGoal = switch goal.lowercased() {
            case "lose weight", "weight loss":
                .weightLoss(targetPounds: (targetWeight ?? weight - 10) * 2.20462, timeline: 12)
            case "build muscle", "muscle gain":
                .muscleGain(targetPounds: (targetWeight ?? weight + 10) * 2.20462, timeline: 12)
            case "maintain weight":
                .maintainWeight
            case "improve performance", "performance":
                .performanceFocus
            case "better sleep":
                .betterSleep
            default:
                .overallWellbeing
        }
        
        return UserProfile(
            id: UUID(),
            name: "User", // This should be collected in a future update
            age: 30, // This should be collected in a future update
            gender: .male, // This should be collected in a future update
            height: heightInInches,
            weight: weightInPounds,
            activityLevel: ActivityLevel(rawValue: activityLevel) ?? .moderatelyActive,
            primaryGoal: nutritionGoal,
            dietaryPreferences: Array(dietaryRestrictions), // Using restrictions as preferences for now
            dietaryRestrictions: Array(dietaryRestrictions),
            dailyCalorieTarget: Int(tdee ?? 2000),
            dailyProteinTarget: Int((weight * 2.2) * 0.8), // 0.8g per lb
            dailyCarbTarget: 200,
            dailyFatTarget: 65,
            preferredMealTimes: [],
            micronutrientPriorities: [],
            earliestMealHour: Calendar.current.component(.hour, from: wakeTime),
            latestMealHour: Calendar.current.component(.hour, from: bedTime) - 3, // 3 hours before bed
            workSchedule: .standard,
            typicalWakeTime: wakeTime,
            typicalSleepTime: bedTime,
            fastingProtocol: eatingWindow.contains("16") ? .sixteen8 : .none,
            lastBulkLogDate: nil
        )
    }
    
    private func buildUserGoals() -> UserGoals {
        let primaryGoal: UserGoals.Goal = switch goal.lowercased() {
            case "lose weight", "weight loss": .loseWeight
            case "build muscle", "muscle gain": .buildMuscle
            case "maintain weight": .maintainWeight
            case "improve performance", "performance": .improvePerformance
            case "better sleep": .betterSleep
            default: .overallHealth
        }
        
        let activityLevelEnum: UserGoals.ActivityLevel = switch activityLevel.lowercased() {
            case "sedentary": .sedentary
            case "lightly active", "lightlyactive": .lightlyActive
            case "moderately active", "moderatelyactive": .moderatelyActive
            case "very active", "veryactive": .veryActive
            case "extremely active", "extremelyactive", "athlete": .athlete
            default: .moderatelyActive
        }
        
        let calorieTarget = Int(tdee ?? 2000) - (primaryGoal == .loseWeight ? 500 : 0)
        
        return UserGoals(
            primaryGoal: primaryGoal,
            activityLevel: activityLevelEnum,
            dailyCalories: calorieTarget,
            dailyProtein: Int((weight * 2.2) * 0.8), // 0.8g per lb
            dailyCarbs: 200,
            dailyFat: 65,
            targetWeight: targetWeight != nil ? targetWeight! * 2.20462 : nil, // Convert to pounds
            timeline: 12 // Default 12 weeks
        )
    }
}

struct NutriSyncOnboardingCoordinator: View {
    @State private var viewModel = NutriSyncOnboardingViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataProvider: FirebaseDataProvider
    
    let existingProgress: OnboardingProgress?
    
    init(existingProgress: OnboardingProgress? = nil) {
        self.existingProgress = existingProgress
    }
    
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
                    .environment(viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentScreenIndex)
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingSectionIntro)
        .onAppear {
            // Load existing progress if available
            if let progress = existingProgress {
                viewModel.loadExistingProgress(progress)
            }
        }
        .alert("Save Error", isPresented: $viewModel.showSaveError) {
            Button("Retry") {
                Task {
                    await viewModel.saveProgressToFirebase()
                }
            }
            Button("Continue", role: .cancel) {}
        } message: {
            Text(viewModel.saveError?.localizedDescription ?? "Failed to save your progress. You can retry or continue.")
        }
        .overlay(alignment: .top) {
            // Show saving indicator
            if viewModel.isSaving {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("Saving progress...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .padding(.top, 50)
            }
        }
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
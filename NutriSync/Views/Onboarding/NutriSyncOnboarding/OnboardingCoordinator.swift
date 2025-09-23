//
//  OnboardingCoordinator.swift
//  NutriSync
//
//  Main coordinator for NutriSync onboarding flow
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension Date {
    var timeIntervalSinceStartOfDay: TimeInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: self)
        return self.timeIntervalSince(startOfDay)
    }
}

@Observable
@MainActor
class NutriSyncOnboardingViewModel {
    // Navigation state
    var currentSection: NutriSyncOnboardingSection = .basics
    var currentScreenIndex: Int = 0
    var completedSections: Set<NutriSyncOnboardingSection> = []
    var showingSectionIntro: Bool = true
    var navigationDirection: NavigationDirection = .forward
    
    init() {
        print("[NutriSyncOnboardingViewModel] INIT - Creating new coordinator instance")
        print("[NutriSyncOnboardingViewModel] Default values - Exercise: \(exerciseFrequency), Daily: \(dailyActivity)")
    }
    
    // Navigation direction for carousel transitions
    enum NavigationDirection {
        case forward
        case backward
    }
    
    // Firebase integration
    var isSaving: Bool = false
    var saveError: Error?
    var showSaveError: Bool = false
    private var dataProvider = FirebaseDataProvider.shared
    
    // Account creation prompt
    var showAccountCreation: Bool = false
    var hasSkippedAccountCreation: Bool = UserDefaults.standard.bool(forKey: "skippedAccountCreation")
    
    // Progress tracking
    var progress: OnboardingProgress?
    
    // User data
    var height: Double = 178 // in cm (about 5'10")
    var gender: String = "Male"
    var age: Int = 30
    var weight: Double = 70 // in kg (about 154 lbs)
    var exerciseFrequency: String = "0 sessions / week"
    var dailyActivity: String = "Mostly Sedentary" // User's daily activity selection
    var activityLevel: String = "Mostly Sedentary" // Calculated activity level for TDEE
    var tdee: Double? = nil
    var goal: String = ""
    var maintenanceStrategy: String = ""
    var targetWeight: Double? = nil
    var weightLossRate: Double? = nil
    var dietPreference: String = ""
    var calorieFloor: Int? = nil
    var trainingPlan: String = ""
    var trainingFrequency: String? = nil
    var trainingTime: String? = nil
    
    // Meal timing data
    var wakeTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        // Ensure we get a valid date, fallback to 7am today if calendar fails
        return Calendar.current.date(from: components) ?? Date().addingTimeInterval(-Date().timeIntervalSinceStartOfDay + 7 * 3600)
    }()
    var bedTime: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        // Ensure we get a valid date, fallback to 11pm today if calendar fails
        return Calendar.current.date(from: components) ?? Date().addingTimeInterval(-Date().timeIntervalSinceStartOfDay + 23 * 3600)
    }()
    var mealFrequency: String = ""
    // Auto-set based on goals rather than user selection
    private var _eatingWindow: String = ""
    var eatingWindow: String {
        get {
            // If manually set (for backward compatibility), use that
            if !_eatingWindow.isEmpty {
                return _eatingWindow
            }
            
            // Otherwise determine window based on goal
            switch goal.lowercased() {
            case "lose weight":
                return "8 hours" // 16:8 intermittent fasting
            case "build muscle", "gain weight":
                return "12 hours" // More frequent feeding opportunities
            case "maintain weight":
                return "10 hours" // Moderate approach
            default:
                return "10 hours" // Default moderate window
            }
        }
        set {
            _eatingWindow = newValue
        }
    }
    
    // Workout data
    var preworkoutTiming: String = ""
    var postworkoutTiming: String = ""
    
    // Nutrition preferences
    var dietaryRestrictions: Set<String> = []
    var largerMealPreference: String = ""
    
    // Window preferences
    var flexibilityLevel: String = ""
    var autoAdjustWindows: Bool = true
    var weekendDifferent: Bool = false
    
    // Health disclaimer acceptance
    var acceptHealthDisclaimer: Bool = false
    var acceptPrivacyNotice: Bool = false
    
    // Computed properties
    var currentSectionScreens: [String] {
        NutriSyncOnboardingFlow.screens(for: currentSection, goal: goal)
    }
    
    var currentScreen: String? {
        currentSectionScreens[safe: currentScreenIndex]
    }
    
    var isLastScreenInSection: Bool {
        currentScreenIndex >= currentSectionScreens.count - 1
    }
    
    var isLastSection: Bool {
        currentSection == .finish
    }
    
    // Navigation methods
    func nextScreen() {
        navigationDirection = .forward
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
        navigationDirection = .backward
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
    
    func goToPreviousSection() {
        navigationDirection = .backward
        // Navigate to the last screen of the previous section
        if let currentIndex = NutriSyncOnboardingSection.allCases.firstIndex(of: currentSection),
           currentIndex > 0 {
            let previousSection = NutriSyncOnboardingSection.allCases[currentIndex - 1]
            currentSection = previousSection
            let screens = NutriSyncOnboardingFlow.screens(for: previousSection)
            currentScreenIndex = screens.count - 1
            showingSectionIntro = false
        }
    }
    
    private func completeSection() {
        completedSections.insert(currentSection)
        
        // Save progress after each section completion
        Task {
            await saveProgressToFirebase()
        }
        
        // Show account creation prompt after Section 1 (basics) if still anonymous
        if currentSection == .basics && shouldShowAccountPrompt() {
            showAccountCreation = true
        }
        
        // Move to next section
        if let currentIndex = NutriSyncOnboardingSection.allCases.firstIndex(of: currentSection),
           currentIndex < NutriSyncOnboardingSection.allCases.count - 1 {
            currentSection = NutriSyncOnboardingSection.allCases[currentIndex + 1]
            showingSectionIntro = true
            currentScreenIndex = 0
        }
    }
    
    func shouldShowAccountPrompt() -> Bool {
        // Only if still anonymous
        guard Auth.auth().currentUser?.isAnonymous == true else { return false }
        
        // Check if already dismissed once
        return !hasSkippedAccountCreation
    }
    
    func markAccountCreationSkipped() {
        hasSkippedAccountCreation = true
        UserDefaults.standard.set(true, forKey: "skippedAccountCreation")
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
        if !activityLevel.isEmpty { progress.activityLevel = UserGoals.ActivityLevel(rawValue: activityLevel) }
        
        // Section 2: Goals
        if !goal.isEmpty { progress.primaryGoal = UserGoals.Goal(rawValue: goal) }
        progress.targetWeightKG = targetWeight
        progress.weeklyWeightChangeKG = weightLossRate
        progress.minimumCalories = calorieFloor
        
        // Section 3: Lifestyle
        // Always set wake/bed times since they now have proper default values
        progress.wakeTime = wakeTime
        progress.bedTime = bedTime
        if !mealFrequency.isEmpty { progress.mealsPerDay = Int(mealFrequency) ?? 3 }
        if !eatingWindow.isEmpty { progress.eatingWindowHours = Int(eatingWindow.components(separatedBy: " ").first ?? "16") ?? 16 }
        if !dietaryRestrictions.isEmpty { progress.dietaryRestrictions = Array(dietaryRestrictions) }
        if !dietPreference.isEmpty { progress.dietType = dietPreference }
        
        // Section 4: Training
        if !trainingPlan.isEmpty { progress.trainingType = trainingPlan }
        
        // Section 5: Optimization
        if !flexibilityLevel.isEmpty { progress.scheduleFlexibility = flexibilityLevel == "flexible" ? 2 : (flexibilityLevel == "moderate" ? 1 : 0) }
        
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
        if let activityLevel = existingProgress.activityLevel { self.activityLevel = activityLevel.rawValue }
        
        if let goal = existingProgress.primaryGoal { self.goal = goal.rawValue }
        self.targetWeight = existingProgress.targetWeightKG
        self.weightLossRate = existingProgress.weeklyWeightChangeKG
        self.calorieFloor = existingProgress.minimumCalories
        
        if let wakeTime = existingProgress.wakeTime { self.wakeTime = wakeTime }
        if let bedTime = existingProgress.bedTime { self.bedTime = bedTime }
        if let mealsPerDay = existingProgress.mealsPerDay { self.mealFrequency = String(mealsPerDay) }
        if let eatingWindowHours = existingProgress.eatingWindowHours { self.eatingWindow = "\(eatingWindowHours) hours" }
        if let dietaryRestrictions = existingProgress.dietaryRestrictions { self.dietaryRestrictions = Set(dietaryRestrictions) }
        if let dietType = existingProgress.dietType { self.dietPreference = dietType }
        
        self.progress = existingProgress
    }
    
    @MainActor
    func completeOnboarding() async throws {
        guard Auth.auth().currentUser?.uid != nil else {
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
            case "build muscle", "muscle gain", "gain weight":
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
            dailyProteinTarget: Int(weightInPounds * 0.8), // 0.8g per lb (weight already in pounds)
            dailyCarbTarget: calculateCarbs(calories: Int(tdee ?? 2000), goal: nutritionGoal),
            dailyFatTarget: calculateFat(calories: Int(tdee ?? 2000), goal: nutritionGoal),
            preferredMealTimes: [],
            micronutrientPriorities: [],
            earliestMealHour: Calendar.current.component(.hour, from: wakeTime),
            latestMealHour: Calendar.current.component(.hour, from: bedTime) - 3, // 3 hours before bed
            workSchedule: .standard,
            typicalWakeTime: wakeTime,
            typicalSleepTime: bedTime,
            fastingProtocol: eatingWindow.contains("16") ? .sixteen8 : .none,
            lastBulkLogDate: nil,
            firstDayCompleted: false, // Will be set to true after first day windows are generated
            onboardingCompletedAt: Date() // Set the current time as onboarding completion
        )
    }
    
    private func buildUserGoals() -> UserGoals {
        let primaryGoal: UserGoals.Goal = switch goal.lowercased() {
            case "lose weight", "weight loss": .loseWeight
            case "build muscle", "muscle gain", "gain weight": .buildMuscle
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
            targetWeight: targetWeight.map { $0 * 2.20462 }, // Convert to pounds safely
            timeline: 12 // Default 12 weeks
        )
    }
    
    /// Calculate carbs based on calories and goal
    private func calculateCarbs(calories: Int, goal: NutritionGoal) -> Int {
        let carbCalorieRatio: Double
        switch goal {
        case .weightLoss:
            carbCalorieRatio = 0.35 // 35% from carbs for weight loss
        case .muscleGain:
            carbCalorieRatio = 0.45 // 45% from carbs for muscle building
        case .athleticPerformance, .performanceFocus:
            carbCalorieRatio = 0.50 // 50% from carbs for performance
        case .betterSleep:
            carbCalorieRatio = 0.40 // 40% from carbs for sleep optimization
        default:
            carbCalorieRatio = 0.40 // 40% default
        }
        
        let carbCalories = Double(calories) * carbCalorieRatio
        return Int(carbCalories / 4) // 4 calories per gram of carbs
    }
    
    /// Calculate fat based on calories and goal
    private func calculateFat(calories: Int, goal: NutritionGoal) -> Int {
        let fatCalorieRatio: Double
        switch goal {
        case .weightLoss:
            fatCalorieRatio = 0.30 // 30% from fat for weight loss
        case .muscleGain:
            fatCalorieRatio = 0.25 // 25% from fat for muscle building
        case .athleticPerformance, .performanceFocus:
            fatCalorieRatio = 0.25 // 25% from fat for performance
        case .betterSleep:
            fatCalorieRatio = 0.35 // 35% from fat for sleep optimization
        default:
            fatCalorieRatio = 0.30 // 30% default
        }
        
        let fatCalories = Double(calories) * fatCalorieRatio
        return Int(fatCalories / 9) // 9 calories per gram of fat
    }
}

struct NutriSyncOnboardingCoordinator: View {
    @State var viewModel: NutriSyncOnboardingViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var dataProvider: FirebaseDataProvider
    @EnvironmentObject private var firebaseConfig: FirebaseConfig
    @State private var previousScreenIndex: Int = 0
    
    let existingProgress: OnboardingProgress?
    let skipSectionIntro: Bool
    
    init(viewModel: NutriSyncOnboardingViewModel, existingProgress: OnboardingProgress? = nil, skipSectionIntro: Bool = false) {
        self._viewModel = State(initialValue: viewModel)
        self.existingProgress = existingProgress
        self.skipSectionIntro = skipSectionIntro
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
                    },
                    onBack: {
                        viewModel.goToPreviousSection()
                    }
                )
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Fixed progress bar at top
                    OnboardingSectionProgressBar()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                        .environment(viewModel)
                    
                    // Carousel content in the middle
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            ForEach(0..<viewModel.currentSectionScreens.count, id: \.self) { index in
                                getScreenContentView(at: index)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                        .offset(x: -CGFloat(viewModel.currentScreenIndex) * geometry.size.width)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85, blendDuration: 0), value: viewModel.currentScreenIndex)
                    }
                    
                    // Fixed navigation buttons at bottom
                    HStack {
                        Button {
                            viewModel.previousScreen()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        // Navigation dots indicator - inline with back/save buttons
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(index == NutriSyncOnboardingSection.allCases.firstIndex(of: viewModel.currentSection) ? Color.nutriSyncAccent : Color.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Spacer()
                        
                        let isHealthDisclaimer = viewModel.currentScreen == "Health Disclaimer"
                        let termsAccepted = viewModel.acceptHealthDisclaimer && viewModel.acceptPrivacyNotice
                        let isGoalSelection = viewModel.currentScreen == "Goal Selection"
                        let goalSelected = !viewModel.goal.isEmpty
                        let isTrainingPlan = viewModel.currentScreen == "Training Plan"
                        let trainingPlanSelected = viewModel.trainingFrequency != nil && viewModel.trainingTime != nil
                        let isDietPreference = viewModel.currentScreen == "Diet Preference"
                        let dietSelected = !viewModel.dietPreference.isEmpty
                        let isMealFrequency = viewModel.currentScreen == "Meal Frequency"
                        let mealFrequencySelected = !viewModel.mealFrequency.isEmpty
                        
                        let isDisabled = (isHealthDisclaimer && !termsAccepted) || 
                                       (isGoalSelection && !goalSelected) ||
                                       (isTrainingPlan && !trainingPlanSelected) ||
                                       (isDietPreference && !dietSelected) ||
                                       (isMealFrequency && !mealFrequencySelected)
                        let isLastScreenInSection = viewModel.isLastScreenInSection
                        
                        Button {
                            handleNextAction()
                        } label: {
                            HStack(spacing: 6) {
                                Text(isLastScreenInSection ? "Save" : "Next")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(isDisabled ? Color.white.opacity(0.3) : .black)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(isDisabled ? Color.white.opacity(0.1) : Color.nutriSyncAccent)
                            .cornerRadius(22)
                        }
                        .disabled(isDisabled)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
                .environment(viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showingSectionIntro)
        .onAppear {
            // Load existing progress if available
            if let progress = existingProgress {
                viewModel.loadExistingProgress(progress)
            }
            // Skip section intro if requested (e.g., when coming from GetStartedView for users on Basics)
            if skipSectionIntro {
                viewModel.showingSectionIntro = false
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
        .sheet(isPresented: $viewModel.showAccountCreation) {
            AccountCreationView()
                .environmentObject(firebaseConfig)
                .onDisappear {
                    // Mark as skipped if dismissed without creating account
                    if firebaseConfig.isAnonymous {
                        viewModel.markAccountCreationSkipped()
                    }
                }
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
    
    // Handle next button action based on current screen
    private func handleNextAction() {
        // Check if on Health Disclaimer screen and terms aren't accepted
        if viewModel.currentScreen == "Health Disclaimer" && 
           (!viewModel.acceptHealthDisclaimer || !viewModel.acceptPrivacyNotice) {
            // Don't navigate - user must accept both terms
            return
        }
        
        // Check if on Goal Selection screen and no goal is selected
        if viewModel.currentScreen == "Goal Selection" && viewModel.goal.isEmpty {
            // Don't navigate - user must select a goal
            return
        }
        
        // Screen-specific data saving will be handled by the screen's onDisappear
        // Just navigate to next
        viewModel.nextScreen()
    }
    
    @ViewBuilder
    private func getScreenContentView(at index: Int) -> some View {
        let screenName = viewModel.currentSectionScreens[safe: index] ?? ""
        
        switch screenName {
        // Basics Section
        case "Sex Selection":
            SexSelectionView()
        case "Birth Date":
            BirthDateView()
        case "Height":
            HeightSelectionView()
        case "Weight":
            WeightContentView()
        case "Body Fat":
            Text("Body Fat screen removed")
                .foregroundColor(.white)
        case "Exercise":
            ExerciseFrequencyContentView()
        case "Activity":
            ActivityLevelContentView()
        case "Expenditure":
            ExpenditureContentView()
            
        // Notice Section
        case "Health Disclaimer":
            HealthDisclaimerContentView()
        case "Not to Worry":
            NotToWorryContentView()
            
        // Goal Setting Section
        case "Goal Intro":
            GoalSettingIntroContentView()
        case "Goal Selection":
            GoalSelectionContentView()
        case "Trend Weight":
            TrendWeightContentView()
        case "Goal Summary":
            GoalSummaryContentView()
        case "Weight Goal":
            WeightGoalContentView()
        case "Workout Schedule":
            Text("Workout Schedule screen removed")
                .foregroundColor(.white)
        case "Pre-Workout Nutrition":
            PreWorkoutNutritionContentView()
        case "Post-Workout Nutrition":
            PostWorkoutNutritionContentView()
            
        // Program Section
        case "Diet Preference":
            DietPreferenceContentView()
        case "Training Plan":
            TrainingPlanContentView()
        case "Calorie Distribution":
            Text("Calorie Distribution screen removed")
                .foregroundColor(.white)
            
        // New Meal Timing Screens
        case "Sleep Schedule":
            SleepScheduleContentView()
        case "Meal Frequency":
            MealFrequencyContentView()
        case "Breakfast Habit":
            Text("Breakfast Habit screen removed")
                .foregroundColor(.white)
        case "Eating Window":
            EatingWindowContentView()
        case "Lifestyle Factors":
            Text("Lifestyle Factors screen removed")
                .foregroundColor(.white)
        case "Dietary Restrictions":
            DietaryRestrictionsContentView()
        case "Nutrition Preferences":
            Text("Nutrition Preferences screen removed")
                .foregroundColor(.white)
        case "Energy Patterns":
            Text("Energy Patterns screen removed")
                .foregroundColor(.white)
        case "Notification Preferences":
            Text("Notification Preferences screen removed")
                .foregroundColor(.white)
            
        // Finish Section
        case "Review Program":
            EnhancedFinishView()
            
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
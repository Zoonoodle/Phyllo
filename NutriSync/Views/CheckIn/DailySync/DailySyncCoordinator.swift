//
//  DailySyncCoordinator.swift
//  NutriSync
//
//  Simplified daily sync flow with onboarding-style navigation
//

import SwiftUI

struct DailySyncCoordinator: View {
    @StateObject private var viewModel = DailySyncViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var dataProvider: FirebaseDataProvider

    let isMandatory: Bool

    @State private var showDailySyncSheet = true  // For WindowPreviewView binding
    @State private var showDailySyncTour = false
    private let tourManager = TourManager.shared

    init(isMandatory: Bool = false) {
        self.isMandatory = isMandatory
    }

    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            dailySyncContent

            // Daily Sync Tour overlay
            if showDailySyncTour {
                DailySyncTour(
                    onComplete: {
                        tourManager.completeDailySyncTour()
                        showDailySyncTour = false
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            viewModel.setupFlow()

            // Show Daily Sync tour if first time
            if tourManager.shouldShowDailySyncTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showDailySyncTour = true
                }
            }
        }
    }

    private var dailySyncContent: some View {
        VStack(spacing: 0) {
            // Progress dots at top (matching onboarding) - hide on greeting and complete screens
            if viewModel.currentScreen != .greeting && viewModel.currentScreen != .complete {
                DailySyncProgressDots(
                    totalSteps: viewModel.screenFlow.count - 2, // Exclude greeting and complete
                    currentStep: viewModel.currentIndex
                )
                .padding(.top, 60)
                .padding(.bottom, 40)
            }

            // Carousel content with onboarding-style animation
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ForEach(0..<viewModel.screenFlow.count, id: \.self) { index in
                        getScreenContentView(at: index)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .offset(x: -CGFloat(viewModel.currentIndex) * geometry.size.width)
                .animation(.spring(response: 0.5, dampingFraction: 0.85, blendDuration: 0), value: viewModel.currentIndex)
            }
        }
    }

    @ViewBuilder
    private func getScreenContentView(at index: Int) -> some View {
        let screen = index >= 0 && index < viewModel.screenFlow.count
            ? viewModel.screenFlow[index]
            : .greeting

        switch screen {
        case .greeting:
            GreetingView(viewModel: viewModel)
        case .wakeStatusCheck:
            WakeStatusCheckView(viewModel: viewModel)
        case .planningModeChoice:
            PlanningModeChoiceView(viewModel: viewModel)
        case .weightCheck:
            WeightCheckView(viewModel: viewModel)
        case .alreadyEaten:
            AlreadyEatenViewStyled(viewModel: viewModel)
        case .schedule:
            ScheduleViewStyled(viewModel: viewModel)
        case .dailyContext:
            DailyContextInputView(viewModel: viewModel)
        case .complete:
            WindowPreviewWrapper(
                viewModel: viewModel,
                showDailySync: $showDailySyncSheet,
                dismiss: dismiss
            )
        }
    }
}

// MARK: - Window Preview Wrapper
/// Wrapper view that handles loading state and creates WindowPreviewView
struct WindowPreviewWrapper: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @Binding var showDailySync: Bool
    let dismiss: DismissAction
    @State private var hasTriggeredGeneration = false

    var body: some View {
        ZStack {
            if viewModel.isGeneratingWindows {
                // Show loading while generating
                DailySyncProcessingView()
                    .transition(.opacity)
                    .onAppear {
                        // Ensure keyboard is dismissed during loading
                        dismissKeyboard()
                    }
            } else if viewModel.generationError != nil {
                // Show generic error state for other errors
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Couldn't Generate Windows")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)

                    Text(viewModel.generationError?.localizedDescription ?? "An error occurred")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Go Back") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.5))

                        Button("Retry") {
                            viewModel.generationError = nil
                            hasTriggeredGeneration = false
                            Task {
                                await viewModel.generateWindowsForPreview()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.nutriSyncAccent)
                    }
                }
                .transition(.opacity)
            } else if let previewVM = viewModel.windowPreviewViewModel {
                // Show preview when ready
                WindowPreviewView(
                    viewModel: previewVM,
                    showDailySync: $showDailySync,
                    onAccept: {
                        // Complete the sync (save data, process meals)
                        await viewModel.completeSyncAfterPreview()
                        // Schedule notifications for the saved windows
                        if let windows = viewModel.generatedWindows {
                            await NotificationManager.shared.scheduleWindowNotifications(for: windows)
                        }
                        // Cancel today's dailySync reminder since sync is now complete
                        NotificationManager.shared.cancelDailySyncReminder()
                        // Schedule tomorrow's dailySync reminder at user's wake time
                        await NotificationManager.shared.scheduleDailySyncReminder(
                            for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                            wakeTime: viewModel.userProfile?.typicalWakeTime
                        )
                    }
                )
                .transition(.opacity)
            } else if !hasTriggeredGeneration && viewModel.currentScreen == .complete {
                // Waiting for onChange to trigger generation
                DailySyncProcessingView()
            } else {
                // Already triggered but waiting - show loading as fallback
                DailySyncProcessingView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isGeneratingWindows)
        .animation(.easeInOut(duration: 0.3), value: viewModel.windowPreviewViewModel != nil)
        .animation(.easeInOut(duration: 0.3), value: viewModel.generationError != nil)
        .onChange(of: showDailySync) { _, newValue in
            if !newValue {
                dismiss()
            }
        }
        .onChange(of: viewModel.currentScreen) { _, newScreen in
            // Trigger generation when user navigates to the complete screen
            // NOTE: We only use onChange, NOT onAppear, to avoid race condition
            if newScreen == .complete && !hasTriggeredGeneration && viewModel.windowPreviewViewModel == nil {
                // Dismiss keyboard when entering this screen
                dismissKeyboard()
                hasTriggeredGeneration = true
                Task {
                    await viewModel.generateWindowsForPreview()
                }
            }
        }
    }

    /// Dismiss any active keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Model
@MainActor
class DailySyncViewModel: ObservableObject {
    @Published var currentScreen: DailySyncScreen = .greeting
    @Published var syncData = DailySync()
    @Published var alreadyEatenMeals: [QuickMeal] = []
    @Published var workStart: Date
    @Published var workEnd: Date
    @Published var hasWorkToday = true
    @Published var workoutTime: Date?
    @Published var energyLevel: SimpleEnergyLevel = .good
    @Published var isGeneratingWindows = false  // Track window generation
    @Published var recordedWeight: Double? = nil  // Track if weight was recorded
    @Published var generationError: WindowGenerationError? = nil  // Track generation errors

    // Store daily context description
    @Published var dailyContextDescription: String?

    // Store AI-generated insights for display
    @Published var lastGeneratedInsights: [String]?

    // Late-day planning support
    @Published var wakeStatus: WakeStatus = .notAsked
    @Published var planningMode: PlanningMode = .today
    @Published var targetDate: Date = Date()

    /// Whether we need to ask about wake status (afternoon or later)
    var needsWakeStatusCheck: Bool {
        SyncContext.current().needsWakeStatusCheck
    }

    // NEW: Window Preview - stores generated windows before user accepts
    @Published var generatedWindows: [MealWindow]?
    @Published var userProfile: UserProfile?
    @Published var windowPreviewViewModel: WindowPreviewViewModel?

    var screenFlow: [DailySyncScreen] = []
    var currentIndex = 0

    init() {
        // Initialize work times to sensible defaults, rounded to 15 minutes
        let now = Date()
        let calendar = Calendar.current

        // Default work start: 9:00 AM today
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = 9
        startComponents.minute = 0
        self.workStart = calendar.date(from: startComponents) ?? now

        // Default work end: 5:00 PM today
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = 17
        endComponents.minute = 0
        self.workEnd = calendar.date(from: endComponents) ?? now
    }

    // NEW: Computed property for progress tracking
    var currentScreenIndex: Int {
        return currentIndex
    }

    var screens: [DailySyncScreen] {
        return screenFlow
    }

    // Setup dynamic flow based on context
    func setupFlow() {
        let context = SyncContext.current()
        var screens: [DailySyncScreen] = [.greeting]

        // Late-day: Add wake status check (afternoon or later)
        if context.needsWakeStatusCheck {
            screens.append(.wakeStatusCheck)
            // planningModeChoice is added dynamically based on wake status answer
        }

        // Check if we should prompt for weight
        Task {
            do {
                // Load weight history first
                try await WeightTrackingManager.shared.loadWeightHistory()

                // Get user profile for goal
                let profile = try await FirebaseDataProvider.shared.getUserProfile()

                if let profile = profile {
                    let shouldWeigh = WeightCheckSchedule.shouldPromptForWeighIn(
                        lastWeighIn: WeightTrackingManager.shared.lastWeightEntry?.date,
                        goal: profile.primaryGoal,
                        syncContext: context,
                        onboardingCompletedAt: profile.onboardingCompletedAt
                    )

                    if shouldWeigh {
                        // Insert weight check after greeting (or after wakeStatusCheck if present)
                        await MainActor.run {
                            if !self.screenFlow.contains(.weightCheck) {
                                // Insert after wake status check or greeting
                                let insertIndex = self.screenFlow.contains(.wakeStatusCheck) ? 2 : 1
                                self.screenFlow.insert(.weightCheck, at: min(insertIndex, self.screenFlow.count))
                            }
                        }
                    }
                }
            } catch {
                print("Failed to check weight schedule: \(error)")
            }
        }

        // Daily context screen captures schedule + energy + context in natural language
        // Note: Food already eaten is now captured via daily context description
        // instead of a separate screen - AI will parse food mentions from the context
        screens.append(.dailyContext)

        screens.append(.complete)

        self.screenFlow = screens
        self.currentScreen = screens[0]
    }

    func nextScreen() {
        guard currentIndex < screenFlow.count - 1 else { return }
        currentIndex += 1
        currentScreen = screenFlow[currentIndex]
    }
    
    func previousScreen() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        currentScreen = screenFlow[currentIndex]
    }

    // MARK: - Wake Status & Planning Mode Handling

    /// Handle wake status selection - determines planning mode flow
    func setWakeStatus(_ status: WakeStatus) {
        self.wakeStatus = status

        switch status {
        case .justWoke:
            // User just woke up - treat as their "morning", plan rest of today
            planningMode = .lateDayToday
            targetDate = Date()
            // Skip planning mode choice, go to next screen
            nextScreen()

        case .beenAwakeAllDay:
            // User has been awake all day - offer tomorrow planning
            planningMode = .tomorrow
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            // Insert planning mode choice screen after wake status
            insertScreen(.planningModeChoice, after: .wakeStatusCheck)
            nextScreen()

        case .notAsked:
            nextScreen()
        }
    }

    /// Handle planning mode selection
    func setPlanningMode(_ mode: PlanningMode) {
        self.planningMode = mode

        switch mode {
        case .tomorrow:
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            // Remove alreadyEaten screen if present (not needed for tomorrow planning)
            removeScreen(.alreadyEaten)

        case .today:
            targetDate = Date()
            // Add back alreadyEaten screen if appropriate
            let context = SyncContext.current()
            if context.shouldAskAboutEatenMeals && !screenFlow.contains(.alreadyEaten) {
                // Insert before dailyContext
                insertScreen(.alreadyEaten, before: .dailyContext)
            }

        case .lateDayToday:
            targetDate = Date()
            // Keep or add alreadyEaten for context
            let context = SyncContext.current()
            if context.shouldAskAboutEatenMeals && !screenFlow.contains(.alreadyEaten) {
                insertScreen(.alreadyEaten, before: .dailyContext)
            }
        }

        nextScreen()
    }

    /// Insert a screen dynamically after another screen
    func insertScreen(_ screen: DailySyncScreen, after: DailySyncScreen) {
        guard let index = screenFlow.firstIndex(of: after) else { return }
        if !screenFlow.contains(screen) {
            screenFlow.insert(screen, at: index + 1)
        }
    }

    /// Insert a screen dynamically before another screen
    func insertScreen(_ screen: DailySyncScreen, before: DailySyncScreen) {
        guard let index = screenFlow.firstIndex(of: before) else { return }
        if !screenFlow.contains(screen) {
            screenFlow.insert(screen, at: index)
        }
    }

    /// Remove a screen from the flow
    func removeScreen(_ screen: DailySyncScreen) {
        screenFlow.removeAll { $0 == screen }
    }

    // Save daily context method
    func saveDailyContext(_ context: String?) {
        self.dailyContextDescription = context
    }

    /// Generate windows for preview WITHOUT saving to Firebase
    /// Windows are stored temporarily and only saved when user accepts
    func generateWindowsForPreview() async {
        isGeneratingWindows = true

        do {
            // Get user profile
            guard let profile = try await FirebaseDataProvider.shared.getUserProfile() else {
                DebugLogger.shared.error("No user profile found for window preview")
                isGeneratingWindows = false
                return
            }
            self.userProfile = profile

            // Build sync data for generation with planning mode support
            let workSchedule = hasWorkToday ? TimeRange(start: workStart, end: workEnd) : nil
            syncData = DailySync(
                syncContext: SyncContext.current(),
                alreadyConsumed: planningMode == .tomorrow ? [] : alreadyEatenMeals, // Skip meals if planning tomorrow
                workSchedule: workSchedule,
                workoutTime: workoutTime,
                dailyContextDescription: dailyContextDescription,
                planningMode: planningMode,
                targetDate: targetDate
            )

            // Convert to MorningCheckInData for AI service compatibility
            let checkInData = convertToCheckInData(syncData, profile: profile)

            // Generate windows through AI service (without saving)
            // Use targetDate instead of Date() to support tomorrow planning
            let (windows, _, contextInsights) = try await AIWindowGenerationService.shared.generateWindows(
                for: profile,
                checkIn: checkInData,
                dailySync: syncData,
                date: targetDate
            )

            // Store generated data
            self.generatedWindows = windows
            self.lastGeneratedInsights = contextInsights

            // Create WindowPreviewViewModel
            self.windowPreviewViewModel = WindowPreviewViewModel(
                windows: windows,
                profile: profile,
                contextInsights: contextInsights ?? []
            )

            DebugLogger.shared.success("Generated \(windows.count) windows for preview")

        } catch let error as WindowGenerationError {
            DebugLogger.shared.error("Failed to generate windows for preview: \(error)")
            self.generationError = error
        } catch {
            DebugLogger.shared.error("Failed to generate windows for preview: \(error)")
            // Wrap unknown errors
            self.generationError = .noResponse
        }

        isGeneratingWindows = false
    }

    /// Convert DailySync to MorningCheckInData for AI service compatibility
    private func convertToCheckInData(_ sync: DailySync, profile: UserProfile) -> MorningCheckInData? {
        let calendar = Calendar.current
        let today = Date()

        // Use profile's typical wake time (crucial for night shift workers)
        // Extract hour/minute from profile and apply to today's date
        let wakeTime: Date
        if let typicalWake = profile.typicalWakeTime {
            let wakeHour = calendar.component(.hour, from: typicalWake)
            let wakeMinute = calendar.component(.minute, from: typicalWake)
            var wakeComponents = calendar.dateComponents([.year, .month, .day], from: today)
            wakeComponents.hour = wakeHour
            wakeComponents.minute = wakeMinute
            wakeTime = calendar.date(from: wakeComponents) ?? today
        } else {
            // Fallback to 7 AM if not set
            var wakeComponents = calendar.dateComponents([.year, .month, .day], from: today)
            wakeComponents.hour = 7
            wakeComponents.minute = 0
            wakeTime = calendar.date(from: wakeComponents) ?? today
        }

        // Use profile's typical sleep time (important for night shift workers who sleep during the day)
        let plannedBedtime: Date
        if let typicalSleep = profile.typicalSleepTime {
            let sleepHour = calendar.component(.hour, from: typicalSleep)
            let sleepMinute = calendar.component(.minute, from: typicalSleep)
            var bedComponents = calendar.dateComponents([.year, .month, .day], from: today)
            bedComponents.hour = sleepHour
            bedComponents.minute = sleepMinute
            plannedBedtime = calendar.date(from: bedComponents) ?? today.addingTimeInterval(16 * 3600)
        } else {
            // Fallback to 11 PM if not set
            var bedComponents = calendar.dateComponents([.year, .month, .day], from: today)
            bedComponents.hour = 23
            bedComponents.minute = 0
            plannedBedtime = calendar.date(from: bedComponents) ?? today.addingTimeInterval(16 * 3600)
        }

        // Build planned activities from workout time if available
        var plannedActivities: [String] = []
        if let workoutTime = sync.workoutTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            plannedActivities.append("Workout at \(formatter.string(from: workoutTime))")
        }

        return MorningCheckInData(
            date: today,
            wakeTime: wakeTime,
            plannedBedtime: plannedBedtime,
            sleepQuality: 3,
            energyLevel: 3,
            hungerLevel: 3,
            dayFocus: [],
            morningMood: nil,
            plannedActivities: plannedActivities,
            windowPreference: .auto,
            hasRestrictions: false,
            restrictions: []
        )
    }

    /// Save sync data and process already eaten meals (called after user accepts windows)
    func completeSyncAfterPreview() async {
        // Save the sync data to Firebase
        do {
            try await FirebaseDataProvider.shared.saveDailySync(syncData)

            // CRITICAL: Update DailySyncManager state so UI knows sync is complete
            await MainActor.run {
                DailySyncManager.shared.todaySync = syncData
                DailySyncManager.shared.hasCompletedDailySync = true
            }

            // Process already consumed meals through AI analysis
            if !syncData.alreadyConsumed.isEmpty {
                await processAlreadyConsumedMeals(syncData.alreadyConsumed)
            }

            DebugLogger.shared.success("Daily sync completed after preview")
        } catch {
            DebugLogger.shared.error("Failed to save sync data: \(error)")
        }
    }

    /// Process already consumed meals through AI analysis
    private func processAlreadyConsumedMeals(_ meals: [QuickMeal]) async {
        for quickMeal in meals {
            do {
                // Use MealCaptureService for proper AI analysis pipeline
                _ = try await MealCaptureService.shared.startMealAnalysis(
                    image: nil,
                    voiceTranscript: quickMeal.name,
                    barcode: nil,
                    timestamp: quickMeal.time
                )
                DebugLogger.shared.success("Started analysis for: '\(quickMeal.name)'")
            } catch {
                DebugLogger.shared.error("Failed to process meal '\(quickMeal.name)': \(error)")
            }
        }
    }

    func saveSyncData() async {
        // Start loading state
        await MainActor.run {
            isGeneratingWindows = true
        }
        
        let workSchedule = hasWorkToday ? TimeRange(start: workStart, end: workEnd) : nil
        
        syncData = DailySync(
            syncContext: SyncContext.current(),
            alreadyConsumed: alreadyEatenMeals,
            workSchedule: workSchedule,
            workoutTime: workoutTime,
            dailyContextDescription: dailyContextDescription  // NEW
        )
        
        // Save to Firebase and trigger window generation
        await DailySyncManager.shared.saveDailySync(syncData)
        
        // Windows are now generating, the loading view will be shown
        // The dismiss will happen after generation completes
    }
}

// MARK: - Screen Types
enum DailySyncScreen {
    case greeting
    case wakeStatusCheck    // Late-day: "Have you been awake a while?"
    case planningModeChoice // Late-day: "Plan tomorrow?" with today option
    case weightCheck        // Weight tracking screen
    case alreadyEaten
    case schedule
    case dailyContext       // Rich voice/text context input
    case complete
}

// MARK: - Greeting View (Onboarding Style)
struct GreetingView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Icon matching context
            Image(systemName: SyncContext.current().icon)
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(.nutriSyncAccent)
                .padding(.bottom, 32)
            
            DailySyncHeader(
                title: SyncContext.current().greeting,
                subtitle: "Let's quickly sync your nutrition plan"
            )
            
            Spacer()
            
            // Single Continue button (no back on first screen)
            DailySyncBottomNav(
                onBack: nil,
                onNext: { viewModel.nextScreen() },
                nextButtonTitle: "Get Started",
                showBack: false
            )
        }
    }
}

// MARK: - Already Eaten View (Styled)
struct AlreadyEatenViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @State private var showAddMeal = false
    @State private var mealName = ""
    @State private var mealTime = Date()
    @State private var estimatedCalories = ""
    
    var body: some View {
        VStack(spacing: 0) {
            DailySyncHeader(
                title: "Have you eaten today?",
                subtitle: "I'll adjust your remaining meals accordingly"
            )
            .padding(.top, 40)
            
            Spacer()
            
            // Meal list or empty state
            if viewModel.alreadyEatenMeals.isEmpty {
                VStack(spacing: 24) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No meals logged yet")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Button(action: { showAddMeal = true }) {
                        Label("Add a meal", systemImage: "plus.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.alreadyEatenMeals) { meal in
                            QuickMealRow(meal: meal) {
                                viewModel.alreadyEatenMeals.removeAll { $0.id == meal.id }
                            }
                        }
                        
                        Button(action: { showAddMeal = true }) {
                            Label("Add another meal", systemImage: "plus.circle")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.nutriSyncAccent)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            Spacer()
            
            // Navigation
            DailySyncBottomNav(
                onBack: { viewModel.previousScreen() },
                onNext: { viewModel.nextScreen() }
            )
        }
        .sheet(isPresented: $showAddMeal) {
            EnhancedMealEntry(
                mealName: $mealName,
                mealTime: $mealTime,
                estimatedCalories: $estimatedCalories,
                onSave: {
                    let meal = QuickMeal(
                        name: mealName.isEmpty ? "Unnamed meal" : mealName,
                        time: mealTime,
                        estimatedCalories: Int(estimatedCalories)
                    )
                    viewModel.alreadyEatenMeals.append(meal)
                    // Reset fields for next entry
                    mealName = ""
                    estimatedCalories = ""
                    mealTime = Date()
                }
            )
        }
    }
}

// MARK: - Schedule View (Styled)
struct ScheduleViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            DailySyncHeader(
                title: "What's your schedule?",
                subtitle: "I'll time your meals perfectly around your day"
            )
            .padding(.top, 40)
            
            Spacer()
            
            VStack(spacing: 20) {
                // Work toggle
                Toggle(isOn: $viewModel.hasWorkToday) {
                    HStack(spacing: 12) {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.white.opacity(0.7))
                        Text("Working today")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .tint(.nutriSyncAccent)
                .padding(.horizontal, 24)
                
                // Work hours (if working)
                if viewModel.hasWorkToday {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Work hours")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            TimePickerCompact(
                                label: "Start",
                                time: $viewModel.workStart
                            )
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white.opacity(0.3))
                            
                            TimePickerCompact(
                                label: "End",
                                time: $viewModel.workEnd
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Workout toggle
                VStack(spacing: 16) {
                    Toggle(isOn: Binding(
                        get: { viewModel.workoutTime != nil },
                        set: { hasWorkout in
                            if hasWorkout {
                                // Set to current time rounded to nearest 15 minutes
                                let calendar = Calendar.current
                                let now = Date()
                                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                                guard let minute = components.minute else {
                                    viewModel.workoutTime = now
                                    return
                                }

                                // Round to nearest 15 minutes
                                let roundedMinute = (minute + 7) / 15 * 15
                                var newComponents = components
                                newComponents.minute = roundedMinute % 60

                                // Handle hour overflow if minute rounds to 60
                                if roundedMinute >= 60, let hour = components.hour {
                                    newComponents.hour = hour + 1
                                    newComponents.minute = 0
                                }

                                viewModel.workoutTime = calendar.date(from: newComponents) ?? now
                            } else {
                                viewModel.workoutTime = nil
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: "figure.run")
                                .foregroundColor(.white.opacity(0.7))
                            Text("Planning to workout")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.nutriSyncAccent)
                    
                    if viewModel.workoutTime != nil {
                        TimePickerCompact(
                            label: "Workout time",
                            time: Binding(
                                get: { viewModel.workoutTime ?? Date() },
                                set: { viewModel.workoutTime = $0 }
                            )
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Navigation
            DailySyncBottomNav(
                onBack: { viewModel.previousScreen() },
                onNext: { viewModel.nextScreen() }
            )
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.hasWorkToday)
        .animation(.easeInOut(duration: 0.3), value: viewModel.workoutTime != nil)
    }
}

// MARK: - Complete View (Styled)
struct CompleteViewStyled: View {
    @ObservedObject var viewModel: DailySyncViewModel
    let dismiss: DismissAction
    @State private var windowsGenerated = false
    
    var body: some View {
        ZStack {
            // Main content
            if !viewModel.isGeneratingWindows {
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Success animation
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.nutriSyncAccent)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: true)
                        .padding(.bottom, 32)
                    
                    DailySyncHeader(
                        title: "Perfect!",
                        subtitle: "I'm creating your personalized meal schedule for today"
                    )

                    // NEW: Show AI insights if daily context was provided
                    if let insights = viewModel.lastGeneratedInsights, !insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("I understood:")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.phylloTextSecondary)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(insights, id: \.self) { insight in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.nutriSyncAccent)

                                        Text(insight)
                                            .font(.body)
                                            .foregroundColor(.phylloText)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                    }

                    Spacer()
                    
                    // Single button to complete (no back on final screen)
                    DailySyncBottomNav(
                        onBack: nil,
                        onNext: {
                            Task {
                                await viewModel.saveSyncData()
                                // Wait for windows to generate (they're triggered automatically)
                                // Adding a small delay to ensure generation completes
                                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                                
                                await MainActor.run {
                                    windowsGenerated = true
                                    // Small delay before dismissing to show completion
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        dismiss()
                                    }
                                }
                            }
                        },
                        nextButtonTitle: "View Schedule",
                        showBack: false
                    )
                }
                .onAppear {
                    // Trigger haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()

                    // Load context insights if available (they were saved during window generation)
                    Task {
                        if let insights = try? await FirebaseDataProvider.shared.getContextInsights(for: Date()) {
                            await MainActor.run {
                                viewModel.lastGeneratedInsights = insights
                            }
                        }
                    }
                }
            }
            
            // Loading overlay
            if viewModel.isGeneratingWindows {
                DailySyncProcessingView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isGeneratingWindows)
    }
}

// MARK: - Helper Components
struct TimePickerCompact: View {
    let label: String
    @Binding var time: Date

    @State private var selectedHour24: Int = 9  // Store as 24-hour (0-23)
    @State private var selectedMinute: Int = 0

    private let hours24 = Array(0...23)  // All 24 hours
    private let minutes = [0, 15, 30, 45]

    // Computed property to determine AM/PM
    private var period: String {
        selectedHour24 < 12 ? "AM" : "PM"
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))

            ZStack(alignment: .topTrailing) {
                // Time pickers
                HStack(spacing: 4) {
                    // Hour picker (shows 1-12 only)
                    Picker("", selection: $selectedHour24) {
                        ForEach(hours24, id: \.self) { hour24 in
                            Text("\(hour24To12(hour24))")
                                .foregroundColor(.white)
                                .tag(hour24)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 50, height: 80)
                    .clipped()

                    Text(":")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 18, weight: .medium))

                    // Minute picker (15-minute intervals only)
                    Picker("", selection: $selectedMinute) {
                        ForEach(minutes, id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .foregroundColor(.white)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 50, height: 80)
                    .clipped()
                }
                .colorScheme(.dark)

                // AM/PM indicator (top-right)
                Text(period)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.nutriSyncAccent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nutriSyncAccent.opacity(0.15))
                    )
                    .offset(x: -4, y: 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .onAppear {
            // Initialize from binding
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            selectedHour24 = components.hour ?? 9

            // Round minute to nearest 15
            let rawMinute = components.minute ?? 0
            selectedMinute = (rawMinute + 7) / 15 * 15
            if selectedMinute >= 60 {
                selectedMinute = 0
            }
        }
        .onChange(of: selectedHour24) { _ in
            updateTime()
        }
        .onChange(of: selectedMinute) { _ in
            updateTime()
        }
    }

    /// Convert 24-hour to 12-hour display (1-12)
    private func hour24To12(_ hour24: Int) -> Int {
        if hour24 == 0 {
            return 12
        } else if hour24 <= 12 {
            return hour24
        } else {
            return hour24 - 12
        }
    }

    private func updateTime() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: time)
        components.hour = selectedHour24
        components.minute = selectedMinute

        if let newDate = calendar.date(from: components) {
            time = newDate
        }
    }
}

// MARK: - Quick Meal Row

private struct QuickMealRow: View {
    let meal: QuickMeal
    let onDelete: () -> Void

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Text(timeFormatter.string(from: meal.time))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if let calories = meal.estimatedCalories {
                Text("\(calories) cal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    DailySyncCoordinator()
        .preferredColorScheme(.dark)
        .environmentObject(FirebaseDataProvider.shared)
}
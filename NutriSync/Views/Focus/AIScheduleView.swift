import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AIScheduleView: View {
    @Binding var showDeveloperDashboard: Bool
    @Binding var scrollToAnalyzingMeal: AnalyzingMeal?
    @StateObject private var viewModel = AIScheduleViewModel()
    @State private var selectedDate = Date()
    @State private var selectedWindow: MealWindow?
    @State private var showWindowDetail = false
    @State private var selectedMealId: String?
    @State private var showMissedMealsRecovery = false
    @State private var showMorningCheckIn = false
    @State private var showDayDetail = false
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            // Background color that extends to edges
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add safe area top padding
                Color.clear
                    .frame(height: 50)
                
                VStack(spacing: 2) {
                    // Day navigation header with integrated logo and settings
                    DayNavigationHeader(
                        selectedDate: $selectedDate,
                        showDeveloperDashboard: $showDeveloperDashboard,
                        showDayDetail: $showDayDetail,
                        meals: viewModel.meals,
                        userProfile: viewModel.userProfile
                    )
                    .background(Color.nutriSyncBackground)
                    .zIndex(2) // Keep header above timeline content
                    .opacity(showWindowDetail ? 0 : 1)
                    
                    // Content based on state
                    if viewModel.legacyViewModel.isLoading || !viewModel.hasLoadedInitialData || viewModel.isGeneratingWindows {
                        loadingView
                    } else if viewModel.mealWindows.isEmpty {
                        emptyStateView
                    } else {
                        // Use the simplified TimelineView for correct positioning
                        SimpleTimelineView(
                            viewModel: viewModel.legacyViewModel,
                            selectedWindow: $selectedWindow,
                            showWindowDetail: $showWindowDetail,
                            animationNamespace: animationNamespace
                        )
                        .frame(maxWidth: .infinity) // Constrain width to prevent horizontal expansion
                        .opacity(showWindowDetail ? 0 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .overlay(alignment: .center) {
            // Window detail overlay
            if showWindowDetail, let window = selectedWindow {
                WindowDetailOverlay(
                    window: window,
                    viewModel: viewModel.legacyViewModel,
                    showWindowDetail: $showWindowDetail,
                    selectedMealId: $selectedMealId,
                    animationNamespace: animationNamespace
                )
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .opacity.animation(.easeInOut(duration: 0.2))
                ))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToMealDetails)) { notification in
            if let meal = notification.object as? LoggedMeal {
                // Find the window containing this meal
                if let window = viewModel.mealWindows.first(where: { window in
                    meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                }) {
                    // Navigate to window detail with specific meal selected
                    selectedWindow = window
                    selectedMealId = meal.id.uuidString
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showWindowDetail = true
                    }
                }
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            Task {
                await viewModel.loadDailyPlan(for: newDate)
            }
        }
        .onAppear {
            // Wait a moment for the legacyViewModel to initialize properly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                checkForMissedMeals()
            }
            
            // Mark as loaded once the legacyViewModel finishes loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Check if loading is complete
                if !viewModel.legacyViewModel.isLoading {
                    viewModel.hasLoadedInitialData = true
                }
            }
            
            // Only load daily plan if not already loading
            if !viewModel.legacyViewModel.isLoading {
                Task {
                    await viewModel.loadDailyPlan(for: selectedDate)
                }
            }
        }
        .onChange(of: viewModel.legacyViewModel.isLoading) { _, newValue in
            // When loading completes, mark initial data as loaded
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    viewModel.hasLoadedInitialData = true
                }
            }
        }
        .sheet(isPresented: $showMissedMealsRecovery) {
            MissedMealsRecoveryView(
                viewModel: viewModel.legacyViewModel,
                missedWindows: viewModel.missedWindows
            )
        }
        .sheet(isPresented: $showMorningCheckIn) {
            MorningCheckInCoordinator(isMandatory: viewModel.mealWindows.isEmpty)
                .interactiveDismissDisabled(viewModel.mealWindows.isEmpty) // Can't dismiss if no windows
        }
        .sheet(isPresented: $showDayDetail) {
            DayDetailView(
                viewModel: viewModel.legacyViewModel,
                showDayDetail: $showDayDetail
            )
        }
        .sheet(isPresented: .constant(viewModel.legacyViewModel.showingRedistributionNudge)) {
            if let redistribution = viewModel.legacyViewModel.pendingRedistribution {
                RedistributionNudge(
                    result: redistribution,
                    currentWindows: viewModel.mealWindows,
                    onAccept: {
                        Task {
                            await viewModel.legacyViewModel.applyRedistribution()
                        }
                    },
                    onDecline: {
                        viewModel.legacyViewModel.rejectRedistribution()
                    }
                )
            }
        }
        .onChange(of: showMorningCheckIn) { wasShowing, isShowing in
            // When check-in sheet dismisses, show loading while windows generate
            if wasShowing && !isShowing {
                // User completed or dismissed check-in
                viewModel.isGeneratingWindows = true
                
                // Trigger window generation
                Task {
                    // Get the latest morning check-in data
                    if let checkIn = CheckInManager.shared.getLatestMorningCheckIn() {
                        // Convert to the format expected by ScheduleViewModel
                        let checkInData = MorningCheckInData(
                            date: checkIn.date,
                            wakeTime: checkIn.wakeTime,
                            plannedBedtime: checkIn.plannedBedtime,
                            sleepQuality: checkIn.sleepQuality,
                            energyLevel: checkIn.energyLevel,
                            hungerLevel: checkIn.hungerLevel,
                            dayFocus: checkIn.dayFocus,
                            morningMood: checkIn.morningMood,
                            plannedActivities: checkIn.plannedActivities,
                            windowPreference: checkIn.windowPreference,
                            hasRestrictions: checkIn.hasRestrictions,
                            restrictions: checkIn.restrictions
                        )
                        
                        // Save check-in and generate windows
                        await viewModel.legacyViewModel.completeMorningCheckIn(checkInData)
                    }
                    
                    // Monitor for windows to appear
                    await MainActor.run {
                        checkForWindowGeneration()
                    }
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(viewModel.isGeneratingWindows ? "Generating your personalized schedule..." : "Loading your personalized schedule...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Show loading indicator if still loading
            if viewModel.legacyViewModel.isLoading || !viewModel.hasLoadedInitialData {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading your schedule...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            } else {
                // Only show check-in button if no windows exist
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("No meal plan for today")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Complete your morning check-in to generate\na personalized meal schedule")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Button(action: { showMorningCheckIn = true }) {
                    Label("Start Morning Check-In", systemImage: "sun.max.fill")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func checkForWindowGeneration() {
        // Check if windows have been generated
        if !viewModel.mealWindows.isEmpty {
            // Windows are ready, stop showing loading
            viewModel.isGeneratingWindows = false
        } else {
            // Still waiting, check again in a moment
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if viewModel.isGeneratingWindows {
                    checkForWindowGeneration()
                }
            }
            
            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                viewModel.isGeneratingWindows = false
            }
        }
    }
    
    private func checkForMissedMeals() {
        if !viewModel.missedWindows.isEmpty && !viewModel.hasShownMissedMealsToday {
            // Delay showing missed meals sheet to avoid presentation conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showMissedMealsRecovery = true
                viewModel.markMissedMealsShown()
            }
        }
    }
}

// MARK: - AI Schedule View Model

@MainActor
class AIScheduleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedInitialData = false
    @Published var isGeneratingWindows = false
    
    // Loading timeout timer
    private var loadingTimeoutTimer: Timer?
    
    // Legacy view model for compatibility - use this as the source of truth
    let legacyViewModel = ScheduleViewModel()
    
    // Computed properties that delegate to legacyViewModel
    var mealWindows: [MealWindow] {
        legacyViewModel.mealWindows
    }
    
    var meals: [LoggedMeal] {
        legacyViewModel.todaysMeals
    }
    
    var userProfile: UserProfile {
        legacyViewModel.userProfile
    }
    
    // User ID (would come from AuthManager in real app)
    let userId = Auth.auth().currentUser?.uid ?? "preview-user"
    
    // Missed windows tracking
    var missedWindows: [MealWindow] {
        return mealWindows.filter { window in
            window.isPast && !window.isMarkedAsFasted && mealsInWindow(window).isEmpty
        }
    }
    
    var hasShownMissedMealsToday: Bool {
        get {
            let key = "hasShownMissedMeals_\(DateFormatter.yyyyMMdd.string(from: Date()))"
            return UserDefaults.standard.bool(forKey: key)
        }
    }
    
    // MARK: - Dependencies
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        // Don't call loadDailyPlan here - let onAppear handle it
        // This prevents duplicate loading and state conflicts
        
        // Start a timeout timer to ensure we don't get stuck loading forever
        startLoadingTimeout()
    }
    
    private func startLoadingTimeout() {
        // Cancel any existing timer
        loadingTimeoutTimer?.invalidate()
        
        // Start a new timer that will mark data as loaded after 5 seconds
        loadingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            Task { @MainActor in
                if !self.hasLoadedInitialData {
                    print("Loading timeout reached - marking as loaded")
                    self.hasLoadedInitialData = true
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadDailyPlan(for date: Date) async {
        // The legacyViewModel already handles loading windows via its observations
        // We just need to check if a daily plan exists for additional metadata
        
        // Don't set our own loading state - rely on legacyViewModel.isLoading
        let dateString = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: date))
        
        do {
            // Check if daily plan exists (for future use with additional metadata)
            let planDoc = try await db.collection("users")
                .document(userId)
                .collection("dailyPlans")
                .document(dateString)
                .getDocument()
            
            if planDoc.exists, let _ = planDoc.data() {
                // Store daily plan data for future features
                // The windows are already loaded by legacyViewModel
                print("Daily plan exists for \(dateString)")
            }
            
        } catch {
            print("Error checking daily plan: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    
    func markMissedMealsShown() {
        let key = "hasShownMissedMeals_\(DateFormatter.yyyyMMdd.string(from: Date()))"
        UserDefaults.standard.set(true, forKey: key)
    }
    
    private func mealsInWindow(_ window: MealWindow) -> [LoggedMeal] {
        meals.filter { meal in
            meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    @Previewable @State var scrollToAnalyzingMeal: AnalyzingMeal?
    
    NavigationStack {
        AIScheduleView(
            showDeveloperDashboard: $showDeveloperDashboard,
            scrollToAnalyzingMeal: $scrollToAnalyzingMeal
        )
    }
    .preferredColorScheme(.dark)
    .environment(\.isPreview, true)
}
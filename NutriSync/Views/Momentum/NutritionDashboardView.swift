//
//  NutritionDashboardView.swift
//  NutriSync
//
//  Nutrition Performance Dashboard - Fitness Tracker Style
//

import SwiftUI

struct NutritionDashboardView: View {
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var viewModel = NutritionDashboardViewModel()
    @StateObject private var insightsEngine = InsightsEngine.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var timeProvider = TimeProvider.shared
    
    @State private var ringAnimations = RingAnimationState()
    @State private var refreshing = false
    @State private var infoPopupData: InfoPopupData? = nil
    
    struct InfoPopupData {
        let title: String
        let description: String
        let color: Color
        let position: CGPoint
    }
    
    enum RingSegment {
        case timing
        case nutrients
        case adherence
    }
    
    struct RingAnimationState {
        var timingProgress: Double = 0
        var nutrientProgress: Double = 0
        var adherenceProgress: Double = 0
        var animating: Bool = false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                // Main content - single scrollable view
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading {
                        // Loading skeleton
                        loadingContent
                    } else {
                        VStack(spacing: 0) {
                            // Header section
                            headerSection
                            
                            // Main performance content
                            VStack(spacing: PerformanceDesignSystem.cardSpacing) {
                                // Hero: Three performance pillars
                                heroSection
                                    .padding(.top, 16)
                                
                                // Current window card (if active)
                                if let activeWindow = viewModel.mealWindows.first(where: { window in
                                    let now = TimeProvider.shared.currentTime
                                    return now >= window.startTime && now <= window.endTime
                                }) {
                                    CurrentWindowCard(window: activeWindow, viewModel: viewModel)
                                        .animation(PerformanceDesignSystem.springAnimation, value: activeWindow.id)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                // Next window card
                                if let nextWindow = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
                                    NextWindowCard(window: nextWindow)
                                        .animation(PerformanceDesignSystem.springAnimation, value: nextWindow.id)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                // Insight card
                                if let topInsight = viewModel.insights.first {
                                    PerformanceInsightCard(
                                        insight: topInsight.message,
                                        action: topInsight.title.contains("Alert") ? "Fix Now" : nil
                                    )
                                    .animation(PerformanceDesignSystem.springAnimation, value: topInsight.message)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                                
                                // Current metrics (removed Current Window and Nutrients Today cards)
                            
                            // Overall Performance Score
                            overallScoreCard
                            
                            // Nutrient breakdown (priority 2)
                            nutrientBreakdownSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    }
                }
                .refreshable {
                    await refresh()
                }
                
                // Info popup overlay
                if let popupData = infoPopupData {
                    InfoFloatingCard(
                        data: popupData,
                        onDismiss: { infoPopupData = nil }
                    )
                }
            }
        }
        .onAppear {
            loadData()
            animateRings()
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        CombinedPerformanceCard(
            timing: .init(
                title: "Timing",
                percentage: timingPercentage,
                color: timingPercentage > 80 ? PerformanceDesignSystem.successMuted : .white.opacity(0.5),
                detail: getTimingMessage(for: timingPercentage),
                onTap: {
                    showTimingInfo()
                }
            ),
            nutrients: .init(
                title: "Nutrients",
                percentage: nutrientPercentage,
                color: nutrientColorGradient,
                detail: getNutrientMessage(for: nutrientPercentage),
                onTap: {
                    showNutrientsInfo()
                }
            ),
            adherence: .init(
                title: "Adherence",
                percentage: adherencePercentage,
                color: .blue.opacity(0.8),
                detail: getAdherenceMessage(for: adherencePercentage),
                onTap: {
                    showAdherenceInfo()
                }
            )
        )
        .animation(PerformanceDesignSystem.springAnimation, value: timingPercentage)
        .animation(PerformanceDesignSystem.springAnimation, value: nutrientPercentage)
        .animation(PerformanceDesignSystem.springAnimation, value: adherencePercentage)
    }
    
    private var nutrientColorGradient: Color {
        switch nutrientPercentage {
        case 0..<30: return .red.opacity(0.6)
        case 30..<60: return .orange.opacity(0.6)
        case 60..<80: return .yellow.opacity(0.6)
        default: return PerformanceDesignSystem.successMuted
        }
    }
    
    private func determineStatus(for percentage: Double) -> PerformancePillarCard.PerformanceStatus {
        if percentage >= 80 {
            return .excellent
        } else if percentage >= 60 {
            return .good
        } else {
            return .needsWork
        }
    }
    
    private func getTimingMessage(for percentage: Double) -> String {
        if percentage >= 80 {
            return "On track today"
        } else if percentage >= 60 {
            return "Minor adjustments"
        } else {
            return "Room to grow"
        }
    }
    
    private func getNutrientMessage(for percentage: Double) -> String {
        if percentage >= 80 {
            return "Great balance"
        } else if percentage >= 60 {
            return "Add variety"
        } else {
            return "Building diversity"
        }
    }
    
    private func getAdherenceMessage(for percentage: Double) -> String {
        if percentage >= 80 {
            return "Strong week"
        } else if percentage >= 60 {
            return "Building momentum"
        } else {
            return "Learning opportunity"
        }
    }
    
    // MARK: - Info Popup Methods
    
    private func showTimingInfo() {
        infoPopupData = InfoPopupData(
            title: "Timing Score",
            description: "Your timing score measures how well you're eating within your scheduled meal windows.\n\n• Perfect timing (100%): Eating within your window\n• Good timing (80%+): Within 15 minutes of window\n• Needs work (<60%): More than 30 minutes off\n\nConsistent meal timing helps optimize your metabolism, energy levels, and circadian rhythm.",
            color: timingPercentage > 80 ? PerformanceDesignSystem.successMuted : .white.opacity(0.5),
            position: .zero
        )
    }
    
    private func showNutrientsInfo() {
        infoPopupData = InfoPopupData(
            title: "Nutrient Score",
            description: "Your nutrient score tracks the quality and diversity of your nutrition.\n\n• Macronutrients (30%): Protein, carbs, and fats balance\n• Micronutrients (50%): Vitamins and minerals coverage\n• Calorie accuracy (20%): Meeting daily targets\n\nCurrently tracking \(nutrientsHit) out of 18 essential nutrients. Focus on eating a variety of colorful, whole foods to improve this score.",
            color: nutrientColorGradient,
            position: .zero
        )
    }
    
    private func showAdherenceInfo() {
        infoPopupData = InfoPopupData(
            title: "Adherence Score",
            description: "Your adherence score reflects how consistently you're following your nutrition plan.\n\n• Meal frequency (40%): Logging all planned meals\n• Window utilization (30%): Using your eating windows\n• Consistent spacing (30%): 3-5 hours between meals\n\nYou've maintained a \(viewModel.currentStreak)-day streak! Keep building these healthy habits for long-term success.",
            color: .blue.opacity(0.8),
            position: .zero
        )
    }
    
    // MARK: - Loading State
    
    private var loadingContent: some View {
        VStack(spacing: PerformanceDesignSystem.cardSpacing) {
            // Header skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .frame(height: 60)
                .shimmering()
            
            // Hero cards skeleton
            HStack(spacing: PerformanceDesignSystem.cardSpacing) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: PerformanceDesignSystem.cornerRadius)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 100)
                        .shimmering()
                }
            }
            
            // Metric cards skeleton
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: PerformanceDesignSystem.cornerRadius)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 80)
                    .shimmering()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        PerformanceHeaderView(
            showDeveloperDashboard: $showDeveloperDashboard,
            meals: viewModel.todaysMeals,
            userProfile: viewModel.userProfile
        )
        .safeAreaPadding(.top)
    }
    
    
    private var liveMetricsGrid: some View {
        // Removed Current Window and Nutrients Today cards
        EmptyView()
    }
    
    struct MetricCard: View {
        let title: String
        let mainValue: String
        let subValue: String
        let progress: Double
        let color: Color
        let icon: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.nutriSyncTextSecondary)
                    Spacer()
                }
                
                Text(mainValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subValue)
                    .font(.system(size: 12))
                    .foregroundColor(.nutriSyncTextTertiary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.nutriSyncBorder)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.8))
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 4)
            }
            .padding(16)
            .background(Color.nutriSyncElevated)
            .cornerRadius(12)
        }
    }
    
    private var currentWindowCard: some View {
        VStack(spacing: 20) {
            // Header with next window info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT MEAL WINDOW")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.nutriSyncTextTertiary)
                        .tracking(0.5)
                    
                    HStack(spacing: 8) {
                        Text(nextWindowName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        if let timeUntil = timeUntilNextWindow {
                            Text("• \(timeUntil)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nutriSyncTextSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Time badge
                VStack(alignment: .trailing, spacing: 4) {
                    Text(nextWindowTime)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let duration = nextWindowDuration {
                        Text(duration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.nutriSyncTextTertiary)
                    }
                }
            }
            
            // Enhanced timeline with labels
            VStack(spacing: 8) {
                // Timeline visualization
                windowTimelinePreview
                
                // Window labels
                HStack {
                    ForEach(["Completed", "Missed", "Upcoming", "Next"], id: \.self) { label in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(legendColor(for: label))
                                .frame(width: 8, height: 8)
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.nutriSyncTextTertiary)
                        }
                        if label != "Next" {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private var windowTimelinePreview: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 12)
                
                // Active windows with enhanced styling
                ForEach(viewModel.mealWindows) { window in
                    if let position = windowPosition(for: window, in: geometry.size.width) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(windowColor(for: window))
                            .frame(width: position.width, height: 12)
                            .offset(x: position.offset)
                            .overlay(
                                // Add subtle border for better definition
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(windowBorderColor(for: window), lineWidth: 1)
                            )
                            .offset(x: position.offset)
                    }
                }
                
                // Enhanced current time indicator
                VStack(spacing: 2) {
                    // Time marker
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .overlay(
                            Circle()
                                .fill(Color.nutriSyncAccent)
                                .frame(width: 8, height: 8)
                        )
                }
                .offset(x: currentTimePosition(in: geometry.size.width) - 8)
            }
        }
        .frame(height: 16)
    }
    
    
    
    // MARK: - Helpers
    
    private var settingsButton: some View {
        Button(action: { showDeveloperDashboard = true }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(Color.nutriSyncElevated)
                .cornerRadius(12)
        }
    }
    
    private func loadData() {
        // Load initial data
    }
    
    private func animateRings() {
        // No longer needed - rings removed
    }
    
    private func refresh() async {
        refreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadData()
        animateRings()
        refreshing = false
    }
    
    // MARK: - Computed Properties
    
    private var timingPercentage: Double {
        // More forgiving thresholds for better user experience
        // Calculate based on meal timing accuracy for each window
        var totalScore: Double = 0
        var relevantWindows = 0
        
        for window in viewModel.mealWindows {
            var windowScore: Double = 0
            
            // Check if any meal was logged for this specific window
            if let meal = viewModel.todaysMeals.first(where: { $0.windowId == window.id }) {
                // Calculate how close the meal was to the window timing
                let mealTime = meal.timestamp
                
                if mealTime >= window.startTime && mealTime <= window.endTime {
                    // Perfect timing - within window
                    windowScore = 1.0
                } else if mealTime < window.startTime {
                    // Early logging - more forgiving
                    let minutesEarly = window.startTime.timeIntervalSince(mealTime) / 60
                    if minutesEarly <= 30 {
                        windowScore = 0.85 // 85% for up to 30 min early
                    } else if minutesEarly <= 60 {
                        windowScore = 0.7 // 70% for 30-60 min early
                    } else {
                        windowScore = 0.5 // 50% for over 60 min early
                    }
                } else {
                    // Late logging - same forgiving thresholds
                    let minutesLate = mealTime.timeIntervalSince(window.endTime) / 60
                    if minutesLate <= 30 {
                        windowScore = 0.85 // 85% for up to 30 min late
                    } else if minutesLate <= 60 {
                        windowScore = 0.7 // 70% for 30-60 min late
                    } else {
                        windowScore = 0.5 // 50% for over 60 min late
                    }
                }
                
                totalScore += windowScore
                relevantWindows += 1
            } else {
                // No meal for this window
                // Only count it if the window has passed
                if window.endTime < TimeProvider.shared.currentTime {
                    // Missed window completely - 0 points
                    totalScore += 0
                    relevantWindows += 1
                }
                // Don't count future or currently active windows without meals
            }
        }
        
        // If no relevant windows yet, show 0% (no timing to measure)
        guard relevantWindows > 0 else { return 0 }
        
        return (totalScore / Double(relevantWindows)) * 100
    }
    
    private var nutrientPercentage: Double {
        // Calculate comprehensive nutrition score
        var scores: [Double] = []
        
        // Check if there's an active window (don't penalize for in-progress meals)
        let now = TimeProvider.shared.currentTime
        let hasActiveWindow = viewModel.mealWindows.contains { window in
            now >= window.startTime && now <= window.endTime
        }
        
        // If there's an active window and day isn't complete, be more lenient
        let leniencyFactor = hasActiveWindow ? 1.2 : 1.0
        
        // 1. Calorie accuracy (20% weight)
        let adjustedCalorieProgress = dailyCalorieProgress * leniencyFactor
        let calorieScore = min(adjustedCalorieProgress, 1.2) // Allow up to 120%
        let calorieAccuracy = 1.0 - abs(1.0 - calorieScore) // Penalize over/under
        scores.append(calorieAccuracy * 0.2)
        
        // 2. Macro balance (30% weight)
        let proteinProgress = Double(totalProtein) / Double(max(dailyProteinTarget, 1)) * leniencyFactor
        let fatProgress = Double(totalFat) / Double(max(dailyFatTarget, 1)) * leniencyFactor
        let carbProgress = Double(totalCarbs) / Double(max(dailyCarbsTarget, 1)) * leniencyFactor
        
        let proteinScore = min(proteinProgress, 1.2)
        let fatScore = min(fatProgress, 1.2)
        let carbScore = min(carbProgress, 1.2)
        
        let macroAccuracy = (
            (1.0 - abs(1.0 - proteinScore)) +
            (1.0 - abs(1.0 - fatScore)) +
            (1.0 - abs(1.0 - carbScore))
        ) / 3.0
        scores.append(macroAccuracy * 0.3)
        
        // 3. Micronutrient coverage (50% weight)
        let targetNutrients = 18
        let nutrientsWithGoodIntake = min(nutrientsHit, targetNutrients)
        let microScore = Double(nutrientsWithGoodIntake) / Double(targetNutrients)
        scores.append(microScore * 0.5)
        
        return scores.reduce(0, +) * 100
    }
    
    private var adherencePercentage: Double {
        // Calculate plan adherence score - only count required windows
        var adherenceFactors: [Double] = []
        
        // Filter for required windows only (exclude optional snacks)
        let requiredWindows = viewModel.mealWindows.filter { window in
            // Consider a window required if it's a main meal (breakfast, lunch, dinner)
            // or if it contains significant calories (>200)
            let isMainMeal = window.name.lowercased().contains("breakfast") ||
                           window.name.lowercased().contains("lunch") ||
                           window.name.lowercased().contains("dinner")
            let hasSignificantCalories = window.targetCalories > 200
            return isMainMeal || hasSignificantCalories
        }
        
        // 1. Meal frequency (40% weight) - based on required windows only
        let mealsLogged = viewModel.todaysMeals.count
        let targetMeals = requiredWindows.count
        let mealFrequencyScore = targetMeals > 0 ? min(Double(mealsLogged) / Double(targetMeals), 1.0) : 1.0
        adherenceFactors.append(mealFrequencyScore * 0.4)
        
        // 2. Window utilization (30% weight) - for required windows
        let windowsUsed = requiredWindows.filter { window in
            viewModel.todaysMeals.contains { meal in
                let windowRange = window.startTime.addingTimeInterval(-3600)...window.endTime.addingTimeInterval(3600)
                return windowRange.contains(meal.timestamp)
            }
        }.count
        let windowUtilization = targetMeals > 0 ? Double(windowsUsed) / Double(targetMeals) : 1.0
        adherenceFactors.append(windowUtilization * 0.3)
        
        // 3. Consistency score (30% weight)
        // Check if meals are spread throughout the day as planned
        let consistencyScore = calculateConsistencyScore()
        adherenceFactors.append(consistencyScore * 0.3)
        
        return adherenceFactors.reduce(0, +) * 100
    }
    
    private func calculateConsistencyScore() -> Double {
        guard !viewModel.todaysMeals.isEmpty else { return 0 }
        
        // Check meal spacing - ideal is 3-5 hours between meals
        let sortedMeals = viewModel.todaysMeals.sorted { $0.timestamp < $1.timestamp }
        var spacingScores: [Double] = []
        
        for i in 1..<sortedMeals.count {
            let gap = sortedMeals[i].timestamp.timeIntervalSince(sortedMeals[i-1].timestamp) / 3600
            
            if gap >= 3 && gap <= 5 {
                spacingScores.append(1.0) // Perfect spacing
            } else if gap >= 2 && gap <= 6 {
                spacingScores.append(0.8) // Good spacing
            } else if gap < 2 {
                spacingScores.append(0.4) // Too close
            } else {
                spacingScores.append(0.5) // Too far
            }
        }
        
        return spacingScores.isEmpty ? 1.0 : spacingScores.reduce(0, +) / Double(spacingScores.count)
    }
    
    private var totalPercentage: Int {
        Int((timingPercentage + nutrientPercentage + adherencePercentage) / 3)
    }
    
    private var nutrientsHit: Int {
        // Calculate micronutrients that meet at least 25% of RDA
        var nutrientsWithGoodIntake = 0
        var nutrientTotals: [String: Double] = [:]
        
        // Aggregate all micronutrients from today's meals
        for meal in viewModel.todaysMeals {
            for (nutrientName, amount) in meal.micronutrients {
                nutrientTotals[nutrientName, default: 0] += amount
            }
        }
        
        // Check against RDA values
        for (nutrientName, totalAmount) in nutrientTotals {
            if let micronutrient = MicronutrientData.getAllNutrients().first(where: { $0.name == nutrientName }) {
                let percentageOfRDA = (totalAmount / micronutrient.rda) * 100
                if percentageOfRDA >= 25 { // Count if at least 25% of RDA is met
                    nutrientsWithGoodIntake += 1
                }
            }
        }
        
        return nutrientsWithGoodIntake
    }
    
    private var nutrientsStatus: String {
        if nutrientsHit >= 16 { return "Excellent" }
        else if nutrientsHit >= 14 { return "Good" }
        else if nutrientsHit >= 10 { return "Fair" }
        else { return "Needs work" }
    }
    
    private var currentWindowStatus: (mainText: String, subText: String, progress: Double) {
        guard let activeWindow = viewModel.mealWindows.first(where: { window in
            let now = TimeProvider.shared.currentTime
            return now >= window.startTime && now <= window.endTime
        }) else {
            if let nextWindow = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
                let timeUntil = nextWindow.startTime.timeIntervalSince(TimeProvider.shared.currentTime)
                let hours = Int(timeUntil / 3600)
                let minutes = Int((timeUntil.truncatingRemainder(dividingBy: 3600)) / 60)
                
                if hours > 0 {
                    return ("Break", "\(hours)h \(minutes)m until next", 0)
                } else {
                    return ("Break", "\(minutes)m until next", 0)
                }
            }
            return ("No windows", "Day complete", 1.0)
        }
        
        let elapsed = TimeProvider.shared.currentTime.timeIntervalSince(activeWindow.startTime)
        let total = activeWindow.endTime.timeIntervalSince(activeWindow.startTime)
        let progress = elapsed / total
        
        let remaining = activeWindow.endTime.timeIntervalSince(TimeProvider.shared.currentTime)
        let minutes = Int(remaining / 60)
        
        let calories = viewModel.caloriesConsumedInWindow(activeWindow)
        let caloriesRemaining = max(0, activeWindow.targetCalories - calories)
        
        return (getMealType(for: activeWindow), "\(minutes)m left • \(caloriesRemaining) cal", progress)
    }
    
    private var nextWindowName: String {
        if let window = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
            return getMealType(for: window)
        }
        return "Day Complete"
    }
    
    private var nextWindowTime: String {
        if let window = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: window.startTime)
        }
        return "—"
    }
    
    private var timeUntilNextWindow: String? {
        if let window = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
            let timeInterval = window.startTime.timeIntervalSince(TimeProvider.shared.currentTime)
            let hours = Int(timeInterval) / 3600
            let minutes = (Int(timeInterval) % 3600) / 60
            
            if hours > 0 {
                return "in \(hours)h \(minutes)m"
            } else {
                return "in \(minutes)m"
            }
        }
        return nil
    }
    
    private var nextWindowDuration: String? {
        if let window = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
            let duration = window.endTime.timeIntervalSince(window.startTime)
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            
            if hours > 0 && minutes > 0 {
                return "\(hours)h \(minutes)m window"
            } else if hours > 0 {
                return "\(hours)h window"
            } else {
                return "\(minutes)m window"
            }
        }
        return nil
    }
    
    private func windowPosition(for window: MealWindow, in width: CGFloat) -> (offset: CGFloat, width: CGFloat)? {
        let dayStart = Calendar.current.startOfDay(for: TimeProvider.shared.currentTime)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        
        let startPercent = window.startTime.timeIntervalSince(dayStart) / dayEnd.timeIntervalSince(dayStart)
        let endPercent = window.endTime.timeIntervalSince(dayStart) / dayEnd.timeIntervalSince(dayStart)
        
        let offset = width * startPercent
        let windowWidth = width * (endPercent - startPercent)
        
        return (offset: CGFloat(offset), width: CGFloat(windowWidth))
    }
    
    private func windowColor(for window: MealWindow) -> Color {
        // Check if this is the next upcoming window
        let isNextWindow = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime })?.id == window.id
        
        if viewModel.todaysMeals.contains(where: { meal in
            meal.windowId == window.id
        }) {
            return .nutriSyncAccent // Completed - green
        } else if window.endTime < TimeProvider.shared.currentTime {
            return Color(hex: "E94B3C").opacity(0.8) // Missed - soft red
        } else if isNextWindow {
            return Color(hex: "F4A460") // Next - soft orange highlight
        } else {
            return Color.white.opacity(0.15) // Upcoming - subtle
        }
    }
    
    private func windowBorderColor(for window: MealWindow) -> Color {
        let isNextWindow = viewModel.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime })?.id == window.id
        
        if isNextWindow {
            return Color(hex: "F4A460").opacity(0.5)
        }
        return Color.clear
    }
    
    private func legendColor(for label: String) -> Color {
        switch label {
        case "Completed":
            return .nutriSyncAccent
        case "Missed":
            return Color(hex: "E94B3C").opacity(0.8)
        case "Next":
            return Color(hex: "F4A460")
        case "Upcoming":
            return Color.white.opacity(0.15)
        default:
            return Color.white.opacity(0.15)
        }
    }
    
    private func currentTimePosition(in width: CGFloat) -> CGFloat {
        let dayStart = Calendar.current.startOfDay(for: TimeProvider.shared.currentTime)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        
        let currentPercent = TimeProvider.shared.currentTime.timeIntervalSince(dayStart) / dayEnd.timeIntervalSince(dayStart)
        return width * currentPercent
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: TimeProvider.shared.currentTime)
    }
    
    private var windowsHit: Int {
        viewModel.mealWindows.filter { window in
            viewModel.todaysMeals.contains { meal in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }
        }.count
    }
    
    private var totalWindows: Int {
        viewModel.mealWindows.count
    }
    
    private var totalCalories: Int {
        viewModel.todaysMeals.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Int {
        viewModel.todaysMeals.reduce(0) { $0 + $1.protein }
    }
    
    private var totalFat: Int {
        viewModel.todaysMeals.reduce(0) { $0 + $1.fat }
    }
    
    private var totalCarbs: Int {
        viewModel.todaysMeals.reduce(0) { $0 + $1.carbs }
    }
    
    // Daily targets based on user goals
    private var dailyCalorieTarget: Int {
        viewModel.dailyCalorieTarget
    }
    
    private var dailyProteinTarget: Int {
        viewModel.dailyProteinTarget
    }
    
    private var dailyFatTarget: Int {
        viewModel.dailyFatTarget
    }
    
    private var dailyCarbsTarget: Int {
        viewModel.dailyCarbTarget
    }
    
    private var dailyCalorieProgress: Double {
        guard dailyCalorieTarget > 0 else { return 0 }
        return Double(totalCalories) / Double(dailyCalorieTarget)
    }
    
    private var todayScore: Int {
        Int((timingPercentage + nutrientPercentage + adherencePercentage) / 3)
    }
    
    // Overall Performance Score Card
    private var overallScoreCard: some View {
        PerformanceCard {
            VStack(spacing: 12) {
                Text("Overall Performance")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("\(todayScore)%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(scoreColor)
                
                Text(scoreMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    private var scoreColor: Color {
        switch todayScore {
        case 0..<40: return .red.opacity(0.8)
        case 40..<60: return .orange.opacity(0.8)
        case 60..<80: return .yellow.opacity(0.8)
        default: return PerformanceDesignSystem.successMuted
        }
    }
    
    private var scoreMessage: String {
        switch todayScore {
        case 0..<40: return "Room to grow - let's build momentum together"
        case 40..<60: return "Building momentum - keep pushing forward"
        case 60..<80: return "Strong progress - you're doing great"
        default: return "Excellent performance - crushing your goals!"
        }
    }
    
    private var nutrientBreakdownSection: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 20) {
                Text("Today's Micronutrients")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                // Redesigned NutriSync Petals - smaller and shadcn themed
                HexagonFlowerView(
                    micronutrients: viewModel.topNutrients.map { ($0.name, $0.percentage) },
                    size: 180,  // Reduced from 240px
                    showLabels: false,
                    showPurposeText: true  // Show nutrient names in petals
                )
                .frame(maxWidth: .infinity)
            }
            
            // Nutrient detail grid - 2 columns with flexible sizing
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 140)),
                GridItem(.flexible(minimum: 140))
            ], spacing: 12) {
                ForEach(viewModel.topNutrients, id: \.name) { nutrient in
                    NutrientDetailCard(nutrient: nutrient)
                        .frame(minHeight: 80)
                }
            }
        }
    }
}

// MARK: - Nested Types

extension NutritionDashboardView {
    struct NutrientDetailCard: View {
        let nutrient: NutritionDashboardViewModel.NutrientInfo
        @State private var isExpanded = false
        
        // Nutrient benefits data with SF Symbol icons
        private var nutrientBenefits: (icon: String, benefits: [String]) {
            switch nutrient.name {
            case "Iron":
                return ("drop.fill", [
                    "Oxygen transport to muscles",
                    "Energy production",
                    "Immune system support"
                ])
            case "Vitamin D", "Vit D":
                return ("sun.max.fill", [
                    "Bone health & calcium absorption",
                    "Muscle function",
                    "Mood regulation"
                ])
            case "Calcium":
                return ("circle.hexagongrid.fill", [
                    "Strong bones and teeth",
                    "Muscle contractions",
                    "Nerve signaling"
                ])
            case "B12":
                return ("bolt.fill", [
                    "Energy metabolism",
                    "Red blood cell formation",
                    "Neurological function"
                ])
            case "Folate":
                return ("leaf.fill", [
                    "DNA synthesis",
                    "Cell division",
                    "Mental clarity"
                ])
            case "Zinc":
                return ("shield.fill", [
                    "Immune defense",
                    "Wound healing",
                    "Protein synthesis"
                ])
            default:
                return ("pills.fill", ["Essential nutrient"])
            }
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Main card content
                VStack(alignment: .leading, spacing: 10) {
                    // Top row with icon and name
                    HStack {
                        Image(systemName: nutrientBenefits.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(nutrient.color)
                            .frame(width: 24)
                        
                        Text(nutrient.name == "Vit D" ? "Vitamin D" : nutrient.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Percentage and progress bar
                    HStack {
                        Text("\(Int(nutrient.percentage * 100))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(nutrient.color)
                            .frame(width: 40, alignment: .leading)
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(nutrient.color.opacity(0.8))
                                    .frame(width: geometry.size.width * nutrient.percentage)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                // Expandable benefits section
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Benefits")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        ForEach(nutrientBenefits.benefits, id: \.self) { benefit in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(benefit)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
                }
            }
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
        }
    }
}

// MARK: - Helper Methods

extension NutritionDashboardView {
    private func getMealType(for window: MealWindow) -> String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        
        switch hour {
        case 5...10:
            return "Breakfast"
        case 11...14:
            return "Lunch"
        case 15...17:
            return "Snack"
        case 18...21:
            return "Dinner"
        default:
            return "Late Snack"
        }
    }
}

// MARK: - Supporting Types

struct NutritionInsight {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let actionText: String?
}



// MARK: - Info Floating Card

struct InfoFloatingCard: View {
    let data: NutritionDashboardView.InfoPopupData
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Circle()
                        .fill(data.color.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(data.color)
                        )
                    
                    Text(data.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.nutriSyncTextTertiary)
                    }
                }
                
                Text(data.description)
                    .font(.system(size: 13))
                    .foregroundColor(.nutriSyncTextSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
            .frame(width: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 10)
            )
            .position(
                x: min(max(160, data.position.x), geometry.size.width - 160),
                y: min(max(150, data.position.y + 50), geometry.size.height - 200)
            )
            .offset(dragOffset)
            .scaleEffect(isDragging ? 0.95 : (animateIn ? 1 : 0.8))
            .opacity(animateIn ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateIn)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // Snap to dismiss if dragged far enough
                        if abs(value.translation.width) > 100 || abs(value.translation.height) > 100 {
                            withAnimation(.spring(response: 0.3)) {
                                dragOffset = CGSize(
                                    width: value.translation.width * 3,
                                    height: value.translation.height * 3
                                )
                                animateIn = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onDismiss()
                            }
                        } else {
                            // Snap back
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    animateIn = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Shimmering Extension

extension View {
    func shimmering() -> some View {
        self
            .redacted(reason: .placeholder)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: true
                    )
            )
    }
}

#Preview {
    NutritionDashboardView(showDeveloperDashboard: .constant(false))
        .preferredColorScheme(.dark)
}

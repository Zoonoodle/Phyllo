//
//  SimplePerformanceView.swift
//  NutriSync
//
//  Simple NOW-only Performance view without tabs
//

import SwiftUI

struct SimplePerformanceView: View {
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
        let category: String
        let icon: String
        let tips: [String]
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
                
                VStack(spacing: 0) {
                    // Simple header without tabs
                    headerSection
                    
                    // Main NOW content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            nowView
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refresh()
                    }
                }
                
                // Info popup overlay
                if let popupData = infoPopupData {
                    SimpleInfoFloatingCard(
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        // Centered title with settings button
        ZStack {
            // Settings button on the right
            HStack {
                Spacer()
                
                Button(action: { showDeveloperDashboard = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Centered title
            Text("Performance")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - NOW View
    
    private var nowView: some View {
        VStack(spacing: 24) {
            // Activity Rings
            activityRingsSection
            
            // Live Metrics Grid
            liveMetricsGrid
            
            // Current Window Status
            currentWindowCard
            
            // Quick Actions
            quickActionsRow
        }
    }
    
    private var activityRingsSection: some View {
        VStack(spacing: 20) {
            // Three concentric activity rings - replaced with simple placeholder circles
            ZStack {
                // Timing Ring placeholder (Outer)
                Circle()
                    .stroke(Color(hex: "FF3B30").opacity(0.2), lineWidth: 24)
                    .frame(width: 260, height: 260)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: ringAnimations.timingProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 24, lineCap: .round)
                            )
                            .frame(width: 260, height: 260)
                            .rotationEffect(.degrees(-90))
                    )
                    .animation(Animation.spring(response: 1.0, dampingFraction: 0.8), value: ringAnimations.timingProgress)
                
                // Nutrients Ring placeholder (Middle)
                Circle()
                    .stroke(Color(hex: "34C759").opacity(0.2), lineWidth: 24)
                    .frame(width: 210, height: 210)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: ringAnimations.nutrientProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "34C759"), Color(hex: "5EDD79")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 24, lineCap: .round)
                            )
                            .frame(width: 210, height: 210)
                            .rotationEffect(.degrees(-90))
                    )
                    .animation(Animation.spring(response: 1.0, dampingFraction: 0.8).delay(0.1), value: ringAnimations.nutrientProgress)
                
                // Adherence Ring placeholder (Inner)
                Circle()
                    .stroke(Color(hex: "007AFF").opacity(0.2), lineWidth: 24)
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .trim(from: 0, to: ringAnimations.adherenceProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "007AFF"), Color(hex: "4FA0FF")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 24, lineCap: .round)
                            )
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                    )
                    .animation(Animation.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: ringAnimations.adherenceProgress)
                
                // Center metrics with subtle glass background
                ZStack {
                    // Glass circle
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 138, height: 138)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    VStack(spacing: 6) {
                        Text("\(totalPercentage)%")
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        Text("Overall")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(Color.white.opacity(0.06))
                            )
                    }
                }
            }
            .frame(height: 300)
            
            // Ring labels with info buttons
            HStack(spacing: 20) {
                ringLabelWithInfo(
                    color: Color(hex: "FF3B30"), 
                    label: "TIMING", 
                    value: Int(timingPercentage), 
                    icon: "clock.fill",
                    infoTitle: "Timing Score",
                    infoDescription: "Measures how well you eat within your scheduled windows:\n\n• 100% = Meal within window\n• -10% per 30min early\n• -15% per 30min late\n\nEating on time optimizes digestion, energy, and circadian rhythm.",
                    infoCategory: "Performance",
                    infoIcon: "clock.fill",
                    infoTips: ["Log meals as soon as you eat", "Set reminders for meal times", "Plan meals around your schedule"]
                )
                
                ringLabelWithInfo(
                    color: Color(hex: "34C759"), 
                    label: "NUTRIENTS", 
                    value: Int(nutrientPercentage), 
                    icon: "leaf.fill",
                    infoTitle: "Nutrient Score",
                    infoDescription: "Complete nutrition assessment:\n\n• 20% - Calorie accuracy\n• 30% - Macro balance (protein, fat, carbs)\n• 50% - Micronutrient coverage (vitamins & minerals)\n\nBalanced nutrition supports all body functions.",
                    infoCategory: "Nutrition",
                    infoIcon: "leaf.fill",
                    infoTips: ["Eat a variety of colorful foods", "Focus on whole, unprocessed foods", "Track your micronutrients"]
                )
                
                ringLabelWithInfo(
                    color: Color(hex: "007AFF"), 
                    label: "ADHERENCE", 
                    value: Int(adherencePercentage), 
                    icon: "checkmark.circle.fill",
                    infoTitle: "Adherence Score",
                    infoDescription: "How well you follow your plan:\n\n• 40% - Meal frequency\n• 30% - Window utilization\n• 30% - Consistent spacing (3-5hrs)\n\nConsistency builds sustainable habits.",
                    infoCategory: "Consistency",
                    infoIcon: "checkmark.circle.fill",
                    infoTips: ["Start with small, achievable goals", "Prepare meals in advance", "Track your progress daily"]
                )
            }
        }
        .padding(.vertical, 20)
    }
    
    private func ringLabelWithInfo(
        color: Color, 
        label: String, 
        value: Int, 
        icon: String,
        infoTitle: String,
        infoDescription: String,
        infoCategory: String,
        infoIcon: String,
        infoTips: [String]
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.nutriSyncTextSecondary)
                    
                    GeometryReader { geo in
                        Button(action: { 
                            let frame = geo.frame(in: .global)
                            infoPopupData = InfoPopupData(
                                title: infoTitle,
                                description: infoDescription,
                                color: color,
                                position: CGPoint(x: frame.midX, y: frame.midY),
                                category: infoCategory,
                                icon: infoIcon,
                                tips: infoTips
                            )
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.nutriSyncTextTertiary)
                        }
                    }
                    .frame(width: 12, height: 12)
                }
                
                Text("\(value)%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var liveMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            // Current Window Metric
            MetricCard(
                title: "CURRENT WINDOW",
                mainValue: currentWindowStatus.mainText,
                subValue: currentWindowStatus.subText,
                progress: currentWindowStatus.progress,
                color: .blue,
                icon: "clock.fill"
            )
            
            // Nutrients Today
            MetricCard(
                title: "NUTRIENTS TODAY",
                mainValue: "\(nutrientsHit)/18",
                subValue: nutrientsStatus,
                progress: Double(nutrientsHit) / 18.0,
                color: .green,
                icon: "leaf.fill"
            )
            
            // Fasting Timer
            MetricCard(
                title: "FASTING TIME",
                mainValue: fastingTime,
                subValue: fastingStatus,
                progress: fastingProgress,
                color: .purple,
                icon: "timer"
            )
            
            // Streak Counter
            MetricCard(
                title: "STREAK",
                mainValue: "\(viewModel.currentStreak) days",
                subValue: "Personal best: 14",
                progress: Double(viewModel.currentStreak) / 14.0,
                color: .orange,
                icon: "flame.fill"
            )
        }
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
    
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                label: "Log Meal",
                color: .nutriSyncAccent
            ) {
                NotificationCenter.default.post(name: .switchToScanTab, object: nil)
            }
            
            QuickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                label: "View Trends",
                color: .blue
            ) {
                // Could navigate to insights or trends
            }
            
            QuickActionButton(
                icon: "lightbulb.fill",
                label: "Get Tips",
                color: .orange
            ) {
                // Could show insights
            }
        }
    }
    
    struct QuickActionButton: View {
        let icon: String
        let label: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadData() {
        // Load initial data
    }
    
    private func animateRings() {
        withAnimation(.easeOut(duration: 1.5)) {
            ringAnimations.timingProgress = timingPercentage / 100
            ringAnimations.nutrientProgress = nutrientPercentage / 100
            ringAnimations.adherenceProgress = adherencePercentage / 100
            ringAnimations.animating = true
        }
    }
    
    private func refresh() async {
        refreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadData()
        animateRings()
        refreshing = false
    }
    
    // MARK: - Computed Properties (Same calculations as original)
    
    private var timingPercentage: Double {
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
                    // Early logging - give partial credit based on how early
                    let minutesEarly = window.startTime.timeIntervalSince(mealTime) / 60
                    if minutesEarly <= 15 {
                        windowScore = 0.9 // 90% for up to 15 min early
                    } else if minutesEarly <= 30 {
                        windowScore = 0.7 // 70% for 15-30 min early
                    } else if minutesEarly <= 60 {
                        windowScore = 0.5 // 50% for 30-60 min early
                    } else {
                        windowScore = 0.3 // 30% for over 60 min early
                    }
                } else {
                    // Late logging - penalize more than early
                    let minutesLate = mealTime.timeIntervalSince(window.endTime) / 60
                    if minutesLate <= 15 {
                        windowScore = 0.8 // 80% for up to 15 min late
                    } else if minutesLate <= 30 {
                        windowScore = 0.5 // 50% for 15-30 min late
                    } else if minutesLate <= 60 {
                        windowScore = 0.3 // 30% for 30-60 min late
                    } else {
                        windowScore = 0.1 // 10% for over 60 min late
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
        
        // If no relevant windows yet, show 100% (benefit of doubt)
        guard relevantWindows > 0 else { return 100 }
        
        return (totalScore / Double(relevantWindows)) * 100
    }
    
    private var nutrientPercentage: Double {
        // Calculate comprehensive nutrition score
        var scores: [Double] = []
        
        // 1. Calorie accuracy (20% weight)
        let calorieScore = min(dailyCalorieProgress, 1.2) // Allow up to 120%
        let calorieAccuracy = 1.0 - abs(1.0 - calorieScore) // Penalize over/under
        scores.append(calorieAccuracy * 0.2)
        
        // 2. Macro balance (30% weight)
        let proteinProgress = Double(totalProtein) / Double(max(dailyProteinTarget, 1))
        let fatProgress = Double(totalFat) / Double(max(dailyFatTarget, 1))
        let carbProgress = Double(totalCarbs) / Double(max(dailyCarbsTarget, 1))
        
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
        // Calculate plan adherence score
        var adherenceFactors: [Double] = []
        
        // 1. Meal frequency (40% weight)
        let mealsLogged = viewModel.todaysMeals.count
        let targetMeals = viewModel.mealWindows.count
        let mealFrequencyScore = targetMeals > 0 ? min(Double(mealsLogged) / Double(targetMeals), 1.0) : 0
        adherenceFactors.append(mealFrequencyScore * 0.4)
        
        // 2. Window utilization (30% weight)
        let windowsUsed = viewModel.mealWindows.filter { window in
            viewModel.todaysMeals.contains { meal in
                let windowRange = window.startTime.addingTimeInterval(-3600)...window.endTime.addingTimeInterval(3600)
                return windowRange.contains(meal.timestamp)
            }
        }.count
        let windowUtilization = targetMeals > 0 ? Double(windowsUsed) / Double(targetMeals) : 0
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
                    return ("Fasting", "\(hours)h \(minutes)m until next", 0)
                } else {
                    return ("Fasting", "\(minutes)m until next", 0)
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
    
    private var fastingTime: String {
        // Calculate time since last meal
        if let lastMeal = viewModel.todaysMeals.last {
            let elapsed = TimeProvider.shared.currentTime.timeIntervalSince(lastMeal.timestamp)
            let hours = Int(elapsed / 3600)
            let minutes = Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
            
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
        return "No meals"
    }
    
    private var fastingStatus: String {
        if let lastMeal = viewModel.todaysMeals.last {
            let elapsed = TimeProvider.shared.currentTime.timeIntervalSince(lastMeal.timestamp)
            let hours = elapsed / 3600
            
            if hours >= 16 { return "Extended fast" }
            else if hours >= 12 { return "Optimal range" }
            else if hours >= 3 { return "Digesting" }
            else { return "Just ate" }
        }
        return "Start tracking"
    }
    
    private var fastingProgress: Double {
        if let lastMeal = viewModel.todaysMeals.last {
            let elapsed = TimeProvider.shared.currentTime.timeIntervalSince(lastMeal.timestamp)
            let targetFast = 16.0 * 3600 // 16 hour fast target
            return min(elapsed / targetFast, 1.0)
        }
        return 0
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
    
    // MARK: - Helper Methods
    
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

// MARK: - Simple Info Floating Card
struct SimpleInfoFloatingCard: View {
    let data: SimplePerformanceView.InfoPopupData
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Background overlay
            backgroundOverlay
            
            // Main card content
            GeometryReader { geometry in
                cardContent
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    .offset(dragOffset)
                    .scaleEffect(animateIn ? 1 : 0.8)
                    .opacity(animateIn ? 1 : 0)
                    .gesture(dragGesture)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
    
    private var backgroundOverlay: some View {
        Color.black.opacity(animateIn ? 0.4 : 0)
            .ignoresSafeArea()
            .onTapGesture(perform: onDismiss)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            titleSection
            descriptionSection
            if !data.tips.isEmpty {
                tipsSection
            }
        }
        .padding(20)
        .background(cardBackground)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }
    
    private var headerSection: some View {
        HStack {
            Label(data.category, systemImage: data.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
    
    private var titleSection: some View {
        Text(data.title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
    }
    
    private var descriptionSection: some View {
        Text(data.description)
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tips")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
            
            ForEach(data.tips, id: \.self) { tip in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(Color.nutriSyncAccent)
                        .frame(width: 4, height: 4)
                        .offset(y: 6)
                    Text(tip)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                if abs(value.translation.height) > threshold ||
                   abs(value.translation.width) > threshold {
                    onDismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
                isDragging = false
            }
    }
}

#Preview {
    SimplePerformanceView(showDeveloperDashboard: .constant(false))
        .preferredColorScheme(.dark)
}
//
//  NutritionDashboardView.swift
//  Phyllo
//
//  Nutrition Performance Dashboard - Fitness Tracker Style
//

import SwiftUI

struct NutritionDashboardView: View {
    @Binding var showDeveloperDashboard: Bool
    @ObservedObject private var mockData = MockDataManager.shared
    @StateObject private var insightsEngine = InsightsEngine.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var timeProvider = TimeProvider.shared
    
    @State private var selectedView: DashboardView = .now
    @State private var ringAnimations = RingAnimationState()
    @State private var refreshing = false
    
    enum DashboardView {
        case now, today, week, insights
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
                Color.phylloBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with tabs
                    headerSection
                    
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            switch selectedView {
                            case .now:
                                nowView
                            case .today:
                                todayView
                            case .week:
                                weekView
                            case .insights:
                                insightsView
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refresh()
                    }
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
        VStack(spacing: 12) {
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
            
            
            // View selector tabs
            viewSelector
                .padding(.horizontal, 24)
        }
    }
    
    private var viewSelector: some View {
        HStack(spacing: 0) {
            ForEach([DashboardView.now, .today, .week, .insights], id: \.self) { view in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedView = view
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(viewTitle(for: view))
                            .font(.system(size: 13, weight: selectedView == view ? .semibold : .regular))
                            .foregroundColor(selectedView == view ? .white : .phylloTextSecondary)
                        
                        Rectangle()
                            .fill(selectedView == view ? Color.phylloAccent : Color.clear)
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.2), value: selectedView)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func viewTitle(for view: DashboardView) -> String {
        switch view {
        case .now: return "NOW"
        case .today: return "TODAY"
        case .week: return "WEEK"
        case .insights: return "INSIGHTS"
        }
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
            // Three concentric activity rings
            ZStack {
                // Timing Ring (Outer)
                AppleStyleRing(
                    progress: ringAnimations.timingProgress,
                    diameter: 260,
                    lineWidth: 24,
                    backgroundColor: Color(hex: "FF3B30").opacity(0.2),
                    foregroundColors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
                    icon: "clock.fill",
                    iconAngle: 0
                )
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: ringAnimations.timingProgress)
                
                // Nutrients Ring (Middle)
                AppleStyleRing(
                    progress: ringAnimations.nutrientProgress,
                    diameter: 210,
                    lineWidth: 24,
                    backgroundColor: Color(hex: "34C759").opacity(0.2),
                    foregroundColors: [Color(hex: "34C759"), Color(hex: "5EDD79")],
                    icon: "leaf.fill",
                    iconAngle: 0
                )
                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1), value: ringAnimations.nutrientProgress)
                
                // Adherence Ring (Inner)
                AppleStyleRing(
                    progress: ringAnimations.adherenceProgress,
                    diameter: 160,
                    lineWidth: 24,
                    backgroundColor: Color(hex: "007AFF").opacity(0.2),
                    foregroundColors: [Color(hex: "007AFF"), Color(hex: "4FA0FF")],
                    icon: "checkmark.circle.fill",
                    iconAngle: 0
                )
                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2), value: ringAnimations.adherenceProgress)
                
                // Center metrics
                VStack(spacing: 4) {
                    Text("\(totalPercentage)%")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Overall")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                }
            }
            .frame(height: 300)
            
            // Ring labels
            HStack(spacing: 20) {
                ringLabel(color: Color(hex: "FF3B30"), label: "TIMING", value: Int(timingPercentage), icon: "clock.fill")
                ringLabel(color: Color(hex: "34C759"), label: "NUTRIENTS", value: Int(nutrientPercentage), icon: "leaf.fill")
                ringLabel(color: Color(hex: "007AFF"), label: "ADHERENCE", value: Int(adherencePercentage), icon: "checkmark.circle.fill")
            }
        }
        .padding(.vertical, 20)
    }
    
    private func ringLabel(color: Color, label: String, value: Int, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.phylloTextSecondary)
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
                mainValue: "\(mockData.currentStreak) days",
                subValue: "Personal best: 14",
                progress: Double(mockData.currentStreak) / 14.0,
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
                        .foregroundColor(.phylloTextSecondary)
                    Spacer()
                }
                
                Text(mainValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(subValue)
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextTertiary)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.phylloBorder)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.8))
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 4)
            }
            .padding(16)
            .background(Color.phylloElevated)
            .cornerRadius(12)
        }
    }
    
    private var currentWindowCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Meal Window")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.phylloTextSecondary)
                    
                    Text(nextWindowName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(nextWindowTime)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.phylloAccent)
            }
            
            // Window timeline preview
            windowTimelinePreview
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    private var windowTimelinePreview: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background line
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.phylloBorder)
                    .frame(height: 8)
                
                // Active windows
                ForEach(mockData.mealWindows) { window in
                    if let position = windowPosition(for: window, in: geometry.size.width) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(windowColor(for: window))
                            .frame(width: position.width, height: 8)
                            .offset(x: position.offset)
                    }
                }
                
                // Current time indicator
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: currentTimePosition(in: geometry.size.width) - 6)
            }
        }
        .frame(height: 12)
    }
    
    private var quickActionsRow: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "plus.circle.fill",
                label: "Log Meal",
                color: .phylloAccent
            ) {
                NotificationCenter.default.post(name: .switchToScanTab, object: nil)
            }
            
            QuickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                label: "View Trends",
                color: .blue
            ) {
                withAnimation {
                    selectedView = .week
                }
            }
            
            QuickActionButton(
                icon: "lightbulb.fill",
                label: "Get Tips",
                color: .orange
            ) {
                withAnimation {
                    selectedView = .insights
                }
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
    
    // MARK: - TODAY View
    
    private var todayView: some View {
        VStack(spacing: 20) {
            // Daily summary card
            dailySummaryCard
            
            // Meal timeline
            mealTimelineSection
            
            // Nutrient breakdown
            nutrientBreakdownSection
        }
    }
    
    private var dailySummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Summary")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
            }
            
            // Summary metrics
            HStack(spacing: 20) {
                SummaryMetric(label: "Meals", value: "\(mockData.todayMeals.count)", icon: "fork.knife")
                SummaryMetric(label: "Windows Hit", value: "\(windowsHit)/\(totalWindows)", icon: "clock.fill")
                SummaryMetric(label: "Calories", value: "\(totalCalories)", icon: "flame.fill")
                SummaryMetric(label: "Score", value: "\(todayScore)", icon: "star.fill")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    struct SummaryMetric: View {
        let label: String
        let value: String
        let icon: String
        
        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.phylloAccent)
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.phylloTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - WEEK View
    
    private var weekView: some View {
        VStack(spacing: 20) {
            // Week overview
            weekOverviewCard
            
            // Trend charts
            trendChartsSection
            
            // Weekly achievements
            weeklyAchievementsSection
        }
    }
    
    private var weekOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Ring progress comparison
            VStack(spacing: 12) {
                WeekProgressBar(label: "Timing", values: weekTimingValues, color: .blue)
                WeekProgressBar(label: "Nutrients", values: weekNutrientValues, color: .green)
                WeekProgressBar(label: "Adherence", values: weekAdherenceValues, color: .orange)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    struct WeekProgressBar: View {
        let label: String
        let values: [Double]
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(values.reduce(0, +) / Double(values.count)))% avg")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextSecondary)
                }
                
                HStack(spacing: 4) {
                    ForEach(0..<7) { day in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(0.2))
                                .frame(height: 40)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color)
                                        .frame(height: 40 * (values.indices.contains(day) ? values[day] : 0))
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                )
                            
                            Text(dayLabel(for: day))
                                .font(.system(size: 9))
                                .foregroundColor(.phylloTextTertiary)
                        }
                    }
                }
            }
        }
        
        func dayLabel(for day: Int) -> String {
            ["M", "T", "W", "T", "F", "S", "S"][day]
        }
    }
    
    // MARK: - INSIGHTS View
    
    private var insightsView: some View {
        VStack(spacing: 20) {
            ForEach(insights, id: \.title) { insight in
                InsightCard(insight: insight)
            }
        }
    }
    
    struct InsightCard: View {
        let insight: NutritionInsight
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: insight.icon)
                        .font(.system(size: 20))
                        .foregroundColor(insight.color)
                    
                    Text(insight.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                Text(insight.description)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                    .lineSpacing(4)
                
                if let action = insight.actionText {
                    Button(action: {}) {
                        Text(action)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(insight.color)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(20)
            .background(Color.phylloElevated)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helpers
    
    private var settingsButton: some View {
        Button(action: { showDeveloperDashboard = true }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .background(Color.phylloElevated)
                .cornerRadius(12)
        }
    }
    
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
    
    // MARK: - Computed Properties
    
    private var timingPercentage: Double {
        // Calculate based on windows hit on time
        let windowsHit = mockData.mealWindows.filter { window in
            mockData.todayMeals.contains { meal in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }
        }.count
        
        let totalWindows = mockData.mealWindows.filter { $0.endTime > TimeProvider.shared.currentTime }.count
        guard totalWindows > 0 else { return 0 }
        
        return Double(windowsHit) / Double(totalWindows) * 100
    }
    
    private var nutrientPercentage: Double {
        // Calculate based on micronutrients hit
        let targetNutrients = 18
        let nutrientsHit = min(nutrientsHit, targetNutrients)
        return Double(nutrientsHit) / Double(targetNutrients) * 100
    }
    
    private var adherencePercentage: Double {
        // Calculate based on following meal plan
        let mealsLogged = mockData.todayMeals.count
        let targetMeals = mockData.mealWindows.count
        guard targetMeals > 0 else { return 0 }
        
        let adherence = min(Double(mealsLogged) / Double(targetMeals), 1.0) * 100
        return adherence
    }
    
    private var totalPercentage: Int {
        Int((timingPercentage + nutrientPercentage + adherencePercentage) / 3)
    }
    
    private var nutrientsHit: Int {
        // Calculate micronutrients that meet at least 25% of RDA
        var nutrientsWithGoodIntake = 0
        var nutrientTotals: [String: Double] = [:]
        
        // Aggregate all micronutrients from today's meals
        for meal in mockData.todayMeals {
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
        guard let activeWindow = mockData.mealWindows.first(where: { window in
            let now = TimeProvider.shared.currentTime
            return now >= window.startTime && now <= window.endTime
        }) else {
            if let nextWindow = mockData.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
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
        
        let calories = mockData.caloriesConsumedInWindow(activeWindow)
        let caloriesRemaining = max(0, activeWindow.effectiveCalories - calories)
        
        return (getMealType(for: activeWindow), "\(minutes)m left • \(caloriesRemaining) cal", progress)
    }
    
    private var fastingTime: String {
        // Calculate time since last meal
        if let lastMeal = mockData.todayMeals.last {
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
        if let lastMeal = mockData.todayMeals.last {
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
        if let lastMeal = mockData.todayMeals.last {
            let elapsed = TimeProvider.shared.currentTime.timeIntervalSince(lastMeal.timestamp)
            let targetFast = 16.0 * 3600 // 16 hour fast target
            return min(elapsed / targetFast, 1.0)
        }
        return 0
    }
    
    private var nextWindowName: String {
        if let window = mockData.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
            return getMealType(for: window)
        }
        return "Day Complete"
    }
    
    private var nextWindowTime: String {
        if let window = mockData.mealWindows.first(where: { $0.startTime > TimeProvider.shared.currentTime }) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: window.startTime)
        }
        return "—"
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
        if mockData.todayMeals.contains(where: { meal in
            meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }) {
            return .phylloAccent
        } else if window.endTime < TimeProvider.shared.currentTime {
            return .red.opacity(0.6)
        } else {
            return .white.opacity(0.3)
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
        mockData.mealWindows.filter { window in
            mockData.todayMeals.contains { meal in
                meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            }
        }.count
    }
    
    private var totalWindows: Int {
        mockData.mealWindows.count
    }
    
    private var totalCalories: Int {
        mockData.todayMeals.reduce(0) { $0 + $1.calories }
    }
    
    private var todayScore: Int {
        Int((timingPercentage + nutrientPercentage + adherencePercentage) / 3)
    }
    
    private var mealTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Timeline")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            // Timeline items
            VStack(spacing: 0) {
                ForEach(mockData.todayMeals) { meal in
                    MealTimelineItem(meal: meal)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    struct MealTimelineItem: View {
        let meal: LoggedMeal
        
        var body: some View {
            HStack(spacing: 12) {
                // Time
                Text(timeString)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.phylloTextSecondary)
                    .frame(width: 50, alignment: .trailing)
                
                // Timeline dot and line
                VStack(spacing: 0) {
                    Circle()
                        .fill(Color.phylloAccent)
                        .frame(width: 8, height: 8)
                    
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 40)
                }
                
                // Meal info
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(meal.calories) cal • \(meal.protein)g P")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                }
                
                Spacer()
            }
        }
        
        private var timeString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: meal.timestamp)
        }
    }
    
    private var nutrientBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Nutrient Status")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            // Large Phyllo Petals visualization
            HexagonFlowerView(
                micronutrients: topNutrients.map { ($0.name, $0.percentage) },
                size: 240,
                showLabels: false,
                showPurposeText: true  // Show nutrient names in petals
            )
            .frame(maxWidth: .infinity)
            
            // Nutrient detail grid below the flower - 2 columns for more space
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(topNutrients, id: \.name) { nutrient in
                    NutrientDetailCard(nutrient: nutrient)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    struct NutrientDetailCard: View {
        let nutrient: NutrientInfo
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
                VStack(spacing: 8) {
                    // Nutrient name and percentage
                    HStack(spacing: 8) {
                        Image(systemName: nutrientBenefits.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(nutrient.color)
                            .frame(width: 20)
                        
                        Text(nutrient.name == "Vit D" ? "Vitamin D" : nutrient.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .layoutPriority(1)
                        
                        Spacer()
                        
                        Text("\(Int(nutrient.percentage * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(nutrient.color)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
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
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
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
    
    private var weeklyAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week's Achievements")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                AchievementRow(icon: "checkmark.circle.fill", text: "Hit all meal windows 3 days", color: .green)
                AchievementRow(icon: "flame.fill", text: "7-day streak maintained", color: .orange)
                AchievementRow(icon: "leaf.fill", text: "90% nutrient targets met", color: .phylloAccent)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    struct AchievementRow: View {
        let icon: String
        let text: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
    
    private var trendChartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Trends")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            // Simple line chart placeholder
            ZStack {
                // Grid lines
                VStack(spacing: 20) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(Color.phylloDivider)
                            .frame(height: 1)
                    }
                }
                
                // Trend line
                Path { path in
                    let points: [CGPoint] = [
                        CGPoint(x: 0, y: 80),
                        CGPoint(x: 50, y: 60),
                        CGPoint(x: 100, y: 70),
                        CGPoint(x: 150, y: 40),
                        CGPoint(x: 200, y: 45),
                        CGPoint(x: 250, y: 30),
                        CGPoint(x: 300, y: 20)
                    ]
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(LinearGradient(
                    colors: [Color.phylloAccent, Color.phylloAccent.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                ), lineWidth: 2)
            }
            .frame(height: 100)
        }
        .padding(20)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
    
    // MARK: - Data
    
    private var ringData: [(id: String, diameter: CGFloat)] {
        [
            (id: "outer", diameter: 240),
            (id: "middle", diameter: 200),
            (id: "inner", diameter: 160)
        ]
    }
    
    private var weekTimingValues: [Double] {
        [0.9, 0.85, 0.95, 0.8, 0.9, 0.7, 0.85]
    }
    
    private var weekNutrientValues: [Double] {
        [0.8, 0.75, 0.85, 0.9, 0.8, 0.65, 0.7]
    }
    
    private var weekAdherenceValues: [Double] {
        [0.95, 0.9, 0.85, 0.9, 0.95, 0.8, 0.9]
    }
    
    private var insights: [NutritionInsight] {
        [
            NutritionInsight(
                title: "Best Energy Days",
                description: "You report 40% higher energy levels when you eat your first meal between 8-10 AM. Your current average is 11:30 AM.",
                icon: "bolt.fill",
                color: .yellow,
                actionText: "Adjust morning routine"
            ),
            NutritionInsight(
                title: "Protein Timing Pattern",
                description: "Your muscle recovery improves when you distribute protein across 3-4 meals rather than 2 large portions.",
                icon: "figure.strengthtraining.traditional",
                color: .blue,
                actionText: nil
            ),
            NutritionInsight(
                title: "Weekend Challenge",
                description: "Your adherence drops 25% on weekends. Pre-planning Friday night can help maintain your momentum.",
                icon: "calendar",
                color: .orange,
                actionText: "Set weekend reminder"
            )
        ]
    }
    
    private var topNutrients: [NutrientInfo] {
        // Calculate actual nutrient percentages from today's meals
        var nutrientTotals: [String: Double] = [:]
        
        // Aggregate all micronutrients from today's meals
        for meal in mockData.todayMeals {
            for (nutrientName, amount) in meal.micronutrients {
                nutrientTotals[nutrientName, default: 0] += amount
            }
        }
        
        // Select top 6 nutrients to display
        let displayNutrients = [
            ("Iron", Color.red),
            ("Vitamin D", Color.orange),
            ("Calcium", Color.blue),
            ("B12", Color.purple),
            ("Folate", Color.green),
            ("Zinc", Color.pink)
        ]
        
        return displayNutrients.compactMap { nutrientPair in
            let (displayName, color) = nutrientPair
            
            // Find the matching nutrient in our data
            let matchingKey = nutrientTotals.keys.first { key in
                key.contains(displayName) || 
                (displayName == "Vitamin D" && key == "Vitamin D") ||
                (displayName == "B12" && key.contains("B12"))
            }
            
            guard let key = matchingKey,
                  let totalAmount = nutrientTotals[key],
                  let micronutrient = MicronutrientData.getAllNutrients().first(where: { $0.name == key }) else {
                // Return default low value if no data
                return NutrientInfo(name: displayName, percentage: 0.1, color: color)
            }
            
            // Calculate percentage of RDA (cap at 100%)
            let percentage = min((totalAmount / micronutrient.rda), 1.0)
            
            return NutrientInfo(name: displayName, percentage: percentage, color: color)
        }
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

// MARK: - Supporting Types

struct NutritionInsight {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let actionText: String?
}

struct NutrientInfo {
    let name: String
    let percentage: Double
    let color: Color
}

// MARK: - Apple Style Ring Component

struct AppleStyleRing: View {
    let progress: Double
    let diameter: CGFloat
    let lineWidth: CGFloat
    let backgroundColor: Color
    let foregroundColors: [Color]
    let icon: String
    let iconAngle: Double
    
    var body: some View {
        ZStack {
            // Background ring (dimmed more for contrast)
            Circle()
                .stroke(backgroundColor.opacity(0.3), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)
            
            // Active ring with 3D effect
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: foregroundColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .shadow(color: foregroundColors.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)
                .overlay(
                    // Add highlight for 3D effect
                    Circle()
                        .trim(from: 0, to: progress * 0.98)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    foregroundColors.last?.opacity(0.4) ?? .clear,
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: lineWidth * 0.3, lineCap: .round)
                        )
                        .frame(width: diameter - lineWidth, height: diameter - lineWidth)
                        .rotationEffect(.degrees(-90))
                        .blur(radius: 1)
                )
            
            // Icon at starting point (top center)
            Image(systemName: icon)
                .font(.system(size: lineWidth * 0.9, weight: .bold))
                .foregroundColor(progress > 0.01 ? foregroundColors.first : backgroundColor.opacity(0.5))
                .background(
                    Circle()
                        .fill(Color.phylloBackground)
                        .frame(width: lineWidth * 1.3, height: lineWidth * 1.3)
                )
                .offset(y: -(diameter / 2))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

#Preview {
    NutritionDashboardView(showDeveloperDashboard: .constant(false))
        .preferredColorScheme(.dark)
}

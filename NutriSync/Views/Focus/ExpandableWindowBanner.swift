//
//  ExpandableWindowBanner.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

// Compact macro remaining indicator for window display
struct WindowMacroIndicator: View {
    let value: Double // 0.0 to 1.0 (proportion consumed)
    let total: Int
    let label: String
    let color: Color
    
    private var remaining: Int {
        // value is the proportion consumed (0.0 to 1.0)
        // So consumed amount = total * value
        // And remaining = total - consumed
        let consumed = Int(Double(total) * value)
        return max(0, total - consumed)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(remaining)g")
                .font(TimelineTypography.macroValue)
                .foregroundColor(color)
                .monospacedDigit()
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * min(value, 1.0), height: 4)
                }
                .clipShape(Capsule())
            }
            .frame(height: 4)
            
            Text(label)
                .font(TimelineTypography.macroLabel)
                .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
        }
        .frame(maxWidth: .infinity)
    }
}

// Animated switcher between macros and window purpose
struct AnimatedInfoSwitcher: View {
    let window: MealWindow
    let isActive: Bool
    @State private var showMacros = true
    
    // Timer for switching
    let timer = Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Macros display
            HStack(spacing: 3) {
                Text("\(window.effectiveMacros.protein)g")
                    .font(TimelineTypography.macroValue)
                    .foregroundColor(.orange.opacity(0.8))
                    .minimumScaleFactor(0.8)
                Text("P")
                    .font(TimelineTypography.macroLabel)
                    .foregroundColor(.orange.opacity(0.6))
                
                Text("·")
                    .font(TimelineTypography.macroLabel)
                    .foregroundColor(.white.opacity(TimelineOpacity.quaternary))
                
                Text("\(window.effectiveMacros.fat)g")
                    .font(TimelineTypography.macroValue)
                    .foregroundColor(.yellow.opacity(0.8))
                    .minimumScaleFactor(0.8)
                Text("F")
                    .font(TimelineTypography.macroLabel)
                    .foregroundColor(.yellow.opacity(0.6))
                
                Text("·")
                    .font(TimelineTypography.macroLabel)
                    .foregroundColor(.white.opacity(TimelineOpacity.quaternary))
                
                Text("\(window.effectiveMacros.carbs)g")
                    .font(TimelineTypography.macroValue)
                    .foregroundColor(.blue.opacity(0.8))
                    .minimumScaleFactor(0.8)
                Text("C")
                    .font(TimelineTypography.macroLabel)
                    .foregroundColor(.blue.opacity(0.6))
            }
            .lineLimit(1)
            .opacity(showMacros ? 1 : 0)
            .scaleEffect(showMacros ? 1 : 0.9)
            .offset(y: showMacros ? 0 : 3)
            
            // Window purpose display
            HStack(spacing: 3) {
                Image(systemName: window.purpose.icon)
                    .font(TimelineTypography.macroLabel)
                Text(window.purpose.rawValue)
                    .font(TimelineTypography.macroLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(window.purpose.color)
            .opacity(showMacros ? 0 : 1)
            .scaleEffect(showMacros ? 0.9 : 1)
            .offset(y: showMacros ? -3 : 0)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showMacros)
        .onReceive(timer) { _ in
            withAnimation {
                showMacros.toggle()
            }
        }
        .onAppear {
            // Start with macros for active windows, purpose for inactive
            showMacros = isActive
        }
    }
}

struct ExpandableWindowBanner: View {
    let window: MealWindow
    let meals: [LoggedMeal]
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    @ObservedObject var viewModel: ScheduleViewModel
    // Optional fixed banner height so the card can exactly represent the time span on the timeline
    let bannerHeight: CGFloat?
    
    // State for missed window actions
    @State private var showMissedWindowActions = false
    @State private var showInlineMissedActions = false
    @State private var showSimplifiedMealLogging = false
    @State private var selectedMissedWindow: MealWindow?
    @State private var isProcessingFasting = false
    
    // Add analyzing meals for this window - only if scanned within window time
    private var analyzingMealsInWindow: [AnalyzingMeal] {
        viewModel.analyzingMeals.filter { meal in
            // Prefer assigned window
            if meal.windowId == window.id { return true }
            // Fallback: if within flexibility buffer before start or during window, show it
            let beforeStart = meal.timestamp >= window.startTime.addingTimeInterval(-window.flexibility.timeBuffer) && meal.timestamp < window.startTime
            let during = meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
            return beforeStart || during
        }
    }
    
    @StateObject private var timeProvider = TimeProvider.shared
    @State private var isExpanded = false
    @State private var pulseAnimation = false
    
    // Use AI-generated name if available, otherwise categorize by time-of-day
    private var mealType: String {
        // If window has an AI-generated name, use it
        if !window.name.isEmpty {
            return window.name
        }
        
        // Otherwise use the default time-based naming
        let base = baseMealName(for: window.startTime)
        // Count prior windows with same base
        let priorSame = viewModel.mealWindows
            .filter { baseMealName(for: $0.startTime) == base && $0.startTime < window.startTime }
            .count
        if priorSame == 0 { return base }
        return "\(base) \(priorSame + 1)"
    }

    private func baseMealName(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5...10: return "Breakfast"
        case 11...12: return "Brunch"
        case 13...15: return "Lunch"
        case 16...17: return "Snack"
        case 18...21: return "Dinner"
        default: return "Snack"
        }
    }
    
    private var mealIcon: String {
        switch mealType.lowercased() {
        case "breakfast":
            return "sun.max.fill"
        case "brunch", "lunch":
            return "sun.min.fill"
        case "dinner":
            return "moon.fill"
        case "snack", "late snack":
            return "leaf.fill"
        default:
            return "fork.knife"
        }
    }
    
    private var timeUntilWindow: String {
        let now = timeProvider.currentTime
        let timeUntil = window.startTime.timeIntervalSince(now)
        
        // Check if meals have been logged
        let hasMeals = !meals.isEmpty
        
        if timeUntil > 0 {
            // Upcoming window
            let hours = Int(timeUntil) / 3600
            let minutes = (Int(timeUntil) % 3600) / 60
            
            if hours > 0 {
                return "in \(hours)h \(minutes)m"
            } else {
                return "in \(minutes)m"
            }
        } else if case .active = windowStatus {
            // Currently active window
            if hasMeals {
                // Check if first meal was logged late, early, or on time
                if let firstMeal = meals.first {
                    if firstMeal.timestamp > window.endTime {
                        // Started late (after window ended)
                        let hoursLate = Int(firstMeal.timestamp.timeIntervalSince(window.endTime)) / 3600
                        let minutesLate = (Int(firstMeal.timestamp.timeIntervalSince(window.endTime)) % 3600) / 60
                        if hoursLate > 0 {
                            return "started \(hoursLate)h \(minutesLate)m late"
                        } else {
                            return "started \(minutesLate)m late"
                        }
                    } else if firstMeal.timestamp < window.startTime {
                        // Started early (before window started)
                        let hoursEarly = Int(window.startTime.timeIntervalSince(firstMeal.timestamp)) / 3600
                        let minutesEarly = (Int(window.startTime.timeIntervalSince(firstMeal.timestamp)) % 3600) / 60
                        if hoursEarly > 0 {
                            return "started \(hoursEarly)h \(minutesEarly)m early"
                        } else {
                            return "started \(minutesEarly)m early"
                        }
                    } else {
                        // Logged on time (within window)
                        return ""  // Don't show redundant text since we're already showing time remaining
                    }
                }
            } else {
                // No meals logged yet, show time remaining
                if let remaining = window.timeRemaining {
                    return "\(formatTime(remaining)) remaining"
                }
                return "Active now"
            }
        } else {
            // Past window
            if hasMeals {
                // Don't show late text for completed windows
                return ""
            } else {
                // Only show late for missed windows
                let timeLate = -timeUntil
                let hours = Int(timeLate) / 3600
                let minutes = (Int(timeLate) % 3600) / 60
                
                if hours > 0 {
                    return "\(hours)h \(minutes)m late"
                } else {
                    return "\(minutes)m late"
                }
            }
        }
        
        return ""
    }
    
    private var windowProgress: Double {
        guard case .active = windowStatus else { return 0 }
        let elapsed = timeProvider.currentTime.timeIntervalSince(window.startTime)
        let total = window.duration
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }
    
    private var windowCaloriesRemaining: Int {
        let consumed = viewModel.caloriesConsumedInWindow(window)
        return max(0, window.effectiveCalories - consumed)
    }
    
    // Window status enum for clearer state management
    private enum WindowStatus: Equatable {
        case upcoming
        case active
        case lateButDoable
        case completed(consumed: Int, target: Int, redistribution: WindowRedistributionManager.RedistributionReason?)
        case missed(redistribution: WindowRedistributionManager.RedistributionReason?)
        
        static func == (lhs: WindowStatus, rhs: WindowStatus) -> Bool {
            switch (lhs, rhs) {
            case (.upcoming, .upcoming), (.active, .active), (.lateButDoable, .lateButDoable):
                return true
            case (.completed(let lConsumed, let lTarget, _), .completed(let rConsumed, let rTarget, _)):
                return lConsumed == rConsumed && lTarget == rTarget
            case (.missed(_), .missed(_)):
                return true
            default:
                return false
            }
        }
    }
    
    private var windowStatus: WindowStatus {
        let now = timeProvider.currentTime
        let hasMeals = !meals.isEmpty
        
        // If window has meals and hasn't started yet, treat it as active (started early)
        if now < window.startTime && hasMeals {
            return .active
        } else if now < window.startTime {
            return .upcoming
        } else if now >= window.startTime && now <= window.endTime {
            return .active
        } else {
            // Window is past - determine the specific status
            
            if hasMeals {
                // Window has meals - it's completed
                let consumed = viewModel.caloriesConsumedInWindow(window)
                return .completed(
                    consumed: consumed,
                    target: window.effectiveCalories,
                    redistribution: window.redistributionReason
                )
            } else {
                // No meals - check if it's late but doable
                let nextWindow = viewModel.mealWindows.first { 
                    $0.startTime > window.startTime && $0.id != window.id 
                }
                
                if window.isLateButDoable(nextWindow: nextWindow) {
                    return .lateButDoable
                } else {
                    return .missed(redistribution: window.redistributionReason)
                }
            }
        }
    }
    
    // Check if it's optimal time to eat (within first 30% of window)
    private var isOptimalTime: Bool {
        guard case .active = windowStatus, meals.isEmpty else { return false }
        let elapsed = timeProvider.currentTime.timeIntervalSince(window.startTime)
        let optimalPeriod = window.duration * 0.3 // First 30% of window
        return elapsed <= optimalPeriod
    }
    
    // Window opacity based on status
    private var windowOpacity: Double {
        switch windowStatus {
        case .completed, .missed:
            return 0.7
        case .lateButDoable:
            return 0.85
        case .active, .upcoming:
            return 1.0
        }
    }
    
    // Window border color based on status
    private var windowBorderColor: Color {
        switch windowStatus {
        case .active:
            return window.purpose.color.opacity(0.4)
        case .lateButDoable:
            return Color.yellow.opacity(0.3)
        case .completed:
            return Color.white.opacity(0.08)
        case .missed:
            return Color.orange.opacity(0.2)
        case .upcoming:
            return Color.white.opacity(0.08)
        }
    }
    
    // Window background color based on status
    private var windowBackgroundColor: Color {
        switch windowStatus {
        case .completed, .missed:
            return Color(red: 0.08, green: 0.08, blue: 0.09)  // Darker for passed windows
        case .lateButDoable:
            return Color(red: 0.12, green: 0.11, blue: 0.10)  // Slightly yellow tint
        case .active, .upcoming:
            return Color(red: 0.11, green: 0.11, blue: 0.12)  // Normal dark gray
        }
    }
    
    // Check if window is about to start (within 15 minutes)
    private var isStartingSoon: Bool {
        guard window.isUpcoming else { return false }
        let timeUntil = window.startTime.timeIntervalSince(timeProvider.currentTime)
        return timeUntil <= 15 * 60 // 15 minutes
    }
    
    // Check for circadian optimization indicators
    private var isCircadianOptimal: Bool {
        switch window.purpose {
        case .sleepOptimization:
            // Last meal should be finishing soon for sleep optimization
            let hoursUntilSleep = 3.0 // Assuming 3 hours between last meal and sleep
            let timeToFinishEating = window.endTime.timeIntervalSince(timeProvider.currentTime)
            return timeToFinishEating > 0 && timeToFinishEating <= hoursUntilSleep * 3600
        case .preWorkout:
            // Should eat 1-2 hours before workout
            if case .active = windowStatus { return true }
            return isStartingSoon
        case .postWorkout:
            // Critical window - should eat ASAP after workout
            if case .active = windowStatus, meals.isEmpty { return true }
            return false
        default:
            return false
        }
    }
    
    var body: some View {
        // Container only; tap/drag handled by overlay layer wrapper
        VStack(spacing: 0) {
            // Replace banner content with actions when showing missed actions
            if case .missed = windowStatus, showInlineMissedActions {
                missedWindowActionsContent
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
            } else {
                windowBannerContent
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity
                    ))
            }
            
            // Show additional content for active windows when empty
            if window.isActive && meals.isEmpty && analyzingMealsInWindow.isEmpty {
                windowInsightsSection
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
            
            // Remove spacer - let content determine height naturally
            
            // Meals section (if any meals or analyzing)
            if !meals.isEmpty || !analyzingMealsInWindow.isEmpty {
                mealsSection
            }
        }
        .frame(maxWidth: .infinity) // Ensure VStack fills available width
        .background(windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    windowBorderColor,
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .opacity(windowOpacity)
        .overlay(optimalTimeIndicators)
        // Apply fixed height if provided so the background and content expand to match duration
        .frame(minHeight: nil, idealHeight: bannerHeight, maxHeight: bannerHeight, alignment: .top)
        .onTapGesture {
            // Check if this is a missed window
            if case .missed = windowStatus {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showInlineMissedActions.toggle()
                }
            } else {
                // Normal behavior for other windows
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    selectedWindow = window
                    showWindowDetail = true
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
        // Removed old modal sheet - now using inline UI for missed windows
        .sheet(isPresented: $showSimplifiedMealLogging) {
            if let missedWindow = selectedMissedWindow {
                SimplifiedMealLoggingView(
                    window: missedWindow,
                    viewModel: viewModel,
                    isPresented: $showSimplifiedMealLogging
                )
            }
        }
    }
    
    @ViewBuilder
    private var windowBannerContent: some View {
        HStack(spacing: 8) {
            windowInfoSection
                .frame(maxWidth: .infinity, alignment: .leading)
            
            quickStatsSection
                .frame(minWidth: 80, alignment: .trailing)
            
            statusIndicator
                .frame(width: 44, height: 44)
        }
        .padding(windowBannerPadding)
    }
    
    // Use consistent padding for cleaner look
    private var windowBannerPadding: CGFloat {
        return 14
    }
    
    @ViewBuilder
    private var windowInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: mealIcon)
                    .font(.system(size: { if case .active = windowStatus { return 17 } else { return 15 } }()))
                Text(mealType)
                    .font({ if case .active = windowStatus { return TimelineTypography.windowTitle } else { return TimelineTypography.windowTitleInactive } }())
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundColor(.white)
            
            // Time range display with duration
            VStack(alignment: .leading, spacing: 1) {
                Text(formatTimeRange(start: window.startTime, end: window.endTime))
                    .font(TimelineTypography.timeRange)
                    .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                
                // Show duration for windows longer than 1 hour
                if window.duration > 3600 {
                    Text("\(formatDuration(window.duration)) window")
                        .font(TimelineTypography.duration)
                        .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
                }
            }
            
            // Status text based on window state
            switch windowStatus {
            case .active:
                HStack(spacing: 4) {
                    if let remaining = window.timeRemaining {
                        Image(systemName: "clock")
                            .font(TimelineTypography.statusLabel)
                        Text("\(formatTime(remaining)) left")
                            .font(TimelineTypography.statusValue)
                            .monospacedDigit()
                    }
                }
                .foregroundColor(window.timeRemaining ?? 0 < 1800 ? .orange : .white.opacity(0.9))
                
            case .lateButDoable:
                if let hoursLate = window.hoursLate {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(TimelineTypography.statusLabel)
                        if hoursLate < 1 {
                            Text("\(Int(hoursLate * 60))m late •")
                                .monospacedDigit()
                            Text("still doable")
                        } else {
                            Text("\(Int(hoursLate))h late •")
                                .monospacedDigit()
                            Text("still doable")
                        }
                    }
                    .font(TimelineTypography.statusValue)
                    .foregroundColor(.yellow)
                }
                
            case .completed, .missed:
                if !timeUntilWindow.isEmpty {
                    Text(timeUntilWindow)
                        .font(TimelineTypography.statusLabel)
                        .monospacedDigit()
                        .foregroundColor(.orange.opacity(0.8))
                }
                
            case .upcoming:
                Text(timeUntilWindow)
                    .font(TimelineTypography.statusLabel)
                    .monospacedDigit()
                    .foregroundColor(getTimeTextColor())
            }
        }
    }
    
    @ViewBuilder
    private var quickStatsSection: some View {
        VStack(alignment: .trailing, spacing: 3) {
            switch windowStatus {
            case .completed(let consumed, let target, let redistribution):
                // Show consumed vs target
                HStack(spacing: 2) {
                    Text("\(consumed)")
                        .font(consumed >= 1000 ? TimelineTypography.caloriesSmall : TimelineTypography.caloriesMedium)
                        .monospacedDigit()
                        .foregroundColor(consumptionColor(consumed: consumed, target: target))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("/")
                        .font(TimelineTypography.calorieUnit)
                        .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
                    Text("\(target)")
                        .font(TimelineTypography.calorieUnit)
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                        .minimumScaleFactor(0.6)
                    Text("cal")
                        .font(TimelineTypography.calorieUnit)
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                }
                
                // Show redistribution info if available
                if let reason = redistribution {
                    redistributionText(for: reason)
                        .font(TimelineTypography.duration)
                        .foregroundColor(redistributionColor(for: reason))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("completed")
                        .font(TimelineTypography.statusLabel)
                        .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
                }
                
            case .missed(let redistribution):
                HStack(spacing: 2) {
                    Text("\(window.effectiveCalories)")
                        .font(window.effectiveCalories >= 1000 ? TimelineTypography.caloriesSmall : TimelineTypography.caloriesMedium)
                        .monospacedDigit()
                        .foregroundColor(.orange.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("cal")
                        .font(TimelineTypography.calorieUnit)
                        .foregroundColor(.orange.opacity(0.7))
                }
                
                if let reason = redistribution {
                    redistributionText(for: reason)
                        .font(TimelineTypography.duration)
                        .foregroundColor(.orange.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("missed")
                        .font(TimelineTypography.statusLabel)
                        .foregroundColor(.orange.opacity(0.7))
                }
                
            case .lateButDoable:
                HStack(spacing: 2) {
                    Text("\(window.effectiveCalories)")
                        .font(window.effectiveCalories >= 1000 ? TimelineTypography.caloriesSmall : TimelineTypography.caloriesMedium)
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("cal")
                        .font(TimelineTypography.calorieUnit)
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                }
                
                AnimatedInfoSwitcher(window: window, isActive: false)
                    .frame(maxWidth: 140)
                
            case .active:
                HStack(spacing: 2) {
                    Text("\(windowCaloriesRemaining)")
                        .font(windowCaloriesRemaining >= 1000 ? TimelineTypography.caloriesSmall : TimelineTypography.caloriesLarge)
                        .monospacedDigit()
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .layoutPriority(1)
                    Text("cal")
                        .font(TimelineTypography.calorieUnit)
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                }
                
                Text("remaining")
                    .font(TimelineTypography.statusLabel)
                    .foregroundColor(.white.opacity(TimelineOpacity.tertiary))
                
            case .upcoming:
                HStack(spacing: 2) {
                    Text("\(window.effectiveCalories)")
                        .font(window.effectiveCalories >= 1000 ? TimelineTypography.caloriesSmall : TimelineTypography.caloriesMedium)
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .layoutPriority(1)
                    Text("cal")
                        .font(TimelineTypography.calorieUnit)
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                }
                
                AnimatedInfoSwitcher(window: window, isActive: false)
                    .frame(maxWidth: 140)
            }
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch windowStatus {
        case .active:
            progressRing
        case .completed:
            completedIndicator
        case .missed:
            missedIndicator
        case .lateButDoable:
            lateButDoableIndicator
        case .upcoming:
            upcomingIndicator
        }
    }
    
    @ViewBuilder
    private var progressRing: some View {
        let consumed = viewModel.caloriesConsumedInWindow(window)
        let progressValue = window.effectiveCalories > 0 ? min(Double(consumed) / Double(window.effectiveCalories), 1.0) : 0
        
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(Color.white.opacity(0.1), lineWidth: 2)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(90))
            
            Circle()
                .trim(from: 0, to: progressValue * 0.76)
                .stroke(
                    window.purpose.color,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(126))
                .animation(.linear(duration: 1), value: progressValue)
            
            Text("\(Int(progressValue * 100))%")
                .font(TimelineTypography.progressPercentage)
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
    
    @ViewBuilder
    private var upcomingIndicator: some View {
        Text("Soon")
            .font(TimelineTypography.progressLabel)
            .foregroundColor(.white.opacity(TimelineOpacity.secondary))
            .frame(width: 40)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
    }
    
    @ViewBuilder
    private var completedIndicator: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.green)
            .frame(width: 50, height: 50)
    }
    
    @ViewBuilder
    private var missedIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 50, height: 50)
            
            Text("Missed")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.orange)
        }
    }
    
    @ViewBuilder
    private var lateButDoableIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.yellow.opacity(0.15))
                .frame(width: 50, height: 50)
            
            VStack(spacing: 0) {
                Text("Late")
                    .font(.system(size: 10, weight: .semibold))
                
                if let hoursLate = window.hoursLate {
                    if hoursLate < 1 {
                        Text("\(Int(hoursLate * 60))m")
                            .font(.system(size: 9))
                    } else {
                        Text("\(Int(hoursLate))h")
                            .font(.system(size: 9))
                    }
                }
            }
            .foregroundColor(.yellow)
        }
    }
    
    @ViewBuilder
    private var windowInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            VStack(alignment: .leading, spacing: 8) {
                // Window purpose insight
                HStack(spacing: 6) {
                    Image(systemName: window.purpose.icon)
                        .font(.system(size: 12))
                        .foregroundColor(window.purpose.color)
                    
                    Text(getPurposeInsight())
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Show remaining macros for active windows (only when empty to guide choices)
                if case .active = windowStatus, meals.isEmpty && analyzingMealsInWindow.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remaining in window:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        HStack(spacing: 16) {
                            WindowMacroIndicator(
                                value: window.effectiveMacros.protein > 0 ? Double(meals.reduce(0) { $0 + $1.protein }) / Double(window.effectiveMacros.protein) : 0,
                                total: window.effectiveMacros.protein,
                                label: "P",
                                color: .orange
                            )
                            WindowMacroIndicator(
                                value: window.effectiveMacros.fat > 0 ? Double(meals.reduce(0) { $0 + $1.fat }) / Double(window.effectiveMacros.fat) : 0,
                                total: window.effectiveMacros.fat,
                                label: "F",
                                color: .yellow
                            )
                            WindowMacroIndicator(
                                value: window.effectiveMacros.carbs > 0 ? Double(meals.reduce(0) { $0 + $1.carbs }) / Double(window.effectiveMacros.carbs) : 0,
                                total: window.effectiveMacros.carbs,
                                label: "C",
                                color: .blue
                            )
                        }
                    }
                }
                
                // Meal suggestions based on remaining macros (only show when empty)
                if case .active = windowStatus, meals.isEmpty && analyzingMealsInWindow.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suggested meals:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(getMealSuggestions().prefix(2), id: \.self) { suggestion in
                                    HStack(spacing: 4) {
                                        Image(systemName: getSuggestionIcon(suggestion))
                                            .font(.system(size: 10))
                                        Text(suggestion)
                                            .font(.system(size: 11))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Capsule())
                                    .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // Timing reminder for upcoming windows
                if case .upcoming = windowStatus, isStartingSoon {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text("Prepare your meal soon")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: windowStatus)
    }
    
    @ViewBuilder
    private var missedWindowActionsContent: some View {
        ZStack {
            // Background tap to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showInlineMissedActions = false
                    }
                }
            
            HStack(spacing: 0) {
                // Log meal button (left side)
                Button(action: {
                    selectedMissedWindow = window
                    showSimplifiedMealLogging = true
                    showInlineMissedActions = false
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 14))
                        Text("Log meal")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Vertical divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 16)
                
                // Mark as fasted button (right side)
                Button(action: {
                    Task {
                        isProcessingFasting = true
                        await viewModel.markWindowAsFasted(windowId: window.id)
                        isProcessingFasting = false
                        showInlineMissedActions = false
                    }
                }) {
                    HStack(spacing: 6) {
                        if isProcessingFasting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "clock.badge.xmark")
                                .font(.system(size: 14))
                        }
                        Text("I was fasting")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessingFasting)
                .opacity(isProcessingFasting ? 0.5 : 1.0)
            }
            .frame(height: 56) // Slightly smaller to match banner content
            .padding(.horizontal, windowBannerPadding)
        }
    }
    
    private func getPurposeInsight() -> String {
        switch window.purpose {
        case .recovery:
            return "Focus on protein and nutrient-dense foods for optimal recovery"
        case .sustainedEnergy:
            return "Include complex carbs and healthy fats for lasting energy"
        case .focusBoost:
            return "Light meal with brain-boosting nutrients"
        case .metabolicBoost:
            return "Balanced meal to support metabolism"
        case .preWorkout:
            return "Energizing carbs and moderate protein"
        case .postWorkout:
            return "High protein within 30 minutes for muscle recovery"
        case .sleepOptimization:
            return "Light, easy-to-digest foods to promote better sleep"
        }
    }
    
    private func getMealSuggestions() -> [String] {
        // Return meal suggestions based on window purpose
        switch window.purpose {
        case .recovery:
            return ["Grilled Chicken", "Greek Yogurt", "Quinoa Bowl"]
        case .sustainedEnergy:
            return ["Oatmeal", "Avocado Toast", "Brown Rice"]
        case .focusBoost:
            return ["Berries", "Nuts", "Green Tea"]
        case .metabolicBoost:
            return ["Lean Protein", "Vegetables", "Whole Grains"]
        case .preWorkout:
            return ["Banana", "Energy Bar", "Smoothie"]
        case .postWorkout:
            return ["Protein Shake", "Tuna Wrap", "Eggs"]
        case .sleepOptimization:
            return ["Cottage Cheese", "Almonds", "Herbal Tea"]
        }
    }
    
    private func getSuggestionIcon(_ suggestion: String) -> String {
        switch suggestion.lowercased() {
        case let s where s.contains("chicken") || s.contains("tuna") || s.contains("protein"):
            return "fish.fill"
        case let s where s.contains("yogurt") || s.contains("cottage cheese") || s.contains("shake"):
            return "cup.and.saucer.fill"
        case let s where s.contains("rice") || s.contains("quinoa") || s.contains("oatmeal"):
            return "leaf.fill"
        case let s where s.contains("berries") || s.contains("banana"):
            return "carrot.fill"
        case let s where s.contains("nuts") || s.contains("almonds"):
            return "circle.hexagongrid.fill"
        case let s where s.contains("tea"):
            return "mug.fill"
        default:
            return "fork.knife"
        }
    }
    
    @ViewBuilder
    private var mealsSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 14)
            
            // Show analyzing meals first
            ForEach(analyzingMealsInWindow) { analyzingMeal in
                AnalyzingMealRowCompact(meal: analyzingMeal)
                    .padding(.horizontal, 14)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Then show logged meals
            ForEach(meals) { meal in
                MealRowCompact(meal: meal)
                    .padding(.horizontal, 14)
            }
        }
        .padding(.bottom, 14)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))  // Ensure opaque background for meals section
    }
    
    private var windowBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(red: 0.12, green: 0.12, blue: 0.13)) // Slightly lighter than pure black
            .matchedGeometryEffect(
                id: "window-\(window.id)",
                in: animationNamespace,
                properties: .frame,
                isSource: true
            )
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatWindowTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        // Check if both times are in the same AM/PM period
        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)
        let sameAMPM = (startHour < 12 && endHour < 12) || (startHour >= 12 && endHour >= 12)
        
        if sameAMPM {
            // Show AM/PM only at the end
            formatter.dateFormat = "h:mm"
            let startTime = formatter.string(from: start)
            formatter.dateFormat = "h:mm a"
            let endTime = formatter.string(from: end)
            return "\(startTime) - \(endTime)"
        } else {
            // Show AM/PM for both when they differ
            formatter.dateFormat = "h:mm a"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
    
    private func getTimeTextColor() -> Color {
        let text = timeUntilWindow
        if text.contains("late") {
            return .orange.opacity(0.8)
        } else if text.contains("early") {
            return .blue.opacity(0.8)
        } else if text.contains("on time") {
            return .green.opacity(0.8)
        } else {
            return .white.opacity(0.7)
        }
    }
    
    @ViewBuilder
    private var optimalTimeIndicators: some View {
        ZStack {
            // Glowing border for optimal eating time
            if (isOptimalTime || isCircadianOptimal) && meals.isEmpty {
                RoundedRectangle(cornerRadius: { if case .active = windowStatus { return 16 } else { return 12 } }())
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.nutriSyncAccent.opacity(0.6),
                                Color.nutriSyncAccent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: Color.nutriSyncAccent.opacity(0.3), radius: pulseAnimation ? 8 : 4)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            }
            
            // Starting soon indicator
            if isStartingSoon, case .upcoming = windowStatus {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                            Text("Starting Soon")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.2))
                        )
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            }
            
            // Post-workout urgency indicator
            if window.purpose == .postWorkout, case .active = windowStatus, meals.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                            Text("Eat Soon")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.2))
                        )
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }
    
    // Helper function to determine color based on consumption
    private func consumptionColor(consumed: Int, target: Int) -> Color {
        guard target > 0 else { return .gray }
        let percentage = Double(consumed) / Double(target)
        
        if percentage < 0.8 {
            return .yellow // Under-consumed
        } else if percentage > 1.2 {
            return .orange // Over-consumed
        } else {
            return .green // Within range
        }
    }
    
    // Helper function to get redistribution text
    private func redistributionText(for reason: WindowRedistributionManager.RedistributionReason) -> Text {
        switch reason {
        case .overconsumption(let percent):
            return Text("\(percent)% redistributed →")
        case .underconsumption(let percent):
            return Text("\(percent)% redistributed →")
        case .missedWindow:
            return Text("redistributed →")
        case .earlyConsumption:
            return Text("early • redistributed →")
        case .lateConsumption:
            return Text("late • redistributed →")
        }
    }
    
    // Helper function to get redistribution color
    private func redistributionColor(for reason: WindowRedistributionManager.RedistributionReason) -> Color {
        switch reason {
        case .overconsumption:
            return .orange.opacity(0.7)
        case .underconsumption:
            return .yellow.opacity(0.7)
        case .missedWindow:
            return .orange.opacity(0.7)
        case .earlyConsumption:
            return .blue.opacity(0.7)
        case .lateConsumption:
            return .yellow.opacity(0.7)
        }
    }
}

// Compact meal row for inside window banner
struct MealRowCompact: View {
    let meal: LoggedMeal
    
    var body: some View {
        HStack(spacing: 6) {
            // Time
            Text(timeFormatter.string(from: meal.timestamp))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Food emoji
            Text(meal.emoji)
                .font(.system(size: 16))
                .frame(width: 20)
            
            // Meal info
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 3) {
                    // Calories
                    HStack(spacing: 2) {
                        Text("\(meal.calories)")
                            .font(.system(size: 10, weight: .medium))
                            .monospacedDigit()
                            .foregroundColor(.white.opacity(0.7))
                            .minimumScaleFactor(0.8)
                        Text("cal")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text("·")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Macros with better spacing
                    HStack(spacing: 4) {
                        Text("\(meal.protein)g")
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundColor(.orange.opacity(0.7))
                            .minimumScaleFactor(0.8)
                        
                        Text("\(meal.fat)g")
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundColor(.yellow.opacity(0.7))
                            .minimumScaleFactor(0.8)
                        
                        Text("\(meal.carbs)g")
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundColor(.blue.opacity(0.7))
                            .minimumScaleFactor(0.8)
                    }
                }
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}

// Compact analyzing meal row for inside window banner
struct AnalyzingMealRowCompact: View {
    let meal: AnalyzingMeal
    @State private var dotsAnimation = false
    @State private var currentMessageIndex = 0
    @State private var messageTimer: Timer?
    
    let messages = [
        "Analyzing meal...",
        "Processing...",
        "Calculating...",
        "Almost done..."
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            // Time
            Text(timeFormatter.string(from: meal.timestamp))
                .font(.system(size: 11))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Loading dots instead of emoji
            HStack(spacing: 3) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.nutriSyncAccent)
                        .frame(width: 5, height: 5)
                        .scaleEffect(dotsAnimation ? 1.0 : 0.5)
                        .opacity(dotsAnimation ? 1.0 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: dotsAnimation
                        )
                }
            }
            .frame(width: 16)
            
            // Meal info
            VStack(alignment: .leading, spacing: 1) {
                Text(messages[currentMessageIndex])
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                
                // Shimmer for macros
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 11)
                    .shimmer()
            }
            
            Spacer()
            
            // Loading spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .nutriSyncAccent.opacity(0.6)))
                .scaleEffect(0.6)
        }
        .onAppear {
            dotsAnimation = true
            startMessageRotation()
        }
        .onDisappear {
            messageTimer?.invalidate()
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    
    private func startMessageRotation() {
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedWindow: MealWindow?
    @Previewable @State var showWindowDetail = false
    @Previewable @Namespace var animationNamespace
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        VStack(spacing: 16) {
            if let window = viewModel.activeWindow {
                ExpandableWindowBanner(
                    window: window,
                    meals: viewModel.mealsInWindow(window),
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail,
                    animationNamespace: animationNamespace,
                    viewModel: viewModel,
                    bannerHeight: nil
                )
                .padding(.horizontal)
            }
        }
    }
}
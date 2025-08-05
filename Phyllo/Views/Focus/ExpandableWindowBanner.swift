//
//  ExpandableWindowBanner.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

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
            HStack(spacing: 4) {
                Text("\(window.effectiveMacros.protein)g P")
                    .font(.system(size: 10))
                    .foregroundColor(.orange.opacity(0.8))
                
                Text("\(window.effectiveMacros.fat)g F")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow.opacity(0.8))
                
                Text("\(window.effectiveMacros.carbs)g C")
                    .font(.system(size: 10))
                    .foregroundColor(.blue.opacity(0.8))
            }
            .lineLimit(1)
            .opacity(showMacros ? 1 : 0)
            .scaleEffect(showMacros ? 1 : 0.9)
            .offset(y: showMacros ? 0 : 3)
            
            // Window purpose display
            HStack(spacing: 4) {
                Image(systemName: window.purpose.icon)
                    .font(.system(size: 10))
                Text(window.purpose.rawValue)
                    .font(.system(size: 10, weight: .medium))
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
    
    // Add analyzing meals for this window - only if scanned within window time
    private var analyzingMealsInWindow: [AnalyzingMeal] {
        viewModel.analyzingMeals.filter { meal in
            // Must be assigned to this window AND scanned within window time
            meal.windowId == window.id &&
            meal.timestamp >= window.startTime &&
            meal.timestamp <= window.endTime
        }
    }
    
    @StateObject private var timeProvider = TimeProvider.shared
    @State private var isExpanded = false
    @State private var pulseAnimation = false
    
    private var mealType: String {
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
    
    private var mealIcon: String {
        switch mealType.lowercased() {
        case "breakfast":
            return "sun.max.fill"
        case "lunch":
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
        
        if now < window.startTime {
            return .upcoming
        } else if now >= window.startTime && now <= window.endTime {
            return .active
        } else {
            // Window is past - determine the specific status
            let hasMeals = !meals.isEmpty
            
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
            return window.purpose.color.opacity(0.5)
        case .lateButDoable:
            return Color.yellow.opacity(0.3)
        case .completed:
            return Color.white.opacity(0.05)
        case .missed:
            return Color.orange.opacity(0.2)
        case .upcoming:
            return Color.white.opacity(0.1)
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
        case .preworkout:
            // Should eat 1-2 hours before workout
            if case .active = windowStatus { return true }
            return isStartingSoon
        case .postworkout:
            // Critical window - should eat ASAP after workout
            if case .active = windowStatus, meals.isEmpty { return true }
            return false
        default:
            return false
        }
    }
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                selectedWindow = window
                showWindowDetail = true
            }
        } label: {
            VStack(spacing: 0) {
                windowBannerContent
                
                // Meals section (if any meals or analyzing)
                if !meals.isEmpty || !analyzingMealsInWindow.isEmpty {
                    mealsSection
                }
            }
            .background(windowBackground)
            .clipShape(RoundedRectangle(cornerRadius: { if case .active = windowStatus { return 16 } else { return 12 } }()))
            .overlay(
                RoundedRectangle(cornerRadius: { if case .active = windowStatus { return 16 } else { return 12 } }())
                    .strokeBorder(
                        windowBorderColor,
                        lineWidth: { if case .active = windowStatus { return 2 } else { return 1 } }()
                    )
            )
            .opacity(windowOpacity)
            .overlay(optimalTimeIndicators)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    @ViewBuilder
    private var windowBannerContent: some View {
        HStack(spacing: 12) {
            windowInfoSection
            
            Spacer()
            
            quickStatsSection
            
            statusIndicator
                .frame(width: 50, height: 50)
        }
        .padding({ if case .active = windowStatus { return 16 } else { return 12 } }())
    }
    
    @ViewBuilder
    private var windowInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: mealIcon)
                    .font(.system(size: { if case .active = windowStatus { return 14 } else { return 12 } }()))
                Text(mealType)
                    .font(.system(size: { if case .active = windowStatus { return 14 } else { return 13 } }(), weight: .semibold))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(.white)
            
            // Time range display
            Text(formatTimeRange(start: window.startTime, end: window.endTime))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Status text based on window state
            switch windowStatus {
            case .active:
                HStack(spacing: 4) {
                    if let remaining = window.timeRemaining {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(formatTime(remaining)) left")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundColor(window.timeRemaining ?? 0 < 1800 ? .orange : .white.opacity(0.9))
                
            case .lateButDoable:
                if let hoursLate = window.hoursLate {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 11))
                        if hoursLate < 1 {
                            Text("\(Int(hoursLate * 60))m late • still doable")
                        } else {
                            Text("\(Int(hoursLate))h late • still doable")
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.yellow)
                }
                
            case .completed, .missed:
                if !timeUntilWindow.isEmpty {
                    Text(timeUntilWindow)
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.8))
                }
                
            case .upcoming:
                Text(timeUntilWindow)
                    .font(.system(size: 12))
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
                HStack(spacing: 4) {
                    Text("\(consumed)")
                        .font(.system(size: consumed >= 1000 ? 13 : 14, weight: .semibold))
                        .foregroundColor(consumptionColor(consumed: consumed, target: target))
                    Text("/")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(target) cal")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                
                // Show redistribution info if available
                if let reason = redistribution {
                    redistributionText(for: reason)
                        .font(.system(size: 10))
                        .foregroundColor(redistributionColor(for: reason))
                } else {
                    Text("completed")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                
            case .missed(let redistribution):
                Text("\(window.effectiveCalories) cal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                if let reason = redistribution {
                    redistributionText(for: reason)
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.7))
                } else {
                    Text("missed")
                        .font(.system(size: 12))
                        .foregroundColor(.orange.opacity(0.7))
                }
                
            case .lateButDoable:
                Text("\(window.effectiveCalories) cal")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                AnimatedInfoSwitcher(window: window, isActive: false)
                    .frame(width: 120)
                
            case .active:
                Text("\(windowCaloriesRemaining) cal")
                    .font(.system(size: windowCaloriesRemaining >= 1000 ? 14 : 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                
                Text("remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                
            case .upcoming:
                Text("\(window.effectiveCalories) cal")
                    .font(.system(size: window.effectiveCalories >= 1000 ? 12 : 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                
                AnimatedInfoSwitcher(window: window, isActive: false)
                    .frame(width: 120)
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
        let progressValue = min(Double(consumed) / Double(window.effectiveCalories), 1.0)
        
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
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var upcomingIndicator: some View {
        Text("Soon")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white.opacity(0.6))
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
    private var mealsSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            // Show analyzing meals first
            ForEach(analyzingMealsInWindow) { analyzingMeal in
                AnalyzingMealRowCompact(meal: analyzingMeal)
                    .padding(.horizontal, 16)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            
            // Then show logged meals
            ForEach(meals) { meal in
                MealRowCompact(meal: meal)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))  // Ensure opaque background for meals section
    }
    
    private var windowBackground: some View {
        RoundedRectangle(cornerRadius: { if case .active = windowStatus { return 16 } else { return 12 } }())
            .fill(Color.phylloBackground)  // Fully opaque black background first
            .overlay(
                RoundedRectangle(cornerRadius: { if case .active = windowStatus { return 16 } else { return 12 } }())
                    .fill(windowBackgroundColor)
            )
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
                                Color.phylloAccent.opacity(0.6),
                                Color.phylloAccent.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: Color.phylloAccent.opacity(0.3), radius: pulseAnimation ? 8 : 4)
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
            if window.purpose == .postworkout, case .active = windowStatus, meals.isEmpty {
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
        HStack(spacing: 8) {
            // Time
            Text(timeFormatter.string(from: meal.timestamp))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Food emoji
            Text(meal.emoji)
                .font(.system(size: 16))
            
            // Meal info
            VStack(alignment: .leading, spacing: 1) {
                Text(meal.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\(meal.calories) cal")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("\(meal.protein)P")
                        .font(.system(size: 11))
                        .foregroundColor(.orange.opacity(0.7))
                    
                    Text("\(meal.fat)F")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow.opacity(0.7))
                    
                    Text("\(meal.carbs)C")
                        .font(.system(size: 11))
                        .foregroundColor(.blue.opacity(0.7))
                }
                .lineLimit(1)
            }
            
            Spacer()
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
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Loading dots instead of emoji
            HStack(spacing: 3) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.phylloAccent)
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
                .progressViewStyle(CircularProgressViewStyle(tint: .phylloAccent.opacity(0.6)))
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
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 16) {
            if let window = viewModel.activeWindow {
                ExpandableWindowBanner(
                    window: window,
                    meals: viewModel.mealsInWindow(window),
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail,
                    animationNamespace: animationNamespace,
                    viewModel: viewModel
                )
                .padding(.horizontal)
            }
        }
    }
    .onAppear {
        MockDataManager.shared.completeMorningCheckIn()
        MockDataManager.shared.simulateTime(hour: 12)
        MockDataManager.shared.addMockMeal()
        MockDataManager.shared.addMockMeal()
    }
}
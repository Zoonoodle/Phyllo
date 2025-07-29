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
    
    @StateObject private var timeProvider = TimeProvider.shared
    @StateObject private var mockData = MockDataManager.shared
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
        } else if window.isActive {
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
            // Past window, no meals logged
            let timeLate = -timeUntil
            let hours = Int(timeLate) / 3600
            let minutes = (Int(timeLate) % 3600) / 60
            
            if hours > 0 {
                return "\(hours)h \(minutes)m late"
            } else {
                return "\(minutes)m late"
            }
        }
        
        return ""
    }
    
    private var windowProgress: Double {
        guard window.isActive else { return 0 }
        let elapsed = timeProvider.currentTime.timeIntervalSince(window.startTime)
        let total = window.duration
        return min(max(elapsed / total, 0), 1)
    }
    
    private var windowCaloriesRemaining: Int {
        let consumed = mockData.caloriesConsumedInWindow(window)
        return max(0, window.effectiveCalories - consumed)
    }
    
    // Check if it's optimal time to eat (within first 30% of window)
    private var isOptimalTime: Bool {
        guard window.isActive && meals.isEmpty else { return false }
        let elapsed = timeProvider.currentTime.timeIntervalSince(window.startTime)
        let optimalPeriod = window.duration * 0.3 // First 30% of window
        return elapsed <= optimalPeriod
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
            return window.isActive || isStartingSoon
        case .postworkout:
            // Critical window - should eat ASAP after workout
            return window.isActive && meals.isEmpty
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
                
                // Meals section (if any)
                if !meals.isEmpty {
                    mealsSection
                }
            }
            .background(windowBackground)
            .clipShape(RoundedRectangle(cornerRadius: window.isActive ? 16 : 12))
            .overlay(
                RoundedRectangle(cornerRadius: window.isActive ? 16 : 12)
                    .strokeBorder(
                        window.isActive ? window.purpose.color.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: window.isActive ? 2 : 1
                    )
            )
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
        .padding(window.isActive ? 16 : 12)
    }
    
    @ViewBuilder
    private var windowInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: mealIcon)
                    .font(.system(size: window.isActive ? 14 : 12))
                Text(mealType)
                    .font(.system(size: window.isActive ? 14 : 13, weight: .semibold))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundColor(.white)
            
            // Time range display
            Text(formatTimeRange(start: window.startTime, end: window.endTime))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Status text with time remaining for active windows
            if window.isActive {
                HStack(spacing: 4) {
                    if let remaining = window.timeRemaining {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(formatTime(remaining)) left")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundColor(window.timeRemaining ?? 0 < 1800 ? .orange : .white.opacity(0.9))
            } else {
                Text(timeUntilWindow)
                    .font(.system(size: 12))
                    .foregroundColor(getTimeTextColor())
            }
        }
    }
    
    @ViewBuilder
    private var quickStatsSection: some View {
        VStack(alignment: .trailing, spacing: 3) {
            if window.isActive || !meals.isEmpty {
                Text("\(windowCaloriesRemaining) cal")
                    .font(.system(size: windowCaloriesRemaining >= 1000 ? 14 : 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                
                Text("remaining")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                Text("\(window.effectiveCalories) cal")
                    .font(.system(size: window.effectiveCalories >= 1000 ? 12 : 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                
                AnimatedInfoSwitcher(window: window, isActive: window.isActive)
                    .frame(width: 120)
            }
        }
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if window.isActive || !meals.isEmpty {
            progressRing
        } else {
            upcomingLateIndicator
        }
    }
    
    @ViewBuilder
    private var progressRing: some View {
        let consumed = mockData.caloriesConsumedInWindow(window)
        let progressValue = min(Double(consumed) / Double(window.effectiveCalories), 1.0)
        
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(Color.white.opacity(0.1), lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(90))
            
            Circle()
                .trim(from: 0, to: progressValue * 0.76)
                .stroke(
                    window.purpose.color,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
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
    private var upcomingLateIndicator: some View {
        Text(timeUntilWindow.contains("late") ? "Late" : "Soon")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(timeUntilWindow.contains("late") ? .orange : .white.opacity(0.6))
            .frame(width: 40)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
    }
    
    @ViewBuilder
    private var mealsSection: some View {
        VStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)
            
            ForEach(meals) { meal in
                MealRowCompact(meal: meal)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 12)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))  // Ensure opaque background for meals section
    }
    
    private var windowBackground: some View {
        RoundedRectangle(cornerRadius: window.isActive ? 16 : 12)
            .fill(Color.phylloBackground)  // Fully opaque black background first
            .overlay(
                RoundedRectangle(cornerRadius: window.isActive ? 16 : 12)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))  // Dark gray on top
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
                RoundedRectangle(cornerRadius: window.isActive ? 16 : 12)
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
            if isStartingSoon && !window.isActive {
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
            if window.purpose == .postworkout && window.isActive && meals.isEmpty {
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

#Preview {
    @Previewable @State var selectedWindow: MealWindow?
    @Previewable @State var showWindowDetail = false
    @Previewable @Namespace var animationNamespace
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 16) {
            if let window = MockDataManager.shared.activeWindow {
                ExpandableWindowBanner(
                    window: window,
                    meals: MockDataManager.shared.mealsInWindow(window),
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail,
                    animationNamespace: animationNamespace
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
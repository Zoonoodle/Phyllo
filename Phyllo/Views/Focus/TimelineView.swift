//
//  TimelineView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI
import Combine

struct TimelineView: View {
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    @Binding var scrollToAnalyzingMeal: AnalyzingMeal?
    
    @StateObject private var mockData = MockDataManager.shared
    @StateObject private var timeProvider = TimeProvider.shared
    @State private var currentTime = Date()
    @Environment(\.isPreview) private var isPreview
    
    // Animation states
    @State private var animatingMeal: LoggedMeal?
    @State private var animationStartPosition: CGPoint = .zero
    @State private var animationEndPosition: CGPoint = .zero
    @State private var showMealAnimation = false
    
    // Timer to update current time marker (disabled in preview mode)
    var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 60, on: .main, in: isPreview ? .default : .common).autoconnect()
    }
    
    // Define timeline hours (7 AM to 10 PM)
    let hours = Array(7...22)
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(hours, id: \.self) { hour in
                        TimelineHourRow(
                            hour: hour,
                            currentTime: currentTime,
                            windows: mockData.mealWindows,
                            meals: mealsForTimeRange(hour: hour),
                            analyzingMeals: analyzingMealsForTimeRange(hour: hour),
                            isLastHour: hour == hours.last,
                            selectedWindow: $selectedWindow,
                            showWindowDetail: $showWindowDetail,
                            animationNamespace: animationNamespace
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // Extra padding at bottom to prevent clipping
                    Color.clear
                        .frame(height: 100)
                }
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                currentTime = timeProvider.currentTime
                // Scroll to current hour on appear
                withAnimation {
                    proxy.scrollTo(currentHour, anchor: .center)
                }
            }
            .onReceive(timer) { _ in
                if !isPreview {
                    currentTime = timeProvider.currentTime
                }
            }
            .onChange(of: timeProvider.currentTime) { _, newTime in
                if !isPreview {
                    currentTime = newTime
                }
            }
            .onChange(of: scrollToAnalyzingMeal) { _, analyzingMeal in
                if let meal = analyzingMeal {
                    // Calculate which hour the meal is in
                    let targetHour = Calendar.current.component(.hour, from: meal.timestamp)
                    
                    // Scroll to that hour with animation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        proxy.scrollTo(targetHour, anchor: .center)
                    }
                    
                    // Clear the binding after scrolling
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        scrollToAnalyzingMeal = nil
                    }
                }
            }
        }
    }
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }
    
    private func mealsForTimeRange(hour: Int) -> [(meal: LoggedMeal, offset: CGFloat)] {
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: timeProvider.currentTime)!
        let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)!
        
        return mockData.todaysMeals.compactMap { meal in
            if meal.timestamp >= startOfHour && meal.timestamp < endOfHour {
                let minutes = calendar.component(.minute, from: meal.timestamp)
                let offset = CGFloat(minutes) / 60.0 // 0.0 to 1.0 representing position in hour
                return (meal: meal, offset: offset)
            }
            return nil
        }
    }
    
    private func analyzingMealsForTimeRange(hour: Int) -> [(meal: AnalyzingMeal, offset: CGFloat)] {
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: timeProvider.currentTime)!
        let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)!
        
        return mockData.analyzingMeals.compactMap { meal in
            if meal.timestamp >= startOfHour && meal.timestamp < endOfHour {
                let minutes = calendar.component(.minute, from: meal.timestamp)
                let offset = CGFloat(minutes) / 60.0 // 0.0 to 1.0 representing position in hour
                return (meal: meal, offset: offset)
            }
            return nil
        }
    }
    
    // Group meals that are within 30 minutes of each other
    private func groupMeals(_ meals: [(meal: LoggedMeal, offset: CGFloat)]) -> [MealGroup] {
        guard !meals.isEmpty else { return [] }
        
        var groups: [MealGroup] = []
        var currentGroup: [LoggedMeal] = [meals[0].meal]
        var groupOffset = meals[0].offset
        
        for i in 1..<meals.count {
            let previousMeal = meals[i-1].meal
            let currentMeal = meals[i].meal
            let timeDiff = currentMeal.timestamp.timeIntervalSince(previousMeal.timestamp) / 60 // minutes
            
            if timeDiff <= 30 {
                // Add to current group
                currentGroup.append(currentMeal)
            } else {
                // Start new group
                groups.append(MealGroup(meals: currentGroup, offset: groupOffset))
                currentGroup = [currentMeal]
                groupOffset = meals[i].offset
            }
        }
        
        // Add final group
        groups.append(MealGroup(meals: currentGroup, offset: groupOffset))
        
        return groups
    }
    
    struct MealGroup {
        let meals: [LoggedMeal]
        let offset: CGFloat
    }
}

// Timeline hour row with MacroFactors style
struct TimelineHourRow: View {
    let hour: Int
    let currentTime: Date
    let windows: [MealWindow]
    let meals: [(meal: LoggedMeal, offset: CGFloat)]
    let analyzingMeals: [(meal: AnalyzingMeal, offset: CGFloat)]
    let isLastHour: Bool
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    @StateObject private var mockData = MockDataManager.shared
    
    let baseHourHeight: CGFloat = 80
    
    struct MealGroup {
        let meals: [LoggedMeal]
        let offset: CGFloat
    }
    
    var isCurrentHour: Bool {
        Calendar.current.component(.hour, from: currentTime) == hour
    }
    
    var windowForHour: MealWindow? {
        windows.first { window in
            let calendar = Calendar.current
            let startHour = calendar.component(.hour, from: window.startTime)
            // Only show window in the hour where it starts
            return hour == startHour
        }
    }
    
    // Calculate dynamic height based on content
    private var hourHeight: CGFloat {
        // Always return base height - windows extend into next hours naturally
        return baseHourHeight
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Hour label
            TimeLabel(hour: hour)
                .frame(width: 60)
            
            // Main content area
            timelineContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(hour)
    }
    
    @ViewBuilder
    private var timelineContent: some View {
        ZStack(alignment: .topLeading) {
            // Hour divider - only show if there's no window banner overlapping
            if !isLastHour && shouldShowDivider() {
                hourDivider
                    .zIndex(0)
            }
            
            // Window or meals content
            if let window = windowForHour {
                windowContent(for: window)
                    .zIndex(2)
            } else {
                standaloneMealsContent
                    .zIndex(1)
            }
            
            // Current time indicator (only show if window is not active in this hour)
            if isCurrentHour && windowForHour == nil {
                CurrentTimeMarker()
                    .offset(y: getCurrentMinuteOffset())
                    .zIndex(4) // Higher z-index to appear above everything
            }
        }
        .frame(height: hourHeight)
    }
    
    @ViewBuilder
    private var hourDivider: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .clipped()  // Ensure divider doesn't extend beyond bounds
    }
    
    @ViewBuilder
    private func windowContent(for window: MealWindow) -> some View {
        let calendar = Calendar.current
        let startMinute = calendar.component(.minute, from: window.startTime)
        // Use baseHourHeight for consistent positioning
        let windowOffset = CGFloat(startMinute) / 60.0 * baseHourHeight
        let windowMeals = mockData.mealsInWindow(window)
        
        ExpandableWindowBanner(
            window: window,
            meals: windowMeals,
            selectedWindow: $selectedWindow,
            showWindowDetail: $showWindowDetail,
            animationNamespace: animationNamespace
        )
        .offset(y: windowOffset)
        .allowsHitTesting(true)
        .zIndex(10) // Ensure window banners are above everything else
    }
    
    @ViewBuilder
    private var standaloneMealsContent: some View {
        // First, separate meals into indicators and standalone
        let mealCategories = categorizeMeals()
        
        // Show indicators for meals in window banners
        ForEach(mealCategories.indicators, id: \.meal.id) { item in
            MealTimeIndicator(
                meal: item.meal,
                window: item.window,
                onTap: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedWindow = item.window
                        showWindowDetail = true
                    }
                }
            )
            .offset(y: item.offset * hourHeight)
        }
        
        // Show analyzing meals
        ForEach(analyzingMeals, id: \.meal.id) { item in
            AnalyzingMealRow(timestamp: item.meal.timestamp)
                .offset(y: item.offset * hourHeight)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
        }
        
        // Group and show standalone meals
        let groups = groupMeals(mealCategories.standalone)
        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
            if group.meals.count > 1 {
                // Show grouped meals
                GroupedMealsRow(meals: group.meals)
                    .offset(y: group.offset * hourHeight)
            } else if let meal = group.meals.first {
                // Show single meal
                MealRow(meal: meal)
                    .offset(y: group.offset * hourHeight)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
    }
    
    private func categorizeMeals() -> (indicators: [(meal: LoggedMeal, window: MealWindow, offset: CGFloat)], 
                                       standalone: [(meal: LoggedMeal, offset: CGFloat)]) {
        var indicators: [(meal: LoggedMeal, window: MealWindow, offset: CGFloat)] = []
        var standalone: [(meal: LoggedMeal, offset: CGFloat)] = []
        
        for item in meals {
            if let windowId = item.meal.windowId,
               let window = mockData.mealWindows.first(where: { $0.id == windowId }) {
                let windowStartHour = Calendar.current.component(.hour, from: window.startTime)
                
                if windowStartHour == hour || !isMealStandalone(item.meal, window: window) {
                    // Show as indicator if window is in this hour OR meal is close to window
                    indicators.append((meal: item.meal, window: window, offset: item.offset))
                } else {
                    // Show as standalone if far from window
                    standalone.append(item)
                }
            } else {
                // No window assigned
                standalone.append(item)
            }
        }
        
        return (indicators, standalone)
    }
    
    // Check if meal is far enough from window to be considered standalone
    private func isMealStandalone(_ meal: LoggedMeal, window: MealWindow) -> Bool {
        let hoursBefore = window.startTime.timeIntervalSince(meal.timestamp) / 3600
        let hoursAfter = meal.timestamp.timeIntervalSince(window.endTime) / 3600
        
        // Meal is standalone if it's 2+ hours before or after the window
        return hoursBefore >= 2 || hoursAfter >= 2
    }
    
    // Group meals that are within 30 minutes of each other
    private func groupMeals(_ meals: [(meal: LoggedMeal, offset: CGFloat)]) -> [MealGroup] {
        guard !meals.isEmpty else { return [] }
        
        var groups: [MealGroup] = []
        var currentGroup: [LoggedMeal] = [meals[0].meal]
        var groupOffset = meals[0].offset
        
        for i in 1..<meals.count {
            let previousMeal = meals[i-1].meal
            let currentMeal = meals[i].meal
            let timeDiff = currentMeal.timestamp.timeIntervalSince(previousMeal.timestamp) / 60 // minutes
            
            if timeDiff <= 30 {
                // Add to current group
                currentGroup.append(currentMeal)
            } else {
                // Start new group
                groups.append(MealGroup(meals: currentGroup, offset: groupOffset))
                currentGroup = [currentMeal]
                groupOffset = meals[i].offset
            }
        }
        
        // Add final group
        groups.append(MealGroup(meals: currentGroup, offset: groupOffset))
        
        return groups
    }
    
    private func getCurrentMinuteOffset() -> CGFloat {
        let minutes = Calendar.current.component(.minute, from: currentTime)
        return CGFloat(minutes) / 60.0 * hourHeight
    }
    
    // Determine if the hour divider should be shown
    private func shouldShowDivider() -> Bool {
        // Check if there's a window in this hour that starts very early
        if let window = windowForHour {
            let startMinute = Calendar.current.component(.minute, from: window.startTime)
            // Only hide divider if window starts in first 15 minutes
            if startMinute < 15 {
                return false
            }
        }
        
        // Check if a window from the previous hour extends into this hour
        if hour > 0 {
            let previousHour = hour - 1
            if let prevWindow = windows.first(where: { window in
                Calendar.current.component(.hour, from: window.startTime) == previousHour
            }) {
                // If the previous hour's window ends after this hour starts, hide divider
                let thisHourStart = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
                if prevWindow.endTime > thisHourStart {
                    return false
                }
                
                // If window starts very late in previous hour (last 5 minutes), hide this divider
                let prevWindowMinute = Calendar.current.component(.minute, from: prevWindow.startTime)
                if prevWindowMinute >= 55 {
                    return false
                }
            }
        }
        
        // Check if there are meal indicators near the top
        let mealCategories = categorizeMeals()
        for indicator in mealCategories.indicators {
            if indicator.offset < 0.17 { // Within first 10 minutes
                return false
            }
        }
        
        // Check analyzing meals
        for analyzingMeal in analyzingMeals {
            if analyzingMeal.offset < 0.17 {
                return false
            }
        }
        
        return true
    }
}

// Cylindrical hour label like MacroFactors
struct TimeLabel: View {
    let hour: Int
    
    var timeString: String {
        if hour == 12 {
            return "12 PM"
        } else if hour > 12 {
            return "\(hour - 12) PM"
        } else {
            return "\(hour) AM"
        }
    }
    
    var body: some View {
        Text(timeString)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.5))
            .frame(width: 50)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.05))
            )
    }
}


// Meal row matching MacroFactors style
struct MealRow: View {
    let meal: LoggedMeal
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(timeFormatter.string(from: meal.timestamp))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Food emoji
            Text(meal.emoji)
                .font(.system(size: 20))
            
            // Meal info
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text("\(meal.calories) 🔥")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
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
            }
            
            Spacer()
            
            // Expand arrow
            Image(systemName: "chevron.right.2")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.phylloBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
        )
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}

// Add meal pill
struct AddMealPill: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.white.opacity(0.5))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Current time marker
struct CurrentTimeMarker: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.phylloAccent)
                .frame(width: 6, height: 6)
            
            Rectangle()
                .fill(Color.phylloAccent.opacity(0.8))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            
            Text("NOW")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.phylloAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.phylloBackground)
                )
        }
    }
}

// Compact meal time indicator for meals shown in window banners
struct MealTimeIndicator: View {
    let meal: LoggedMeal
    let window: MealWindow
    let onTap: () -> Void
    
    private var isLate: Bool {
        meal.timestamp > window.endTime
    }
    
    private var isEarly: Bool {
        meal.timestamp < window.startTime
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text("🍽️")
                    .font(.system(size: 12))
                
                Text(timeFormatter.string(from: meal.timestamp))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                if isLate || isEarly {
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(isLate ? "LATE" : "EARLY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isLate ? .orange : .blue)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.phylloBackground)
                    .overlay(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                (isLate ? Color.orange : isEarly ? Color.blue : Color.white).opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Grouped meals row for meals within 30 minutes of each other
struct GroupedMealsRow: View {
    let meals: [LoggedMeal]
    @State private var showingModal = false
    
    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    
    private var timeRange: String {
        guard let first = meals.first?.timestamp,
              let last = meals.last?.timestamp else { return "" }
        
        if meals.count == 1 {
            return timeFormatter.string(from: first)
        } else {
            return "\(timeFormatter.string(from: first)) - \(timeFormatter.string(from: last))"
        }
    }
    
    var body: some View {
        Button {
            showingModal = true
        } label: {
            HStack(spacing: 12) {
                // Time range
                Text(timeRange)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 50)
                
                // Multiple food emojis
                HStack(spacing: -8) {
                    ForEach(Array(meals.prefix(3).enumerated()), id: \.offset) { index, meal in
                        Text(meal.emoji)
                            .font(.system(size: 18))
                            .zIndex(Double(3 - index))
                    }
                    if meals.count > 3 {
                        Text("+\(meals.count - 3)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 4)
                    }
                }
                
                // Group info
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(meals.count) meals")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("\(totalCalories) cal total")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Expand indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.phylloBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingModal) {
            GroupedMealsModal(meals: meals)
        }
    }
}

// Modal view for grouped meals details
struct GroupedMealsModal: View {
    let meals: [LoggedMeal]
    @Environment(\.dismiss) private var dismiss
    
    private var totalNutrition: (calories: Int, protein: Int, carbs: Int, fat: Int) {
        meals.reduce((0, 0, 0, 0)) { result, meal in
            (result.0 + meal.calories,
             result.1 + meal.protein,
             result.2 + meal.carbs,
             result.3 + meal.fat)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Total nutrition summary
                    VStack(spacing: 12) {
                        Text("\(totalNutrition.calories) cal")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            MacroLabel(value: totalNutrition.protein, label: "Protein", color: .orange)
                            MacroLabel(value: totalNutrition.carbs, label: "Carbs", color: .blue)
                            MacroLabel(value: totalNutrition.fat, label: "Fat", color: .yellow)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                    
                    // Individual meals
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(meals) { meal in
                                MealDetailRow(meal: meal)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Meal Group Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.phylloAccent)
                }
            }
        }
    }
}

// Macro label component for modal
struct MacroLabel: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// Detailed meal row for modal
struct MealDetailRow: View {
    let meal: LoggedMeal
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(meal.emoji)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(timeFormatter.string(from: meal.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("\(meal.calories) cal")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack(spacing: 12) {
                    Text("\(meal.protein)g P")
                        .font(.system(size: 11))
                        .foregroundColor(.orange.opacity(0.7))
                    
                    Text("\(meal.carbs)g C")
                        .font(.system(size: 11))
                        .foregroundColor(.blue.opacity(0.7))
                    
                    Text("\(meal.fat)g F")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// Meal row with window indicator for meals logged outside their window
struct MealRowWithWindowIndicator: View {
    let meal: LoggedMeal
    let window: MealWindow
    
    private var windowName: String {
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
    
    var body: some View {
        VStack(spacing: 8) {
            // Window indicator
            HStack(spacing: 4) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 10))
                Text("Assigned to \(windowName)")
                    .font(.system(size: 11))
                Spacer()
            }
            .foregroundColor(window.purpose.color.opacity(0.8))
            .padding(.leading, 35)
            
            // Regular meal row
            MealRow(meal: meal)
        }
    }
}

#Preview {
    @Previewable @State var selectedWindow: MealWindow?
    @Previewable @State var showWindowDetail = false
    @Previewable @State var scrollToAnalyzingMeal: AnalyzingMeal?
    @Previewable @Namespace var animationNamespace
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        TimelineView(
            selectedWindow: $selectedWindow,
            showWindowDetail: $showWindowDetail,
            animationNamespace: animationNamespace,
            scrollToAnalyzingMeal: $scrollToAnalyzingMeal
        )
    }
    .onAppear {
        let mockData = MockDataManager.shared
        mockData.completeMorningCheckIn()
        mockData.simulateTime(hour: 14)
        
        // Add mock meals at specific times
        let calendar = Calendar.current
        let today = TimeProvider.shared.currentTime
        mockData.addMockMeal(
            name: "Homemade Plain Waffles",
            calories: 82,
            protein: 2,
            carbs: 9,
            fat: 4,
            at: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!
        )
        mockData.addMockMeal(
            name: "Strawberries, Fresh",
            calories: 6,
            protein: 0,
            carbs: 1,
            fat: 0,
            at: calendar.date(bySettingHour: 8, minute: 10, second: 0, of: today)!
        )
        mockData.addMockMeal(
            name: "Egg Fried",
            calories: 196,
            protein: 14,
            carbs: 1,
            fat: 15,
            at: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: today)!
        )
        mockData.addMockMeal(
            name: "Cucumber, Raw, Without Peel",
            calories: 28,
            protein: 2,
            carbs: 6,
            fat: 0,
            at: calendar.date(bySettingHour: 10, minute: 15, second: 0, of: today)!
        )
        
        // Test nearest window assignment - meal logged 1 hour after lunch window
        mockData.addMockMeal(
            name: "Late Afternoon Snack",
            calories: 350,
            protein: 15,
            carbs: 40,
            fat: 12,
            at: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!
        )
    }
}
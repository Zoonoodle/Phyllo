//
//  TimelineView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI
import Combine

// Helper struct for scroll offset tracking
struct ScrollViewOffsetData: Equatable {
    let offset: CGFloat
    let isScrolling: Bool
}

// MARK: - Static Windows Render Layer (non-draggable)
private struct WindowsRenderLayer: View {
    let windowLayouts: [TimelineLayoutManager.WindowLayout]
    let animationNamespace: Namespace.ID
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(windowLayouts, id: \.window.id) { layout in
                ExpandableWindowBanner(
                    window: layout.window,
                    meals: viewModel.mealsInWindow(layout.window),
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail,
                    animationNamespace: animationNamespace,
                    viewModel: viewModel,
                    bannerHeight: layout.height
                )
                .offset(y: layout.yPosition)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: layout.yPosition)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: layout.height)
            }
        }
    }
}
struct TimelineView: View {
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    @Binding var scrollToAnalyzingMeal: AnalyzingMeal?
    @ObservedObject var viewModel: ScheduleViewModel
    
    @StateObject private var timeProvider = TimeProvider.shared
    @StateObject private var layoutManager = TimelineLayoutManager()
    @State private var currentTime = Date()
    @Environment(\.isPreview) private var isPreview
    
    // Animation states
    @State private var animatingMeal: LoggedMeal?
    @State private var animationStartPosition: CGPoint = .zero
    @State private var animationEndPosition: CGPoint = .zero
    @State private var showMealAnimation = false

    // Drag state for window interaction
    @State private var draggingWindowId: UUID?
    @State private var dragAccumulatedOffset: CGFloat = 0
    @State private var initialWindowTimes: (start: Date, end: Date)?
    
    // Auto-scroll state
    @State private var lastScrolledHour: Int?
    @State private var userIsScrolling = false
    @State private var scrollEndWorkItem: DispatchWorkItem?
    
    // Timer to update current time marker with smooth movement (every 10 seconds for performance)
    var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        Timer.publish(every: 10, on: .main, in: isPreview ? .default : .common).autoconnect()
    }
    
    // Dynamic timeline hours from ViewModel
    var hours: [Int] {
        viewModel.timelineHours
    }
    // Base height for one hour on the vertical timeline
    private let baseHourHeight: CGFloat = 60 // Matching layout manager
    
    var body: some View {
        if viewModel.mealWindows.isEmpty && viewModel.morningCheckIn == nil {
            NoWindowsView()
        } else {
            ScrollViewReader { proxy in
                buildTimeline(proxy: proxy)
            }
            .overlay(alignment: .topLeading) {
                if showMealAnimation, let meal = animatingMeal {
                    MealRow(meal: meal)
                        .padding(.horizontal, 24)
                        .position(showMealAnimation ? animationEndPosition : animationStartPosition)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0), value: showMealAnimation)
                }
            }
            .onChange(of: viewModel.mealWindows.count) { _, _ in
                updateLayouts()
            }
            .onChange(of: viewModel.todaysMeals.count) { _, _ in
                updateLayouts()
            }
            .onChange(of: viewModel.analyzingMeals.count) { _, _ in
                updateLayouts()
            }
            .onChange(of: viewModel.morningCheckIn) { _, _ in
                updateLayouts()
            }
            .onAppear {
                updateLayouts()
            }
        }
    }
    
    // Update layouts when data changes
    private func updateLayouts() {
        let layouts = layoutManager.calculateLayouts(
            for: viewModel.mealWindows,
            hours: hours,
            viewModel: viewModel
        )
        
        // Store layouts for use in view building
        calculatedHourLayouts = layouts.hours
        calculatedWindowLayouts = layouts.windows
    }
    
    @State private var calculatedHourLayouts: [TimelineLayoutManager.HourLayout] = []
    @State private var calculatedWindowLayouts: [TimelineLayoutManager.WindowLayout] = []
    @State private var lastActiveWindowId: UUID?

    @ViewBuilder
    private func buildTimeline(proxy: ScrollViewProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                // Background hour grid with clean lines
                VStack(spacing: 0) {
                    ForEach(calculatedHourLayouts, id: \.hour) { hourLayout in
                        VStack(spacing: 0) {
                            // Hour divider line at the top
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 1)
                                .padding(.leading, 68) // Start after time label (8 + 48 + 12)
                                .padding(.trailing, 24)
                            
                            TimelineHourRow(
                                hour: hourLayout.hour,
                                currentTime: currentTime,
                                windows: viewModel.mealWindows,
                                meals: mealsForTimeRange(hour: hourLayout.hour),
                                analyzingMeals: analyzingMealsForTimeRange(hour: hourLayout.hour),
                                isLastHour: hourLayout.hour == hours.last,
                                hourHeight: hourLayout.height,
                                selectedWindow: $selectedWindow,
                                showWindowDetail: $showWindowDetail,
                                animationNamespace: animationNamespace,
                                viewModel: viewModel
                            )
                        }
                        .frame(height: hourLayout.height)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: hourLayout.height)
                        .id("hour-\(hourLayout.hour)")
                    }
                    Color.clear.frame(height: 100)
                }
                .frame(maxWidth: .infinity)

                // Windows overlay layer using calculated layouts
                WindowsRenderLayer(
                    windowLayouts: calculatedWindowLayouts,
                    animationNamespace: animationNamespace,
                    viewModel: viewModel,
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail
                )
                // Align with the start of the timeline content (leave gutter for time labels)
                .padding(EdgeInsets(top: 0, leading: 68, bottom: 0, trailing: 24))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: calculateTotalLayoutHeight() + 100,
                    alignment: .topLeading
                )
                .allowsHitTesting(true)
                // Keep current time marker above banners
                .zIndex(3)
            }
        }
        .onAppear {
            currentTime = timeProvider.currentTime
            // Scroll to first window or first hour
            let targetHour: Int
            if let firstWindow = viewModel.mealWindows.first {
                targetHour = Calendar.current.component(.hour, from: firstWindow.startTime)
            } else if let firstHour = hours.first {
                targetHour = firstHour
            } else {
                targetHour = currentHour
            }
            withAnimation {
                proxy.scrollTo("hour-\(targetHour)", anchor: .top)
            }
        }
        .onReceive(timer) { _ in
            if !isPreview {
                currentTime = timeProvider.currentTime
                handleAutoScroll(proxy: proxy)
                
                // Check if active window changed
                let currentActiveWindowId = viewModel.activeWindow?.id
                if currentActiveWindowId != lastActiveWindowId {
                    lastActiveWindowId = currentActiveWindowId
                    updateLayouts()
                }
            }
        }
        .onReceive(timeProvider.$simulatedTime) { newSimulatedTime in
            if newSimulatedTime != nil && !isPreview {
                currentTime = timeProvider.currentTime
                handleAutoScroll(proxy: proxy)
            }
        }
        .onScrollGeometryChange(for: ScrollViewOffsetData.self) { geometry in
            ScrollViewOffsetData(
                offset: geometry.contentOffset.y,
                isScrolling: geometry.contentOffset.y != geometry.contentInsets.top
            )
        } action: { _, data in
            if data.isScrolling {
                userIsScrolling = true
                scrollEndWorkItem?.cancel()
                let work = DispatchWorkItem {
                    userIsScrolling = false
                }
                scrollEndWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
            }
        }
        .onChange(of: scrollToAnalyzingMeal) { _, analyzingMeal in
            if let meal = analyzingMeal {
                let targetHour = Calendar.current.component(.hour, from: meal.timestamp)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    proxy.scrollTo("hour-\(targetHour)", anchor: .center)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    scrollToAnalyzingMeal = nil
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .animateMealToWindow)) { notification in
            if let meal = notification.object as? LoggedMeal {
                handleMealSlideAnimation(meal: meal, proxy: proxy)
            }
        }
    }
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: currentTime)
    }
    
    // Calculate total layout height from calculated layouts
    private func calculateTotalLayoutHeight() -> CGFloat {
        calculatedHourLayouts.reduce(0) { total, hourLayout in
            total + hourLayout.height
        }
    }
    
    // Handle auto-scrolling to keep NOW indicator visible with magnetic snapping
    private func handleAutoScroll(proxy: ScrollViewProxy) {
        let hour = currentHour
        
        // Check for magnetic snap points (meal window boundaries)
        let snapPoint = getMagneticSnapPoint()
        
        // Only scroll if:
        // 1. Hour has changed or we're near a snap point
        // 2. User is not actively scrolling
        // 3. Current hour is within timeline bounds
        if (hour != lastScrolledHour || snapPoint != nil) && !userIsScrolling && hours.contains(hour) {
            lastScrolledHour = hour
            
            // Determine scroll target
            let scrollTarget: Int
            let anchor: UnitPoint
            
            if let snap = snapPoint {
                // Snap to important time
                scrollTarget = snap.hour
                anchor = snap.anchor
            } else {
                // Normal hour centering
                scrollTarget = hour
                anchor = .center
            }
            
            // Smooth scroll with spring animation for magnetic feel
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                proxy.scrollTo("hour-\(scrollTarget)", anchor: anchor)
            }
        }
    }
    
    // Calculate magnetic snap points near meal windows
    private func getMagneticSnapPoint() -> (hour: Int, anchor: UnitPoint)? {
        let snapThreshold: TimeInterval = 5 * 60 // 5 minutes
        let calendar = Calendar.current
        
        // Check all meal windows for nearby start/end times
        for window in viewModel.mealWindows {
            // Check window start
            let startDiff = abs(window.startTime.timeIntervalSince(currentTime))
            if startDiff <= snapThreshold {
                let hour = calendar.component(.hour, from: window.startTime)
                let minute = calendar.component(.minute, from: window.startTime)
                let anchor = UnitPoint(x: 0.5, y: Double(minute) / 60.0)
                return (hour, anchor)
            }
            
            // Check window end
            let endDiff = abs(window.endTime.timeIntervalSince(currentTime))
            if endDiff <= snapThreshold {
                let hour = calendar.component(.hour, from: window.endTime)
                let minute = calendar.component(.minute, from: window.endTime)
                let anchor = UnitPoint(x: 0.5, y: Double(minute) / 60.0)
                return (hour, anchor)
            }
        }
        
        return nil
    }
    
    private func mealsForTimeRange(hour: Int) -> [(meal: LoggedMeal, offset: CGFloat)] {
        let calendar = Calendar.current
        let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: timeProvider.currentTime)!
        let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)!
        
        // Debug logging for meal lookup - removed verbose window details
        
        return viewModel.todaysMeals.compactMap { meal in
            // Check if meal belongs to a window in this hour
            if let windowId = meal.windowId,
               let window = viewModel.mealWindows.first(where: { $0.id == windowId }) {
                // Align meal vertically relative to the window span
                let windowStartHour = calendar.component(.hour, from: window.startTime)
                if windowStartHour == hour {
                    let total = max(window.endTime.timeIntervalSince(window.startTime), 1)
                    let delta = meal.timestamp.timeIntervalSince(window.startTime)
                    let ratio = CGFloat(min(max(delta / total, 0), 1))
                    return (meal: meal, offset: ratio)
                }
                return nil
            } else if let windowId = meal.windowId {
                // Meal has window ID but window not found
                DebugLogger.shared.warning("Meal \(meal.name) has window ID \(windowId) but window NOT FOUND in viewModel.mealWindows")
            }
            
            // Fallback: show meals without windows based on timestamp
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
        
        return viewModel.analyzingMeals.compactMap { meal in
            if meal.timestamp >= startOfHour && meal.timestamp < endOfHour {
                // Show as standalone only when outside assigned window time
                if let windowId = meal.windowId,
                   let window = viewModel.mealWindows.first(where: { $0.id == windowId }) {
                    if meal.timestamp < window.startTime || meal.timestamp > window.endTime {
                        let minutes = calendar.component(.minute, from: meal.timestamp)
                        let offset = CGFloat(minutes) / 60.0
                        return (meal: meal, offset: offset)
                    } else {
                        return nil
                    }
                } else {
                    let minutes = calendar.component(.minute, from: meal.timestamp)
                    let offset = CGFloat(minutes) / 60.0
                    return (meal: meal, offset: offset)
                }
            }
            return nil
        }
    }
    
    private func handleMealSlideAnimation(meal: LoggedMeal, proxy: ScrollViewProxy) {
        guard let window = viewModel.mealWindows.first(where: { window in
            meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
        }) else {
            // Meal not in any window, trigger celebration without animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let metadata = MealCaptureService.shared.getAnalysisMetadata(for: meal.id)
                NudgeManager.shared.triggerNudge(.mealLoggedCelebration(meal: meal, metadata: metadata))
            }
            return
        }
        
        // Calculate positions
        let mealHour = Calendar.current.component(.hour, from: meal.timestamp)
        let mealMinute = Calendar.current.component(.minute, from: meal.timestamp)
        let windowHour = Calendar.current.component(.hour, from: window.startTime)
        
        // Scroll to window if needed
        if abs(mealHour - windowHour) > 2 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                proxy.scrollTo("hour-\(windowHour)", anchor: .center)
            }
        }
        
        // Calculate animation positions
        let hourHeight: CGFloat = 120
        let startYOffset = CGFloat(mealMinute) / 60.0 * hourHeight
        let startY = CGFloat(mealHour - 7) * hourHeight + startYOffset + 60
        
        let windowMinute = Calendar.current.component(.minute, from: window.startTime)
        let endYOffset = CGFloat(windowMinute) / 60.0 * hourHeight
        let endY = CGFloat(windowHour - 7) * hourHeight + endYOffset + 60
        
        animatingMeal = meal
        animationStartPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: startY)
        animationEndPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: endY)
        
        // Start animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showMealAnimation = true
            
            // Hide animation and trigger celebration after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showMealAnimation = false
                animatingMeal = nil
                
                // Trigger meal celebration nudge
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let metadata = MealCaptureService.shared.getAnalysisMetadata(for: meal.id)
                    NudgeManager.shared.triggerNudge(.mealLoggedCelebration(meal: meal, metadata: metadata))
                }
            }
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
    
}

// Timeline hour row with MacroFactors style
struct TimelineHourRow: View {
    let hour: Int
    let currentTime: Date
    let windows: [MealWindow]
    let meals: [(meal: LoggedMeal, offset: CGFloat)]
    let analyzingMeals: [(meal: AnalyzingMeal, offset: CGFloat)]
    let isLastHour: Bool
    let hourHeight: CGFloat
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    @ObservedObject var viewModel: ScheduleViewModel
    
    
    var isCurrentHour: Bool {
        Calendar.current.component(.hour, from: currentTime) == hour
    }
    
    // Deprecated: window banners are now drawn in overlay. Keep for divider heuristics if needed.
    var windowForHour: MealWindow? {
        windows.first { window in
            let calendar = Calendar.current
            let startHour = calendar.component(.hour, from: window.startTime)
            return hour == startHour
        }
    }
    
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Hour label - fixed position
            TimeLabel(hour: hour, isCurrent: isCurrentHour)
                .frame(width: 48)
                .padding(.leading, 8) // Small left padding
                .zIndex(10) // Ensure time labels always sit above everything
            
            // Main content area
            timelineContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 24) // Keep right padding for content
        }
    }
    
    @ViewBuilder
    private var timelineContent: some View {
        ZStack(alignment: .topLeading) {
            // Show only standalone/analyzing meals here; windows are drawn in overlay layer
            standaloneMealsContent
                .zIndex(1)

            // Current time indicator with context awareness
            if isCurrentHour {
                let currentWindowInfo = getCurrentWindowInfo()
                CurrentTimeMarker(
                    currentTime: currentTime,
                    isInsideWindow: currentWindowInfo.isInside,
                    windowPurpose: currentWindowInfo.purpose
                )
                .offset(y: getCurrentMinuteOffset())
                .animation(.linear(duration: 10), value: getCurrentMinuteOffset())
                .zIndex(4)
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
    private func windowContent(for window: MealWindow) -> some View { EmptyView() }
    
    @ViewBuilder
    private var standaloneMealsContent: some View {
        // Only show analyzing meals - all logged meals should appear in their windows
        ForEach(analyzingMeals, id: \.meal.id) { item in
            AnalyzingMealRow(timestamp: item.meal.timestamp, metadata: nil)
                .offset(y: item.offset * hourHeight)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }
    
    
    private func getCurrentMinuteOffset() -> CGFloat {
        let minutes = Calendar.current.component(.minute, from: currentTime)
        return CGFloat(minutes) / 60.0 * hourHeight
    }
    
    // Get current window context for the NOW indicator
    private func getCurrentWindowInfo() -> (isInside: Bool, purpose: WindowPurpose?) {
        // Check all windows to see if current time is inside any
        for window in windows {
            if currentTime >= window.startTime && currentTime <= window.endTime {
                return (true, window.purpose)
            }
        }
        return (false, nil)
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
        
        
        // Check analyzing meals
        for analyzingMeal in analyzingMeals {
            if analyzingMeal.offset < 0.17 {
                return false
            }
        }
        
        return true
    }
}

// Clean hour label inspired by Google Calendar
struct TimeLabel: View {
    let hour: Int
    var isCurrent: Bool = false
    
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
            .font(.system(size: 12, weight: .regular))
            .monospacedDigit()
            .foregroundColor(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .offset(y: -8) // Offset up to align with hour line
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
                .monospacedDigit()
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
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(meal.protein)P")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(.orange.opacity(0.7))
                    Text("\(meal.fat)F")
                        .font(.system(size: 11))
                        .monospacedDigit()
                        .foregroundColor(.yellow.opacity(0.7))
                    Text("\(meal.carbs)C")
                        .font(.system(size: 11))
                        .monospacedDigit()
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

// Enhanced current time marker with premium features
struct CurrentTimeMarker: View {
    let currentTime: Date
    let isInsideWindow: Bool
    let windowPurpose: WindowPurpose?
    @State private var pulseAnimation = false
    
    // Initialize with default values for backward compatibility
    init(currentTime: Date = Date(), isInsideWindow: Bool = false, windowPurpose: WindowPurpose? = nil) {
        self.currentTime = currentTime
        self.isInsideWindow = isInsideWindow
        self.windowPurpose = windowPurpose
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var markerColor: Color {
        if isInsideWindow, let purpose = windowPurpose {
            return purpose.color
        }
        return .phylloAccent
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Pulsing dot with depth
            ZStack {
                // Glow effect
                Circle()
                    .fill(markerColor.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .blur(radius: 4)
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                
                // Main dot with shadow
                Circle()
                    .fill(markerColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: markerColor.opacity(0.6), radius: 3, x: 0, y: 2)
            }
            
            // Timeline with gradient fade
            LinearGradient(
                colors: [
                    markerColor,
                    markerColor.opacity(0.6),
                    markerColor.opacity(0.3),
                    markerColor.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .shadow(color: markerColor.opacity(0.4), radius: 2, x: 0, y: 1)
            
            // Time text inline with the line
            TimeFloat(
                time: timeFormatter.string(from: currentTime),
                color: markerColor,
                isInsideWindow: isInsideWindow
            )
        }
        // Keep marker flat for better scroll performance
        .onAppear {
            pulseAnimation = true
        }
    }
}

// Floating time badge component
struct TimeFloat: View {
    let time: String
    let color: Color
    let isInsideWindow: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if isInsideWindow {
                Image(systemName: "fork.knife")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(color)
            }
            
            Text(time)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.white)
        }
        .padding(.leading, 8)
    }
}

// Small floating action that jumps the scroll back to the current hour
struct JumpToNowButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "location.north.line.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("Now")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }
}







#Preview {
    @Previewable @State var selectedWindow: MealWindow?
    @Previewable @State var showWindowDetail = false
    @Previewable @State var scrollToAnalyzingMeal: AnalyzingMeal?
    @Previewable @Namespace var animationNamespace
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        TimelineView(
            selectedWindow: $selectedWindow,
            showWindowDetail: $showWindowDetail,
            animationNamespace: animationNamespace,
            scrollToAnalyzingMeal: $scrollToAnalyzingMeal,
            viewModel: viewModel
        )
    }
}
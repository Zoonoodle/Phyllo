//
//  TimelineLayoutManager.swift
//  NutriSync
//
//  Created on 8/11/25.
//

import SwiftUI

/// Manages the dynamic layout of the timeline, calculating hour heights and window positions
@MainActor
class TimelineLayoutManager: ObservableObject {
    
    // MARK: - Types
    
    struct HourLayout {
        let hour: Int
        let height: CGFloat
        let yOffset: CGFloat
        let hasActiveWindow: Bool
        let windowsInHour: [MealWindow]
    }
    
    struct WindowLayout {
        let window: MealWindow
        let yPosition: CGFloat
        let height: CGFloat
        let contentHeight: CGFloat // Height needed for content
    }
    
    // MARK: - Constants
    
    let baseHourHeight: CGFloat = 80 // Base height for hours with content
    let minHourHeight: CGFloat = 30 // Minimum height for empty hours (compressed)
    let mealCardHeight: CGFloat = 50 // Height per meal card
    let emptyHourCompression: CGFloat = 0.2 // Compression factor for empty regions (80% space preserved)
    let minimumWindowSpacing: CGFloat = 12 // Ensure windows don't overlap with hour markers
    let windowPadding: CGFloat = 12
    
    // MARK: - Properties
    
    @Published var hourLayouts: [HourLayout] = []
    @Published var windowLayouts: [WindowLayout] = []
    
    // MARK: - Public Methods
    
    /// Calculate all layouts for the given windows and timeline hours
    func calculateLayouts(
        for windows: [MealWindow],
        hours: [Int],
        viewModel: ScheduleViewModel
    ) -> (hours: [HourLayout], windows: [WindowLayout]) {
        
        // Step 1: Determine which windows affect each hour
        var windowsByHour: [Int: [MealWindow]] = [:]
        
        for window in windows {
            let affectedHours = hoursAffectedBy(window: window)
            for hour in affectedHours {
                windowsByHour[hour, default: []].append(window)
            }
        }
        
        // Step 2: Calculate hour heights based on windows
        var calculatedHours: [HourLayout] = []
        var currentYOffset: CGFloat = 0
        
        // One-time debug for hour layout calculation
        if !windows.isEmpty && !hours.isEmpty {
            Task { @MainActor in
                DebugLogger.shared.error("🔍 HOUR LAYOUTS DEBUG")
                DebugLogger.shared.error("  Building layouts for hours: \(hours)")
            }
        }
        
        for hour in hours {
            let windowsInThisHour = windowsByHour[hour] ?? []
            let height = calculateHourHeight(
                hour: hour,
                windows: windowsInThisHour,
                allWindows: windows,
                viewModel: viewModel
            )
            
            let hasActiveWindow = windowsInThisHour.contains { $0.isActive }
            
            let hourLayout = HourLayout(
                hour: hour,
                height: height,
                yOffset: currentYOffset,
                hasActiveWindow: hasActiveWindow,
                windowsInHour: windowsInThisHour
            )
            
            // Debug first few hour layouts
            if hour <= 6 && !windows.isEmpty {
                Task { @MainActor in
                    DebugLogger.shared.error("  Hour \(hour): yOffset=\(currentYOffset), height=\(height)")
                }
            }
            
            calculatedHours.append(hourLayout)
            currentYOffset += height
        }
        
        // Step 3: Calculate window positions
        var calculatedWindows: [WindowLayout] = []
        
        for window in windows {
            let layout = calculateWindowLayout(
                window: window,
                hourLayouts: calculatedHours,
                viewModel: viewModel
            )
            calculatedWindows.append(layout)
        }
        
        // Step 4: Adjust for overlapping windows
        calculatedWindows = adjustForOverlaps(calculatedWindows)
        
        return (calculatedHours, calculatedWindows)
    }
    
    // MARK: - Private Methods
    
    private func hoursAffectedBy(window: MealWindow) -> [Int] {
        // CRITICAL: Use local calendar with proper timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        let startHour = calendar.component(.hour, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        
        // Debug logging removed - was causing infinite loops
        
        if startHour == endHour {
            return [startHour]
        } else if startHour < endHour {
            // Normal case: window doesn't cross midnight
            return Array(startHour...endHour)
        } else {
            // Window crosses midnight
            return Array(startHour...23) + Array(0...endHour)
        }
    }
    
    private func calculateHourHeight(
        hour: Int,
        windows: [MealWindow],
        allWindows: [MealWindow],
        viewModel: ScheduleViewModel
    ) -> CGFloat {
        
        // Check if hour is empty (no windows, no meals)
        let isEmpty = windows.isEmpty && !hasContentInHour(hour: hour, viewModel: viewModel)
        
        // Apply compression for empty hours - preserve 80% of base height
        if isEmpty {
            return baseHourHeight * 0.8 // 80% of base height (64px) for empty hours
        }
        
        // For hours with windows, calculate based on content
        var maxContentNeeded: CGFloat = 0
        
        // Check all windows that affect this hour
        for window in windows {
            // Count meals in this window
            let mealCount = viewModel.mealsInWindow(window).count
            let analyzingCount = viewModel.analyzingMeals.filter { $0.windowId?.uuidString == window.id }.count
            let totalMealCards = mealCount + analyzingCount
            
            // If window has meals, calculate space needed
            if totalMealCards > 0 || window.isActive {
                // Calculate content height needed
                var contentHeight: CGFloat = 0
                
                // Add space for each meal card
                if totalMealCards > 0 {
                    contentHeight += CGFloat(totalMealCards) * mealCardHeight
                    contentHeight += windowPadding * 2 // Top and bottom padding
                    contentHeight += 15 // Extra spacing to prevent overlap with hour markers
                }
                
                // Don't add extra space for active window insights when empty
                // The insights are rendered inside the banner itself, not as extra height
                // The banner should only be sized based on its time duration
                
                // Calculate what portion of window falls in this hour
                let calendar = Calendar.current
                let windowStartHour = calendar.component(.hour, from: window.startTime)
                let windowEndHour = calendar.component(.hour, from: window.endTime)
                
                // How many hours does this window span?
                let hoursSpanned = windowEndHour >= windowStartHour ? 
                    (windowEndHour - windowStartHour + 1) : 
                    (24 - windowStartHour + windowEndHour + 1)
                
                // Distribute content height across all hours the window spans
                let heightPerHour = contentHeight / CGFloat(hoursSpanned)
                
                // This hour needs at least this much space
                maxContentNeeded = max(maxContentNeeded, heightPerHour)
            }
        }
        
        // Return the greater of base height or content-driven height
        // Add buffer to prevent cramping and overlap with hour markers
        let calculatedHeight = max(baseHourHeight, maxContentNeeded + 35)
        
        // Cap at a reasonable maximum to prevent excessive stretching
        return min(calculatedHeight, baseHourHeight * 2.5)
    }
    
    private func calculateWindowExpansion(
        window: MealWindow,
        viewModel: ScheduleViewModel
    ) -> CGFloat {
        
        let analyzingMeals = viewModel.analyzingMeals.filter { $0.windowId?.uuidString == window.id }
        let mealCount = viewModel.mealsInWindow(window).count
        let analyzingCount = analyzingMeals.count
        let totalCards = mealCount + analyzingCount
        
        // Start with minimal base height
        var contentHeight: CGFloat = 60 // Window header
        
        // Don't add space for window insights section here
        // The insights are rendered inside the banner and should not affect timeline height
        // The banner height should be based purely on time duration
        
        // Add space for meal cards (both logged and analyzing)
        if totalCards > 0 {
            // Each meal card needs its height plus some spacing
            let mealSectionHeight = CGFloat(totalCards) * mealCardHeight + 20
            contentHeight += mealSectionHeight
        }
        
        // Add padding
        contentHeight += windowPadding * 2
        
        return contentHeight
    }
    
    private func calculateWindowLayout(
        window: MealWindow,
        hourLayouts: [HourLayout],
        viewModel: ScheduleViewModel
    ) -> WindowLayout {
        
        // CRITICAL: Use local calendar with proper timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current // Ensure we're using local timezone
        
        // Convert UTC dates to local timezone for hour extraction
        let startHour = calendar.component(.hour, from: window.startTime)
        let startMinute = calendar.component(.minute, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        let endMinute = calendar.component(.minute, from: window.endTime)
        
        // Find the hour layout for the start hour
        guard let startHourLayout = hourLayouts.first(where: { $0.hour == startHour }) else {
            // Debug missing hour layout
            if window.id == windowLayouts.first?.window.id {
                Task { @MainActor in
                    DebugLogger.shared.error("⚠️ NO HOUR LAYOUT for hour \(startHour)")
                    DebugLogger.shared.error("  Available hour layouts: \(hourLayouts.map { $0.hour })")
                }
            }
            return WindowLayout(
                window: window,
                yPosition: 0,
                height: baseHourHeight,
                contentHeight: baseHourHeight
            )
        }
        
        // Calculate Y position (hour offset + minute offset within hour)
        let minuteFraction = CGFloat(startMinute) / 60.0
        let yPosition = startHourLayout.yOffset + (minuteFraction * startHourLayout.height)
        
        // One-time debug for first window position calculation
        if window.id == windowLayouts.first?.window.id {
            Task { @MainActor in
                DebugLogger.shared.error("🔍 WINDOW POSITION DEBUG")
                DebugLogger.shared.error("  Window: \(window.name)")
                DebugLogger.shared.error("  Start time: \(window.startTime)")
                DebugLogger.shared.error("  Extracted hour: \(startHour), minute: \(startMinute)")
                DebugLogger.shared.error("  Hour layout found at index: \(hourLayouts.firstIndex(where: { $0.hour == startHour }) ?? -1)")
                DebugLogger.shared.error("  Hour layout yOffset: \(startHourLayout.yOffset)")
                DebugLogger.shared.error("  Hour layout height: \(startHourLayout.height)")
                DebugLogger.shared.error("  Minute fraction: \(minuteFraction)")
                DebugLogger.shared.error("  Final yPosition: \(yPosition)")
            }
        }
        
        // Calculate window height based on actual time span in the timeline
        var timeBasedHeight: CGFloat = 0
        
        if startHour == endHour {
            // Window within single hour
            let duration = CGFloat(endMinute - startMinute) / 60.0
            timeBasedHeight = duration * startHourLayout.height
        } else {
            // Window spans multiple hours
            
            // Remaining time in start hour
            timeBasedHeight += (1.0 - minuteFraction) * startHourLayout.height
            
            // Full hours in between
            for hourLayout in hourLayouts {
                if hourLayout.hour > startHour && hourLayout.hour < endHour {
                    timeBasedHeight += hourLayout.height
                }
            }
            
            // Time in end hour
            if let endHourLayout = hourLayouts.first(where: { $0.hour == endHour }) {
                let endMinuteFraction = CGFloat(endMinute) / 60.0
                timeBasedHeight += endMinuteFraction * endHourLayout.height
            }
        }
        
        // Calculate content height needed
        let contentHeight = calculateWindowExpansion(window: window, viewModel: viewModel)
        
        // The final height should be the time-based height, not the content height
        // The hour heights have already been adjusted to accommodate the content
        let finalHeight = timeBasedHeight
        return WindowLayout(
            window: window,
            yPosition: yPosition,
            height: finalHeight,
            contentHeight: contentHeight
        )
    }
    
    private func adjustForOverlaps(_ layouts: [WindowLayout]) -> [WindowLayout] {
        // If there are 0 or 1 windows, no adjustments needed
        guard layouts.count > 1 else {
            return layouts
        }
        
        var adjusted = layouts
        
        // Sort by Y position
     
        
        // Check for overlaps and adjust
        for i in 1..<adjusted.count {
            let previous = adjusted[i-1]
            let current = adjusted[i]
            
            let previousBottom = previous.yPosition + previous.height
            let requiredSpacing = minimumWindowSpacing
            
            if current.yPosition < previousBottom + requiredSpacing {
                // Overlap detected - adjust current window position
                let newYPosition = previousBottom + requiredSpacing
                adjusted[i] = WindowLayout(
                    window: current.window,
                    yPosition: newYPosition,
                    height: current.height,
                    contentHeight: current.contentHeight
                )
            }
        }
        
        return adjusted
    }
    
    // MARK: - Helper Methods
    
    /// Check if a specific hour has any content (meals, analyzing meals, or windows)
    private func hasContentInHour(hour: Int, viewModel: ScheduleViewModel) -> Bool {
        let calendar = Calendar.current
        
        // Check for any windows in this hour (already checked by caller usually)
        for window in viewModel.mealWindows {
            let startHour = calendar.component(.hour, from: window.startTime)
            let endHour = calendar.component(.hour, from: window.endTime)
            
            // Check if this hour falls within the window
            if startHour <= endHour {
                if hour >= startHour && hour <= endHour {
                    return true
                }
            } else {
                // Window crosses midnight
                if hour >= startHour || hour <= endHour {
                    return true
                }
            }
        }
        
        // Check for meals in this hour
        for meal in viewModel.todaysMeals {
            let mealHour = calendar.component(.hour, from: meal.timestamp)
            if mealHour == hour {
                return true
            }
        }
        
        // Check for analyzing meals in this hour
        for analyzingMeal in viewModel.analyzingMeals {
            let mealHour = calendar.component(.hour, from: analyzingMeal.timestamp)
            if mealHour == hour {
                return true
            }
        }
        
        return false
    }
}

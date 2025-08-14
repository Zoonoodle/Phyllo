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
    
    let baseHourHeight: CGFloat = 60 // Reduced for cleaner look
    let minimumWindowSpacing: CGFloat = 8 // Tighter spacing like Google Calendar
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
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        
        if startHour == endHour {
            return [startHour]
        } else {
            return Array(startHour...endHour)
        }
    }
    
    private func calculateHourHeight(
        hour: Int,
        windows: [MealWindow],
        allWindows: [MealWindow],
        viewModel: ScheduleViewModel
    ) -> CGFloat {
        
        // Start with base height as minimum
        var requiredHeight = baseHourHeight
        
        // Check all windows that affect this hour
        for window in windows {
            let calendar = Calendar.current
            let windowStartHour = calendar.component(.hour, from: window.startTime)
            let windowEndHour = calendar.component(.hour, from: window.endTime)
            let windowStartMinute = calendar.component(.minute, from: window.startTime)
            let windowEndMinute = calendar.component(.minute, from: window.endTime)
            
            // Calculate total content height needed for this window
            let windowContentHeight = calculateWindowExpansion(window: window, viewModel: viewModel)
            
            // Calculate how much of this window's time falls within this hour
            let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: window.startTime)!
            let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart)!
            
            // Find the overlap between window and hour
            let overlapStart = max(window.startTime, hourStart)
            let overlapEnd = min(window.endTime, hourEnd)
            
            if overlapEnd > overlapStart {
                // There is an overlap
                let overlapDuration = overlapEnd.timeIntervalSince(overlapStart)
                let windowDuration = window.endTime.timeIntervalSince(window.startTime)
                
                // Calculate what fraction of the window's time is in this hour
                let fractionInHour = overlapDuration / windowDuration
                
                // Calculate the height needed for this fraction of the window
                // We need to ensure the content fits proportionally
                if fractionInHour > 0 {
                    // The hour needs to be tall enough that the window's portion fits
                    let hourFractionOfContent = windowContentHeight * fractionInHour
                    
                    // Calculate what the full hour height should be
                    // If the window takes up X% of the hour's time, it should take up X% of the hour's height
                    let hourFraction = overlapDuration / 3600.0 // How much of the hour this window uses
                    
                    if hourFraction > 0 {
                        let neededHourHeight = hourFractionOfContent / hourFraction
                        
                        // For active empty windows, limit expansion to prevent visual overflow
                        if window.isActive && viewModel.mealsInWindow(window).isEmpty {
                            neededHourHeight = min(neededHourHeight, baseHourHeight * 2.5)
                        }
                        
                        requiredHeight = max(requiredHeight, neededHourHeight)
                    }
                }
            }
        }
        
        // Ensure reasonable bounds - allow more expansion for content-heavy hours
        return min(max(requiredHeight, baseHourHeight), baseHourHeight * 6)
    }
    
    private func calculateWindowExpansion(
        window: MealWindow,
        viewModel: ScheduleViewModel
    ) -> CGFloat {
        
        let hasAnalyzingMeals = viewModel.analyzingMeals.contains { $0.windowId == window.id }
        let mealCount = viewModel.mealsInWindow(window).count
        let hasMeals = mealCount > 0
        
        // Start with minimal base height
        var contentHeight: CGFloat = 40 // Just for header
        
        // Add space for window insights section based on state
        if window.isActive {
            if hasMeals || hasAnalyzingMeals {
                // Active with meals - just show the meals
                contentHeight += 10 // Small buffer
            } else {
                // Active but empty - needs space for insights and suggestions
                // Now that insights are always shown, we need proper space
                contentHeight += 60 // Insights text, macros, suggestions
            }
        }
        
        // Add space for meals
        if hasMeals || hasAnalyzingMeals {
            let mealSectionHeight = 10 + CGFloat(max(mealCount, hasAnalyzingMeals ? 1 : 0)) * 40
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
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: window.startTime)
        let startMinute = calendar.component(.minute, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        let endMinute = calendar.component(.minute, from: window.endTime)
        
        // Find the hour layout for the start hour
        guard let startHourLayout = hourLayouts.first(where: { $0.hour == startHour }) else {
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
        
        // Use content height to ensure all content is visible
        // The hour heights have been adjusted to accommodate this
        let finalHeight = contentHeight
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
}

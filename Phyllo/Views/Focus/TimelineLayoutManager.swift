//
//  TimelineLayoutManager.swift
//  Phyllo
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
            
            // Calculate how much height this window needs
            let windowContentHeight = calculateWindowExpansion(window: window, viewModel: viewModel)
            
            // Determine how this window affects this specific hour
            if windowStartHour == hour && windowEndHour == hour {
                // Window is entirely within this hour
                let startFraction = CGFloat(windowStartMinute) / 60.0
                let endFraction = CGFloat(windowEndMinute) / 60.0
                let windowDuration = endFraction - startFraction
                
                // The window needs at least its content height
                // Calculate what hour height would be needed to fit this window
                let neededHourHeight = windowContentHeight / max(windowDuration, 0.1)
                requiredHeight = max(requiredHeight, neededHourHeight)
                
            } else if windowStartHour == hour {
                // Window starts in this hour but extends beyond
                let startFraction = CGFloat(windowStartMinute) / 60.0
                let remainingFraction = 1.0 - startFraction
                
                // Calculate proportional height needed in this hour
                if windowEndHour > hour {
                    // Multi-hour window - distribute height proportionally
                    let totalHours = CGFloat(windowEndHour - windowStartHour) + 
                                   (CGFloat(windowEndMinute) / 60.0) - 
                                   (CGFloat(windowStartMinute) / 60.0)
                    let thisHourPortion = remainingFraction / max(totalHours, 0.1)
                    let neededHeight = (windowContentHeight * thisHourPortion) / remainingFraction
                    requiredHeight = max(requiredHeight, neededHeight)
                } else {
                    // Window fits within hour time-wise but may need more space
                    let neededHeight = windowContentHeight / remainingFraction
                    requiredHeight = max(requiredHeight, neededHeight)
                }
                
            } else if windowEndHour == hour && windowStartHour < hour {
                // Window ends in this hour but started earlier
                let endFraction = CGFloat(windowEndMinute) / 60.0
                
                // This hour only needs to accommodate the ending portion
                // The window's main height is handled by its starting hour
                // Just ensure minimum space
                requiredHeight = max(requiredHeight, baseHourHeight)
            }
        }
        
        // Ensure reasonable bounds
        return min(max(requiredHeight, baseHourHeight), baseHourHeight * 8)
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
                contentHeight += 60 // Insights text, purpose, suggestions
                
                // Add space for remaining macros (only for longer windows)
                if window.duration > 5400 { // > 1.5 hours
                    contentHeight += 40
                }
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
        
        // Calculate window height based on time span
        var windowHeight: CGFloat = 0
        
        if startHour == endHour {
            // Window within single hour
            let duration = CGFloat(endMinute - startMinute) / 60.0
            windowHeight = duration * startHourLayout.height
        } else {
            // Window spans multiple hours
            
            // Remaining time in start hour
            windowHeight += (1.0 - minuteFraction) * startHourLayout.height
            
            // Full hours in between
            for hourLayout in hourLayouts {
                if hourLayout.hour > startHour && hourLayout.hour < endHour {
                    windowHeight += hourLayout.height
                }
            }
            
            // Time in end hour
            if let endHourLayout = hourLayouts.first(where: { $0.hour == endHour }) {
                let endMinuteFraction = CGFloat(endMinute) / 60.0
                windowHeight += endMinuteFraction * endHourLayout.height
            }
        }
        
        // Calculate content height needed
        let contentHeight = calculateWindowExpansion(window: window, viewModel: viewModel)
        
        // Use the larger of time-based height or content height
        let finalHeight = max(windowHeight, contentHeight)
        
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

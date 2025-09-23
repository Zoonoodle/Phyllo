//
//  TimelineLayoutCalculator.swift
//  NutriSync
//
//  Created on 8/27/25.
//

import SwiftUI

// MARK: - Timeline Layout Calculator
class TimelineLayoutCalculator: ObservableObject {
    
    // MARK: - Configuration
    struct LayoutConfig {
        let minHourHeight: CGFloat = 40      // Minimum height for empty hours
        let baseHourHeight: CGFloat = 80     // Standard hour height
        let mealCardHeight: CGFloat = 45     // Height per meal card
        let windowHeaderHeight: CGFloat = 60 // Height for window header content
        let windowPadding: CGFloat = 12      // Padding within windows
        let minWindowSpacing: CGFloat = 8    // Minimum spacing between windows
        let emptyHourCompression: CGFloat = 0.8  // 80% space preserved for empty hours
    }
    
    // MARK: - Hour Block Info
    struct HourBlock {
        let hour: Int
        let displayHour: String
        var height: CGFloat
        var hasContent: Bool
        var mealCount: Int
        var analyzingCount: Int
        var windowsInHour: [MealWindow]
        var isActiveHour: Bool
    }
    
    // MARK: - Properties
    private let config = LayoutConfig()
    @Published var hourBlocks: [HourBlock] = []
    @Published var totalHeight: CGFloat = 0
    
    // MARK: - Public Methods
    
    /// Calculate the dynamic layout for the timeline based on content
    func calculateLayout(
        windows: [MealWindow],
        meals: [UUID: [LoggedMeal]],
        analyzingMeals: [AnalyzingMeal],
        checkIn: MorningCheckInData?,
        currentTime: Date = Date()
    ) -> [HourBlock] {
        
        let calendar = Calendar.current
        
        // Determine timeline range based on wake/sleep times
        let wakeTime = checkIn?.wakeTime ?? calendar.date(bySettingHour: 7, minute: 0, second: 0, of: currentTime)!
        let bedtime = checkIn?.plannedBedtime ?? calendar.date(bySettingHour: 22, minute: 30, second: 0, of: currentTime)!
        
        // Calculate start and end hours (1 hour before wake time to bedtime)
        let startHour = max(0, calendar.component(.hour, from: wakeTime) - 1)
        let endHour = min(23, calendar.component(.hour, from: bedtime))
        
        // Initialize hour blocks
        var blocks: [HourBlock] = []
        
        for hour in startHour...endHour {
            let hourString = formatHour(hour)
            
            // Find windows that overlap this hour
            let windowsInThisHour = windows.filter { window in
                doesWindowOverlapHour(window: window, hour: hour)
            }
            
            // Count meals in this hour across all windows
            var totalMealsInHour = 0
            var totalAnalyzingInHour = 0
            
            for window in windowsInThisHour {
                // Count logged meals
                if let windowId = UUID(uuidString: window.id),
                   let windowMeals = meals[windowId] {
                    totalMealsInHour += windowMeals.count
                }
                
                // Count analyzing meals
                let analyzingInWindow = analyzingMeals.filter { meal in
                    // Check if meal is assigned to this window or falls within it
                    meal.windowId?.uuidString == window.id || 
                    (meal.timestamp >= window.startTime && meal.timestamp <= window.endTime)
                }
                totalAnalyzingInHour += analyzingInWindow.count
            }
            
            // Check if this is the current active hour
            let isActive = calendar.component(.hour, from: currentTime) == hour
            
            // Calculate height for this hour
            let hasContent = !windowsInThisHour.isEmpty || totalMealsInHour > 0 || totalAnalyzingInHour > 0
            let height = calculateHourHeight(
                hasContent: hasContent,
                windowCount: windowsInThisHour.count,
                mealCount: totalMealsInHour,
                analyzingCount: totalAnalyzingInHour,
                isActiveHour: isActive
            )
            
            blocks.append(HourBlock(
                hour: hour,
                displayHour: hourString,
                height: height,
                hasContent: hasContent,
                mealCount: totalMealsInHour,
                analyzingCount: totalAnalyzingInHour,
                windowsInHour: windowsInThisHour,
                isActiveHour: isActive
            ))
        }
        
        // Apply compression to consecutive empty hours
        blocks = applyEmptyHourCompression(blocks)
        
        // Calculate total height
        let total = blocks.reduce(0) { $0 + $1.height }
        
        // Update published properties
        DispatchQueue.main.async {
            self.hourBlocks = blocks
            self.totalHeight = total
        }
        
        return blocks
    }
    
    /// Get the Y offset for a specific time within the timeline
    func getYOffset(for date: Date, in blocks: [HourBlock]) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        var offset: CGFloat = 0
        
        for block in blocks {
            if block.hour < hour {
                offset += block.height
            } else if block.hour == hour {
                // Add proportional offset within the hour
                let minuteFraction = CGFloat(minute) / 60.0
                offset += block.height * minuteFraction
                break
            } else {
                break
            }
        }
        
        return offset
    }
    
    // MARK: - Private Methods
    
    private func formatHour(_ hour: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return "\(displayHour) \(period)"
    }
    
    private func doesWindowOverlapHour(window: MealWindow, hour: Int) -> Bool {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        
        // Handle windows that don't cross midnight
        if startHour <= endHour {
            return hour >= startHour && hour <= endHour
        } else {
            // Window crosses midnight
            return hour >= startHour || hour <= endHour
        }
    }
    
    private func calculateHourHeight(
        hasContent: Bool,
        windowCount: Int,
        mealCount: Int,
        analyzingCount: Int,
        isActiveHour: Bool
    ) -> CGFloat {
        
        // Start with base height
        var height = config.baseHourHeight
        
        // If no content and not active, apply compression
        if !hasContent && !isActiveHour {
            return config.minHourHeight
        }
        
        // Add height for meal cards (both logged and analyzing)
        let totalCards = mealCount + analyzingCount
        if totalCards > 0 {
            height += CGFloat(totalCards) * config.mealCardHeight
            height += config.windowPadding * 2  // Top and bottom padding
        }
        
        // Add extra height if window header is present
        if windowCount > 0 {
            height += config.windowHeaderHeight
        }
        
        // Add spacing between multiple windows in same hour
        if windowCount > 1 {
            height += config.minWindowSpacing * CGFloat(windowCount - 1)
        }
        
        // Active hour gets a bit more space for better visibility
        if isActiveHour {
            height *= 1.1
        }
        
        return max(height, config.minHourHeight)
    }
    
    private func applyEmptyHourCompression(_ blocks: [HourBlock]) -> [HourBlock] {
        var compressedBlocks = blocks
        var i = 0
        
        while i < compressedBlocks.count {
            // Find consecutive empty hours
            var j = i
            while j < compressedBlocks.count && !compressedBlocks[j].hasContent && !compressedBlocks[j].isActiveHour {
                j += 1
            }
            
            // If we found 2+ consecutive empty hours, compress them
            let emptyCount = j - i
            if emptyCount >= 2 {
                for k in i..<j {
                    compressedBlocks[k].height *= config.emptyHourCompression
                }
            }
            
            i = max(j, i + 1)
        }
        
        return compressedBlocks
    }
    
    /// Calculate the required height for a window banner based on its content
    func calculateWindowBannerHeight(
        window: MealWindow,
        mealCount: Int,
        analyzingCount: Int
    ) -> CGFloat {
        
        // Calculate based on window duration and content
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        let hourSpan = endHour >= startHour ? endHour - startHour + 1 : (24 - startHour + endHour + 1)
        
        // Base height from hour span
        var height = CGFloat(hourSpan) * config.baseHourHeight
        
        // Add height for content
        let totalCards = mealCount + analyzingCount
        if totalCards > 0 {
            height = max(height, config.windowHeaderHeight + (CGFloat(totalCards) * config.mealCardHeight) + config.windowPadding * 2)
        }
        
        return height
    }
}
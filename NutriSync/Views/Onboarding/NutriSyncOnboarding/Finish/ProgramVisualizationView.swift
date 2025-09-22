//
//  ProgramVisualizationView.swift
//  NutriSync
//
//  Weekly timeline and macro visualization for onboarding completion
//

import SwiftUI

struct ProgramVisualizationView: View {
    let viewModel: OnboardingCompletionViewModel
    @State private var selectedDay = 0
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Personalized Program")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Daily targets optimized for your goals")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    // Weekly Targets with Daily Variations
                    if let macros = viewModel.macroTargets {
                        WeeklyTargetsView(
                            baseCalories: macros.calories,
                            baseMacros: macros,
                            goal: viewModel.userGoal ?? "maintain"
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Average Daily Targets Summary
                    if let macros = viewModel.macroTargets {
                        VStack(spacing: 16) {
                            Text("Average Daily Targets")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            MacroTargetGrid(macros: macros)
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Simplified Eating Window
                    if let firstDay = viewModel.weeklyWindows.first,
                       let firstWindow = firstDay.windows.first,
                       let lastWindow = firstDay.windows.last {
                        
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.nutriSyncAccent)
                                    .font(.system(size: 20))
                                Text("Daily Eating Schedule")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(formatTime(firstWindow.startTime)) - \(formatTime(lastWindow.endTime))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.nutriSyncAccent)
                                
                                Text("\(firstDay.windows.count) meals within a \(calculateWindowHours(from: firstWindow.startTime, to: lastWindow.endTime))-hour window")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                // Meal timing dots
                                HStack(spacing: 4) {
                                    ForEach(0..<firstDay.windows.count, id: \.self) { index in
                                        Circle()
                                            .fill(Color.nutriSyncAccent)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                    
                    // Swipe hint
                    Text("Swipe to continue")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func calculateWindowHours(from start: Date, to end: Date) -> Int {
        let hours = Calendar.current.dateComponents([.hour], from: start, to: end).hour ?? 0
        return max(hours, 1)
    }
}

// MARK: - Weekly Timeline View
struct WeeklyTimelineView: View {
    let windows: [DayWindows]
    
    var body: some View {
        VStack(spacing: 8) {
            // Days of week
            ForEach(Array(windows.enumerated()), id: \.offset) { index, dayWindow in
                HStack(spacing: 8) {
                    // Day label
                    Text(String(dayWindow.dayName.prefix(3)))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 35)
                    
                    // Timeline for the day
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track (24 hours)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 32)
                            
                            // Sleep periods (dark overlay)
                            HStack(spacing: 0) {
                                // Night sleep (before wake)
                                if let firstWindow = dayWindow.windows.first {
                                    let sleepEndRatio = timeToRatio(firstWindow.startTime)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: geometry.size.width * sleepEndRatio, height: 32)
                                }
                                
                                Spacer()
                                
                                // Evening sleep (after last meal + 3 hours)
                                if let lastWindow = dayWindow.windows.last {
                                    let sleepStartTime = Calendar.current.date(byAdding: .hour, value: 3, to: lastWindow.endTime) ?? lastWindow.endTime
                                    let sleepStartRatio = timeToRatio(sleepStartTime)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.purple.opacity(0.2))
                                        .frame(width: geometry.size.width * (1 - sleepStartRatio), height: 32)
                                        .offset(x: geometry.size.width * sleepStartRatio)
                                }
                            }
                            
                            // Meal windows
                            ForEach(dayWindow.windows, id: \.id) { window in
                                let startRatio = timeToRatio(window.startTime)
                                let duration = timeToRatio(window.endTime) - startRatio
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.nutriSyncAccent)
                                    .frame(width: max(geometry.size.width * duration, 20), height: 24)
                                    .offset(x: geometry.size.width * startRatio)
                            }
                        }
                    }
                    .frame(height: 32)
                }
            }
            
            // Time scale
            HStack {
                Text("") // Align with day labels
                    .frame(width: 35)
                
                HStack {
                    ForEach([6, 12, 18, 24], id: \.self) { hour in
                        Text("\(hour == 24 ? 0 : hour)")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        if hour != 24 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func timeToRatio(_ date: Date) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
        return CGFloat(totalMinutes / 1440.0) // 24 hours = 1440 minutes
    }
}

// MARK: - Macro Target Grid
struct MacroTargetGrid: View {
    let macros: OnboardingMacroTargets
    
    var body: some View {
        HStack(spacing: 16) {
            // Calories
            MacroCard(
                value: "\(macros.calories)",
                label: "cal",
                color: Color.nutriSyncAccent,
                isLarge: true
            )
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    // Protein
                    MacroCard(
                        value: "\(macros.protein)g",
                        label: "protein",
                        color: Color.orange.opacity(0.8)
                    )
                    
                    // Carbs
                    MacroCard(
                        value: "\(macros.carbs)g",
                        label: "carbs",
                        color: Color.blue.opacity(0.8)
                    )
                }
                
                HStack(spacing: 16) {
                    // Fat
                    MacroCard(
                        value: "\(macros.fat)g",
                        label: "fat",
                        color: Color.yellow.opacity(0.8)
                    )
                    
                    // Percentages
                    VStack(spacing: 4) {
                        Text("P: \(macros.proteinPercentage)%")
                        Text("C: \(macros.carbPercentage)%")
                        Text("F: \(macros.fatPercentage)%")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Macro Card Component
struct MacroCard: View {
    let value: String
    let label: String
    let color: Color
    var isLarge: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: isLarge ? 32 : 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.lowercase)
        }
        .frame(width: isLarge ? 120 : 80, height: isLarge ? 120 : 52)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
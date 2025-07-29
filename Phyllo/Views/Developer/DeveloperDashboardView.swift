//
//  DeveloperDashboardView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct DeveloperDashboardView: View {
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedTab = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            DashboardTab(title: "Goals", icon: "target", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            DashboardTab(title: "Mock Meals", icon: "fork.knife", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            DashboardTab(title: "Time Control", icon: "clock", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            DashboardTab(title: "Profile", icon: "person.fill", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                            DashboardTab(title: "Data Viewer", icon: "doc.text", isSelected: selectedTab == 4) {
                                selectedTab = 4
                            }
                            DashboardTab(title: "Nudges", icon: "bell.badge", isSelected: selectedTab == 5) {
                                selectedTab = 5
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    
                    // Tab Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case 0:
                                GoalsTabView()
                            case 1:
                                MockMealsTabView()
                            case 2:
                                TimeControlTabView()
                            case 3:
                                ProfileTabView()
                            case 4:
                                DataViewerTabView()
                            case 5:
                                NudgesDebugTabView()
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Developer Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.phylloAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Tab Button Component
struct DashboardTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .phylloAccent : .white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.phylloAccent.opacity(0.2) : Color.clear)
            .cornerRadius(12)
        }
    }
}

// MARK: - Goals Tab
struct GoalsTabView: View {
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Primary Goal
            VStack(alignment: .leading, spacing: 12) {
                Text("Primary Goal")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(NutritionGoal.defaultExamples, id: \.id) { goal in
                    GoalSelectionRow(
                        goal: goal,
                        isSelected: mockData.userProfile.primaryGoal.id == goal.id
                    ) {
                        mockData.setPrimaryGoal(goal)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Secondary Goals
            VStack(alignment: .leading, spacing: 12) {
                Text("Secondary Goals")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(NutritionGoal.defaultExamples, id: \.id) { goal in
                    GoalSelectionRow(
                        goal: goal,
                        isSelected: mockData.userGoals.contains(where: { $0.id == goal.id })
                    ) {
                        if mockData.userGoals.contains(where: { $0.id == goal.id }) {
                            mockData.removeSecondaryGoal(goal)
                        } else {
                            mockData.addSecondaryGoal(goal)
                        }
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
        }
    }
}

struct GoalSelectionRow: View {
    let goal: NutritionGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: goal.icon)
                    .font(.system(size: 20))
                    .foregroundColor(goal.color)
                    .frame(width: 30)
                
                Text(goal.displayName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.phylloAccent)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Mock Meals Tab
struct MockMealsTabView: View {
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Quick Actions
            VStack(spacing: 12) {
                Button(action: {
                    mockData.addMockMeal()
                }) {
                    Label("Add Random Meal", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.phylloAccent)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    mockData.clearAllMeals()
                }) {
                    Label("Clear All Meals", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Start analyzing meal and navigate to timeline
                    let analyzingMeal = mockData.startAnalyzingMeal()
                    NotificationCenter.default.post(
                        name: .switchToTimelineWithScroll,
                        object: analyzingMeal
                    )
                    
                    // Simulate completion after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        let result = analyzingMeal.toLoggedMeal(
                            name: "Test Analyzed Meal",
                            calories: 400,
                            protein: 30,
                            carbs: 40,
                            fat: 15
                        )
                        mockData.completeAnalyzingMeal(analyzingMeal, with: result)
                    }
                }) {
                    Label("Test Analyzing Meal", systemImage: "waveform")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            // Current Meals
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Meals")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(mockData.todaysMeals.count) meals")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if mockData.todaysMeals.isEmpty {
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(mockData.todaysMeals) { meal in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(meal.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("\(meal.calories) cal • P: \(meal.protein)g • C: \(meal.carbs)g • F: \(meal.fat)g")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text(meal.timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.phylloSurface)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Nutrition Summary
            VStack(spacing: 8) {
                HStack {
                    Text("Calories:")
                    Spacer()
                    Text("\(mockData.todaysCaloriesConsumed)")
                }
                HStack {
                    Text("Protein:")
                    Spacer()
                    Text("\(mockData.todaysProteinConsumed)g")
                }
                HStack {
                    Text("Carbs:")
                    Spacer()
                    Text("\(mockData.todaysCarbsConsumed)g")
                }
                HStack {
                    Text("Fat:")
                    Spacer()
                    Text("\(mockData.todaysFatConsumed)g")
                }
            }
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.8))
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Time Control Tab
struct TimeControlTabView: View {
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedHour = 12
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Time Display
            VStack(spacing: 8) {
                Text("Simulated Time")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(mockData.currentSimulatedTime, formatter: timeFormatter)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.phylloAccent)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Time Picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Set Time")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24) { hour in
                        Text("\(hour):00")
                            .tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 150)
                
                Button(action: {
                    mockData.simulateTime(hour: selectedHour)
                }) {
                    Text("Set Time")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.phylloAccent)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Quick Time Buttons
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Jump")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    TimeButton(label: "Morning", hour: 7) {
                        mockData.simulateDayProgress(hour: 7)
                    }
                    TimeButton(label: "Noon", hour: 12) {
                        mockData.simulateDayProgress(hour: 12)
                    }
                    TimeButton(label: "Afternoon", hour: 15) {
                        mockData.simulateDayProgress(hour: 15)
                    }
                    TimeButton(label: "Evening", hour: 19) {
                        mockData.simulateDayProgress(hour: 19)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Day Controls
            HStack(spacing: 12) {
                Button(action: {
                    mockData.resetDay()
                }) {
                    Label("New Day", systemImage: "sunrise.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    mockData.completeMorningCheckIn()
                }) {
                    Label("Complete Check-In", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.phylloAccent)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .short
        return formatter
    }
}

struct TimeButton: View {
    let label: String
    let hour: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                Text("\(hour):00")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.phylloSurface)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}

// MARK: - Profile Tab
struct ProfileTabView: View {
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Activity Level
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Level")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button(action: {
                        mockData.updateActivityLevel(level)
                    }) {
                        HStack {
                            Text(level.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            if mockData.userProfile.activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.phylloAccent)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Work Schedule
            VStack(alignment: .leading, spacing: 12) {
                Text("Work Schedule")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(WorkSchedule.allCases, id: \.self) { schedule in
                    Button(action: {
                        mockData.updateWorkSchedule(schedule)
                    }) {
                        HStack {
                            Text(schedule.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            if mockData.userProfile.workSchedule == schedule {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.phylloAccent)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Meal Preferences
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferred Meal Count")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    ForEach(3...6, id: \.self) { count in
                        Button(action: {
                            mockData.updateMealCount(count)
                        }) {
                            Text("\(count)")
                                .font(.system(size: 16, weight: .medium))
                                .frame(width: 50, height: 50)
                                .background(mockData.userProfile.preferredMealCount == count ? Color.phylloAccent : Color.phylloSurface)
                                .foregroundColor(mockData.userProfile.preferredMealCount == count ? .black : .white)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Fasting Protocol
            VStack(alignment: .leading, spacing: 12) {
                Text("Fasting Protocol")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ForEach(FastingProtocol.allCases, id: \.self) { fasting in
                    Button(action: {
                        mockData.updateFastingProtocol(fasting)
                    }) {
                        HStack {
                            Text(fasting.rawValue)
                                .foregroundColor(.white)
                            Spacer()
                            if mockData.userProfile.intermittentFastingPreference == fasting {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.phylloAccent)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Button(action: {
                    mockData.updateFastingProtocol(nil)
                }) {
                    HStack {
                        Text("No Fasting")
                            .foregroundColor(.white)
                        Spacer()
                        if mockData.userProfile.intermittentFastingPreference == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.phylloAccent)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
        }
    }
}

// MARK: - Data Viewer Tab
struct DataViewerTabView: View {
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Current State
            VStack(alignment: .leading, spacing: 12) {
                Text("Current State")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Group {
                    DataRow(label: "Primary Goal", value: mockData.userProfile.primaryGoal.displayName)
                    DataRow(label: "Secondary Goals", value: "\(mockData.userGoals.count)")
                    DataRow(label: "Meal Windows", value: "\(mockData.mealWindows.count)")
                    DataRow(label: "Windows Remaining", value: "\(mockData.windowsRemaining)")
                    DataRow(label: "Active Window", value: mockData.activeWindow?.purpose.rawValue ?? "None")
                    DataRow(label: "Meals Logged", value: "\(mockData.todaysMeals.count)")
                    DataRow(label: "Morning Check-In", value: mockData.morningCheckIn != nil ? "Complete" : "Pending")
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Windows
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Windows")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if mockData.mealWindows.isEmpty {
                    Text("No windows generated")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    ForEach(mockData.mealWindows) { window in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: window.purpose.icon)
                                    .foregroundColor(window.purpose.color)
                                Text(window.purpose.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                if window.isActive {
                                    Text("ACTIVE")
                                        .font(.caption)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.phylloAccent)
                                        .cornerRadius(4)
                                }
                            }
                            Text(window.formattedTimeRange)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text("\(window.targetCalories) cal • P: \(window.targetMacros.protein)g • C: \(window.targetMacros.carbs)g • F: \(window.targetMacros.fat)g")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.phylloSurface)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Reset Button
            Button(action: {
                mockData.resetToDefaults()
            }) {
                Label("Reset All Data", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
    }
}

struct DataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Nudges Debug Tab
struct NudgesDebugTabView: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Current Nudge State
            VStack(alignment: .leading, spacing: 12) {
                Text("Current State")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Active Nudge")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(nudgeManager.activeNudge?.id ?? "None")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Queued Nudges")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(nudgeManager.queuedNudges.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Dismissed Nudges")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(nudgeManager.dismissedNudges.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Trigger Nudges
            VStack(alignment: .leading, spacing: 12) {
                Text("Trigger Nudges")
                    .font(.headline)
                    .foregroundColor(.white)
                VStack(spacing: 12) {
                    // Tutorial
                    Button(action: {
                        nudgeManager.triggerTestNudge(.firstTimeTutorial(page: 1))
                    }) {
                        Label("Start Tutorial", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.phylloAccent)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    
                    // Morning Check-In
                    Button(action: {
                        mockData.morningCheckIn = nil
                        nudgeManager.triggerTestNudge(.morningCheckIn)
                    }) {
                        Label("Morning Check-In", systemImage: "sun.max.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    
                    // Meal Celebration
                    Button(action: {
                        let testMeal = LoggedMeal(
                            name: "Test Meal",
                            calories: 450,
                            protein: 30,
                            carbs: 45,
                            fat: 15,
                            timestamp: Date()
                        )
                        nudgeManager.triggerTestNudge(.mealLoggedCelebration(meal: testMeal))
                    }) {
                        Label("Meal Celebration", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    
                    // Active Window
                    Button(action: {
                        if let window = mockData.mealWindows.first(where: { $0.isActive }) {
                            nudgeManager.triggerTestNudge(.activeWindowReminder(window: window, timeRemaining: 45))
                        }
                    }) {
                        Label("Active Window Reminder", systemImage: "clock.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    // Missed Window
                    Button(action: {
                        if let window = mockData.mealWindows.first(where: { $0.isPast }) {
                            nudgeManager.triggerTestNudge(.missedWindow(window: window))
                        }
                    }) {
                        Label("Missed Window", systemImage: "exclamationmark.triangle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
            
            // Reset Functions
            VStack(alignment: .leading, spacing: 12) {
                Text("Reset Functions")
                    .font(.headline)
                    .foregroundColor(.white)
                VStack(spacing: 12) {
                    Button(action: {
                        nudgeManager.resetAllNudges()
                    }) {
                        Label("Reset All Nudges", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.phylloSurface)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        UserDefaults.standard.removeObject(forKey: "lastMorningNudgeDate")
                    }) {
                        Label("Reset Onboarding", systemImage: "person.crop.circle.badge.xmark")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.phylloSurface)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.phylloElevated)
            .cornerRadius(16)
        }
    }
}

#Preview {
    DeveloperDashboardView()
}
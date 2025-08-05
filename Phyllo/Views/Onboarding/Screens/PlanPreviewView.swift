//
//  PlanPreviewView.swift
//  Phyllo
//
//  Preview of personalized meal plan
//

import SwiftUI

struct PlanPreviewView: View {
    let data: OnboardingData
    @State private var animateIn = false
    @State private var selectedWindow: MealWindow?
    
    // Generate sample meal windows based on user data
    var sampleWindows: [MealWindow] {
        guard let wakeTime = data.wakeTime,
              let sleepTime = data.sleepTime else { return [] }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Calculate windows based on preferences
        let mealCount = data.preferredMealCount
        let hasWorkout = !data.workoutDays.isEmpty
        
        var windows: [MealWindow] = []
        
        // Calculate eating window based on fasting protocol
        let eatingWindowHours: Int
        switch data.fastingProtocol {
        case .sixteen8: eatingWindowHours = 8
        case .eighteen6: eatingWindowHours = 6
        case .twenty4: eatingWindowHours = 4
        case .omad: eatingWindowHours = 2
        case .custom, .none: eatingWindowHours = 14
        }
        
        // First meal time (considering fasting)
        let firstMealHour = calendar.component(.hour, from: wakeTime) + (data.fastingProtocol != nil ? 2 : 1)
        let lastMealHour = calendar.component(.hour, from: sleepTime) - 3
        
        // Create windows
        if mealCount >= 3 {
            // Breakfast window
            windows.append(MealWindow(
                startTime: calendar.date(bySettingHour: firstMealHour, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: firstMealHour + 2, minute: 0, second: 0, of: today)!,
                targetCalories: Int(Double(2400) * 0.25),
                targetMacros: MacroTargets(protein: 30, carbs: 45, fat: 15),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: today
            ))
            
            // Lunch window
            windows.append(MealWindow(
                startTime: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: today)!,
                targetCalories: Int(Double(2400) * 0.35),
                targetMacros: MacroTargets(protein: 40, carbs: 60, fat: 25),
                purpose: .sustainedEnergy,
                flexibility: .moderate,
                dayDate: today
            ))
            
            // Dinner window
            windows.append(MealWindow(
                startTime: calendar.date(bySettingHour: lastMealHour - 2, minute: 0, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: lastMealHour, minute: 0, second: 0, of: today)!,
                targetCalories: Int(Double(2400) * 0.30),
                targetMacros: MacroTargets(protein: 35, carbs: 40, fat: 20),
                purpose: .recovery,
                flexibility: .strict,
                dayDate: today
            ))
        }
        
        // Add snack windows if needed
        if mealCount >= 4 && hasWorkout {
            windows.insert(MealWindow(
                startTime: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!,
                endTime: calendar.date(bySettingHour: 16, minute: 30, second: 0, of: today)!,
                targetCalories: Int(Double(2400) * 0.10),
                targetMacros: MacroTargets(protein: 10, carbs: 25, fat: 5),
                purpose: .preworkout,
                flexibility: .flexible,
                dayDate: today
            ), at: 2)
        }
        
        return windows
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your personalized plan")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                    
                    Text("Here's a preview of your meal windows")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .animation(.easeOut(duration: 0.6), value: animateIn)
                
                // Summary Cards
                VStack(spacing: 16) {
                    // Daily Targets
                    DailyTargetsCard(data: data)
                        .opacity(animateIn ? 1 : 0)
                        .offset(x: animateIn ? 0 : -50)
                        .animation(.easeOut(duration: 0.6).delay(0.2), value: animateIn)
                    
                    // Meal Schedule
                    MealScheduleCard(windows: sampleWindows)
                        .opacity(animateIn ? 1 : 0)
                        .offset(x: animateIn ? 0 : -50)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateIn)
                }
                .padding(.horizontal)
                
                // Timeline Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Daily Timeline")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .opacity(animateIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
                    
                    TimelinePreview(windows: sampleWindows, selectedWindow: $selectedWindow)
                        .frame(height: 300)
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.9)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
                }
                
                // Selected Window Detail
                if let window = selectedWindow {
                    WindowDetailCard(window: window)
                        .padding(.horizontal)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
                
                // What's Next
                VStack(alignment: .leading, spacing: 12) {
                    Text("What happens next?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        NextStepRow(icon: "bell.badge", text: "Set up smart nudges to stay on track")
                        NextStepRow(icon: "camera", text: "Log your first meal with AI assistance")
                        NextStepRow(icon: "chart.line.uptrend.xyaxis", text: "Track your progress and energy levels")
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.6), value: animateIn)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
}

// MARK: - Daily Targets Card

struct DailyTargetsCard: View {
    let data: OnboardingData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Daily Nutrition Targets")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: "target")
                    .font(.system(size: 18))
                    .foregroundColor(.phylloAccent)
            }
            
            HStack(spacing: 16) {
                MacroTargetView(
                    title: "Calories",
                    value: "2,400",
                    color: .phylloAccent
                )
                
                MacroTargetView(
                    title: "Protein",
                    value: "120g",
                    color: .blue
                )
                
                MacroTargetView(
                    title: "Carbs",
                    value: "270g",
                    color: .orange
                )
                
                MacroTargetView(
                    title: "Fat",
                    value: "80g",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

struct MacroTargetView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Schedule Card

struct MealScheduleCard: View {
    let windows: [MealWindow]
    
    private func getWindowTitle(for window: MealWindow) -> String {
        switch window.purpose {
        case .preworkout:
            return "Pre-Workout"
        case .postworkout:
            return "Post-Workout"
        case .sustainedEnergy:
            return "Energy Window"
        case .recovery:
            return "Recovery"
        case .metabolicBoost:
            return "Metabolic Boost"
        case .sleepOptimization:
            return "Sleep Support"
        case .focusBoost:
            return "Focus Boost"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label {
                Text("Meal Windows")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } icon: {
                Image(systemName: "clock")
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ForEach(windows) { window in
                    HStack {
                        Circle()
                            .fill(window.purpose.color)
                            .frame(width: 8, height: 8)
                        
                        Text(getWindowTitle(for: window))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(window.startTime.formatted(date: .omitted, time: .shortened)) - \(window.endTime.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Timeline Preview

struct TimelinePreview: View {
    let windows: [MealWindow]
    @Binding var selectedWindow: MealWindow?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(7..<22) { hour in
                    VStack(spacing: 8) {
                        // Hour label
                        Text("\(hour):00")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        
                        // Window indicators
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(width: 60, height: 200)
                            
                            ForEach(windows) { window in
                                if isWindowInHour(window: window, hour: hour) {
                                    Rectangle()
                                        .fill(window.purpose.color.opacity(0.3))
                                        .overlay(
                                            Rectangle()
                                                .stroke(window.purpose.color, lineWidth: 2)
                                        )
                                        .overlay(
                                            Text(getWindowTitle(for: window))
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                                .rotationEffect(.degrees(-90))
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                selectedWindow = window
                                            }
                                        }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func isWindowInHour(window: MealWindow, hour: Int) -> Bool {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: window.startTime)
        let endHour = calendar.component(.hour, from: window.endTime)
        return hour >= startHour && hour < endHour
    }
    
    private func getWindowTitle(for window: MealWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: window.startTime)
        
        switch window.purpose {
        case .preworkout:
            return "Pre-Workout"
        case .postworkout:
            return "Post-Workout"
        case .sustainedEnergy:
            return "Energy Window"
        case .recovery:
            return "Recovery"
        case .metabolicBoost:
            return "Metabolic Boost"
        case .sleepOptimization:
            return "Sleep Support"
        case .focusBoost:
            return "Focus Boost"
        }
    }
}

// MARK: - Window Detail Card

struct WindowDetailCard: View {
    let window: MealWindow
    
    private func getWindowTitle(for window: MealWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: window.startTime)
        
        switch window.purpose {
        case .preworkout:
            return "Pre-Workout"
        case .postworkout:
            return "Post-Workout"
        case .sustainedEnergy:
            return "Energy Window"
        case .recovery:
            return "Recovery"
        case .metabolicBoost:
            return "Metabolic Boost"
        case .sleepOptimization:
            return "Sleep Support"
        case .focusBoost:
            return "Focus Boost"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(window.purpose.color)
                    .frame(width: 12, height: 12)
                
                Text(getWindowTitle(for: window))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(getWindowTitle(for: window))
                    .font(.system(size: 14))
                    .foregroundColor(window.purpose.color)
            }
            
            HStack(spacing: 20) {
                Label {
                    Text("\(window.targetCalories) cal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } icon: {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
                
                Label {
                    Text("\(window.targetMacros.protein)g protein")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                } icon: {
                    Image(systemName: "p.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(window.purpose.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(window.purpose.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Next Step Row

struct NextStepRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.phylloAccent)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        var sampleData: OnboardingData {
            var data = OnboardingData()
            data.primaryGoal = .performanceFocus
            data.wakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: Date())
            data.sleepTime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())
            data.preferredMealCount = 4
            data.workoutDays = [1, 3, 5]
            data.fastingProtocol = .sixteen8
            return data
        }
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                PlanPreviewView(data: sampleData)
            }
        }
    }
    
    return PreviewWrapper()
}
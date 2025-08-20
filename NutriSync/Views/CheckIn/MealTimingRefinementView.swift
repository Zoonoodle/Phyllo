//
//  MealTimingRefinementView.swift
//  NutriSync
//
//  Created on 8/19/25.
//

import SwiftUI

struct MealTimingRefinementView: View {
    @Binding var parsedMeals: [ParsedMealWithTiming]
    let missedWindows: [MealWindow]
    let onComplete: ([ParsedMealWithTiming]) -> Void
    let onBack: () -> Void
    
    @State private var currentMealIndex = 0
    @State private var showingAnimation = false
    
    private var currentMeal: ParsedMealWithTiming? {
        guard currentMealIndex < parsedMeals.count else { return nil }
        return parsedMeals[currentMealIndex]
    }
    
    private var progressPercentage: Double {
        guard parsedMeals.count > 0 else { return 0 }
        return Double(currentMealIndex + 1) / Double(parsedMeals.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 16) {
                HStack {
                    Button(action: handleBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("\(currentMealIndex + 1) of \(parsedMeals.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                    
                    // Invisible spacer for balance
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 4)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nutriSyncAccent)
                            .frame(width: geometry.size.width * progressPercentage, height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressPercentage)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 24)
            }
            .padding(.top, 50)
            .padding(.bottom, 40)
            
            if let meal = currentMeal {
                // Main content
                VStack(spacing: 32) {
                    // Question
                    VStack(spacing: 12) {
                        Text("When did you have")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(meal.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Text("?")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                    
                    // Window options
                    VStack(spacing: 12) {
                        ForEach(missedWindows) { window in
                            WindowSelectionButton(
                                window: window,
                                isSelected: parsedMeals[currentMealIndex].assignedWindow?.id == window.id,
                                action: {
                                    selectWindow(window)
                                }
                            )
                        }
                        
                        // Skip option if multiple meals
                        if parsedMeals.count > 1 {
                            Button(action: {
                                // Leave unassigned and continue
                                handleNext()
                            }) {
                                Text("I didn't have this")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Continue button (only show after selection)
                if parsedMeals[currentMealIndex].assignedWindow != nil {
                    Button(action: handleNext) {
                        HStack {
                            Text(currentMealIndex == parsedMeals.count - 1 ? "Finish" : "Next")
                                .font(.system(size: 16, weight: .semibold))
                            
                            if currentMealIndex < parsedMeals.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.nutriSyncAccent)
                        .cornerRadius(26)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nutriSyncBackground)
        .animation(.easeInOut(duration: 0.3), value: currentMealIndex)
        .onAppear {
            showingAnimation = true
            
            // Auto-assign if only one window matches the meal type
            autoAssignObviousWindows()
        }
    }
    
    private func handleBack() {
        if currentMealIndex > 0 {
            withAnimation {
                currentMealIndex -= 1
            }
        } else {
            onBack()
        }
    }
    
    private func handleNext() {
        if currentMealIndex < parsedMeals.count - 1 {
            withAnimation {
                currentMealIndex += 1
            }
        } else {
            // Complete the process
            onComplete(parsedMeals)
        }
    }
    
    private func selectWindow(_ window: MealWindow) {
        parsedMeals[currentMealIndex].assignedWindow = window
        
        // Auto-advance after a short delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentMealIndex < parsedMeals.count - 1 {
                handleNext()
            }
        }
    }
    
    private func autoAssignObviousWindows() {
        // Auto-assign meals to windows based on meal type keywords
        for i in parsedMeals.indices {
            let mealDesc = parsedMeals[i].description.lowercased()
            
            // Breakfast keywords
            if mealDesc.contains("breakfast") || mealDesc.contains("eggs") || 
               mealDesc.contains("cereal") || mealDesc.contains("pancake") ||
               mealDesc.contains("toast") || mealDesc.contains("coffee") {
                if let breakfastWindow = missedWindows.first(where: { window in
                    Calendar.current.component(.hour, from: window.startTime) < 11
                }) {
                    parsedMeals[i].suggestedWindow = breakfastWindow
                    // Auto-assign if it's the only morning window
                    if missedWindows.filter({ Calendar.current.component(.hour, from: $0.startTime) < 11 }).count == 1 {
                        parsedMeals[i].assignedWindow = breakfastWindow
                    }
                }
            }
            // Lunch keywords
            else if mealDesc.contains("lunch") || mealDesc.contains("sandwich") ||
                    mealDesc.contains("salad") || mealDesc.contains("bowl") {
                if let lunchWindow = missedWindows.first(where: { window in
                    let hour = Calendar.current.component(.hour, from: window.startTime)
                    return hour >= 11 && hour <= 14
                }) {
                    parsedMeals[i].suggestedWindow = lunchWindow
                }
            }
            // Dinner keywords
            else if mealDesc.contains("dinner") || mealDesc.contains("salmon") ||
                    mealDesc.contains("steak") || mealDesc.contains("pasta") {
                if let dinnerWindow = missedWindows.first(where: { window in
                    Calendar.current.component(.hour, from: window.startTime) >= 17
                }) {
                    parsedMeals[i].suggestedWindow = dinnerWindow
                }
            }
        }
    }
}

struct WindowSelectionButton: View {
    let window: MealWindow
    let isSelected: Bool
    let action: () -> Void
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: window.startTime)) - \(formatter.string(from: window.endTime))"
    }
    
    private var windowTypeText: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "Breakfast"
        case 11...14: return "Lunch"
        case 15...17: return "Snack"
        case 18...21: return "Dinner"
        default: return "Late Snack"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(windowTypeText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white)
                    
                    HStack(spacing: 12) {
                        // Time range
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(timeRangeText)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.7))
                        
                        // Calories
                        HStack(spacing: 4) {
                            Image(systemName: "flame")
                                .font(.system(size: 12))
                            Text("\(window.targetCalories) cal")
                                .font(.system(size: 14))
                        }
                        .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Window purpose icon
                Image(systemName: window.purpose.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black.opacity(0.8) : window.purpose.color)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color.clear : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
    @State var parsedMeals = [
        ParsedMealWithTiming(
            name: "Scrambled eggs and toast",
            description: "scrambled eggs and toast",
            suggestedWindow: nil,
            assignedWindow: nil
        ),
        ParsedMealWithTiming(
            name: "Chipotle chicken bowl",
            description: "Chipotle chicken bowl",
            suggestedWindow: nil,
            assignedWindow: nil
        ),
        ParsedMealWithTiming(
            name: "Grilled salmon with rice",
            description: "grilled salmon with rice",
            suggestedWindow: nil,
            assignedWindow: nil
        )
    ]
    
    let mockWindows = [
        MealWindow(
            startTime: Date().addingTimeInterval(-36000), // 10 hours ago
            endTime: Date().addingTimeInterval(-32400),   // 9 hours ago
            targetCalories: 400,
            targetMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
            purpose: .metabolicBoost,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        ),
        MealWindow(
            startTime: Date().addingTimeInterval(-21600), // 6 hours ago
            endTime: Date().addingTimeInterval(-18000),   // 5 hours ago
            targetCalories: 500,
            targetMacros: MacroTargets(protein: 35, carbs: 50, fat: 20),
            purpose: .sustainedEnergy,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        ),
        MealWindow(
            startTime: Date().addingTimeInterval(-7200), // 2 hours ago
            endTime: Date().addingTimeInterval(-3600),   // 1 hour ago
            targetCalories: 600,
            targetMacros: MacroTargets(protein: 40, carbs: 60, fat: 25),
            purpose: .recovery,
            flexibility: .moderate,
            dayDate: Calendar.current.startOfDay(for: Date())
        )
    ]
    
    return MealTimingRefinementView(
        parsedMeals: $parsedMeals,
        missedWindows: mockWindows,
        onComplete: { meals in
            print("Completed with meals: \(meals)")
        },
        onBack: {
            print("Back pressed")
        }
    )
    .preferredColorScheme(.dark)
}
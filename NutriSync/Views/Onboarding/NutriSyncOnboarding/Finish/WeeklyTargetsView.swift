//
//  WeeklyTargetsView.swift
//  NutriSync
//
//  Shows daily calorie and macro variations throughout the week
//

import SwiftUI

struct WeeklyTargetsView: View {
    let baseCalories: Int
    let baseMacros: OnboardingMacroTargets
    let goal: String // "lose", "gain", "maintain"
    
    @State private var selectedDay: Int? = nil
    @State private var showingDetail = false
    
    var dailyTargets: [(day: String, calories: Int, protein: Int, carbs: Int, fat: Int)] {
        // Generate variations based on goal
        // For weight loss: lower calories on rest days, higher on training days
        // For muscle gain: higher calories on training days, moderate on rest days
        // For maintenance: steady throughout week
        
        let variation = goal == "lose" ? 0.15 : (goal == "gain" ? 0.10 : 0.05)
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        return days.enumerated().map { index, day in
            let isWeekend = index >= 5
            let isTrainingDay = [1, 3, 5].contains(index) // Tue, Thu, Sat
            
            var calorieMultiplier: Double = 1.0
            
            if goal == "lose" {
                // Calorie cycling for weight loss
                calorieMultiplier = isTrainingDay ? 1.1 : 0.9
            } else if goal == "gain" {
                // Surplus on training days for muscle gain
                calorieMultiplier = isTrainingDay ? 1.15 : 1.0
            }
            
            let dayCalories = Int(Double(baseCalories) * calorieMultiplier)
            
            // Adjust macros proportionally
            let proteinRatio = isTrainingDay ? 1.05 : 1.0
            let carbRatio = isTrainingDay ? 1.2 : 0.85
            let fatRatio = isWeekend ? 1.1 : 1.0
            
            return (
                day: day,
                calories: dayCalories,
                protein: Int(Double(baseMacros.protein) * proteinRatio),
                carbs: Int(Double(baseMacros.carbs) * carbRatio),
                fat: Int(Double(baseMacros.fat) * fatRatio)
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("Weekly Nutrition Targets")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Your targets vary daily to optimize \(goalDescription)")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Daily bars visualization
            VStack(spacing: 12) {
                ForEach(Array(dailyTargets.enumerated()), id: \.offset) { index, dayData in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedDay = selectedDay == index ? nil : index
                        }
                    } label: {
                        DayTargetRow(
                            dayData: dayData,
                            isSelected: selectedDay == index,
                            averageCalories: baseCalories
                        )
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                MacroLegendItem(color: .orange, label: "Protein")
                MacroLegendItem(color: .blue, label: "Carbs")
                MacroLegendItem(color: .yellow, label: "Fat")
            }
            .padding(.top, 8)
            
            // Average note
            VStack(spacing: 4) {
                Text("Weekly Average")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.4))
                Text("\(baseCalories) calories")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var goalDescription: String {
        switch goal {
        case "lose":
            return "fat loss"
        case "gain":
            return "muscle growth"
        default:
            return "maintenance"
        }
    }
}

// MARK: - Day Target Row
struct DayTargetRow: View {
    let dayData: (day: String, calories: Int, protein: Int, carbs: Int, fat: Int)
    let isSelected: Bool
    let averageCalories: Int
    
    private var calorieDeviation: Int {
        dayData.calories - averageCalories
    }
    
    private var deviationColor: Color {
        if calorieDeviation > 100 {
            return Color(hex: "71C5C5").opacity(0.8)  // Higher days in soft teal
        } else if calorieDeviation < -100 {
            return Color(hex: "FF9580").opacity(0.6)  // Lower days in soft coral
        } else {
            return .white.opacity(0.4)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Day label
                Text(dayData.day)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 35, alignment: .leading)
                
                // Calorie bar with macro breakdown
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Protein section - orange
                        Rectangle()
                            .fill(Color.orange.opacity(0.7))
                            .frame(width: geometry.size.width * macroRatio(dayData.protein * 4))
                        
                        // Carbs section - blue
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: geometry.size.width * macroRatio(dayData.carbs * 4))
                        
                        // Fat section - yellow
                        Rectangle()
                            .fill(Color.yellow.opacity(0.7))
                            .frame(width: geometry.size.width * macroRatio(dayData.fat * 9))
                        
                        Spacer()
                    }
                    .cornerRadius(6)
                    .overlay(
                        // Calorie value overlay
                        Text("\(dayData.calories)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                            .padding(.leading, 8),
                        alignment: .leading
                    )
                }
                .frame(height: 32)
                
                // Deviation indicator
                HStack(spacing: 4) {
                    Image(systemName: calorieDeviation > 0 ? "arrow.up" : calorieDeviation < 0 ? "arrow.down" : "minus")
                        .font(.system(size: 12))
                    Text("\(abs(calorieDeviation))")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(deviationColor)
                .frame(width: 50, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(isSelected ? 0.08 : 0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.nutriSyncAccent : Color.clear, lineWidth: 2)
            )
            .cornerRadius(10)
            
            // Expanded macro detail
            if isSelected {
                HStack(spacing: 16) {
                    MacroDetailItem(value: "\(dayData.protein)g", label: "Protein", color: .orange)
                    MacroDetailItem(value: "\(dayData.carbs)g", label: "Carbs", color: .blue)
                    MacroDetailItem(value: "\(dayData.fat)g", label: "Fat", color: .yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.02))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private func macroRatio(_ calories: Int) -> CGFloat {
        let totalCalories = dayData.calories
        return CGFloat(calories) / CGFloat(totalCalories)
    }
}

// MARK: - Supporting Views
struct MacroLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.8))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct MacroDetailItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color.opacity(0.9))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}
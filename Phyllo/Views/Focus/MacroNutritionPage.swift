//
//  MacroNutritionPage.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct MacroNutritionPage: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    
    // Calculate consumed values for this window
    private var windowCaloriesConsumed: Int {
        viewModel.caloriesConsumedInWindow(window)
    }
    
    private var windowProteinConsumed: Int {
        viewModel.proteinConsumedInWindow(window)
    }
    
    private var windowCarbsConsumed: Int {
        viewModel.carbsConsumedInWindow(window)
    }
    
    private var windowFatConsumed: Int {
        viewModel.fatConsumedInWindow(window)
    }
    
    private var calorieProgress: Double {
        guard window.effectiveCalories > 0 else { return 0 }
        return Double(windowCaloriesConsumed) / Double(window.effectiveCalories)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            HStack {
                Text("NutriSync Ring")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Calorie ring with more top padding
            ZStack {
                // Background ring with open bottom
                Circle()
                    .trim(from: 0.12, to: 0.88)
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(90))
                
                // Progress ring with open bottom and tapered ends
                Circle()
                    .trim(from: 0, to: min(calorieProgress * 0.76, 0.76))
                    .stroke(
                        window.purpose.color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(126))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: calorieProgress)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(Int(calorieProgress * 100))% Complete")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(windowCaloriesConsumed) / \(window.effectiveCalories) cal")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Macro bars with proper padding
            HStack(spacing: 20) {
                MacroProgressBar(
                    title: "Protein",
                    consumed: windowProteinConsumed,
                    target: window.effectiveMacros.protein,
                    color: .orange
                )
                
                MacroProgressBar(
                    title: "Fat",
                    consumed: windowFatConsumed,
                    target: window.effectiveMacros.fat,
                    color: .yellow
                )
                
                MacroProgressBar(
                    title: "Carbs",
                    consumed: windowCarbsConsumed,
                    target: window.effectiveMacros.carbs,
                    color: .blue
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 40)
        .padding(.bottom, 34)
    }
}

struct MacroProgressBar: View {
    let title: String
    let consumed: Int
    let target: Int
    let color: Color
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return Double(consumed) / Double(target)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Label on top
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            // Progress bar in middle
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * min(progress, 1), height: 5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 5)
            
            // Values on bottom (consumed/target)
            Text("\(consumed)/\(target)g")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        if let window = viewModel.mealWindows.first {
            MacroNutritionPage(window: window, viewModel: viewModel)
                .padding()
        }
    }
}

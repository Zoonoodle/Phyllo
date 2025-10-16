//
//  AnalyzingMealCard.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct AnalyzingMealCard: View {
    let timestamp: Date
    let metadata: AnalysisMetadata?
    let window: MealWindow? // Optional window to get purpose color
    @ObservedObject private var agent = MealAnalysisAgent.shared
    @State private var showMetadata = false

    // Get color from window purpose, fallback to accent color
    private var displayColor: Color {
        window?.purpose.color ?? .nutriSyncAccent
    }

    var body: some View {
        // Just show the glass morphism text - no extra UI elements
        CompactMealAnalysisLoader(
            size: .card,
            windowColor: displayColor
        )
        .padding(.vertical, 16)
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Timeline version with smaller design
struct AnalyzingMealRow: View {
    let timestamp: Date
    let metadata: AnalysisMetadata?
    let window: MealWindow? // Optional window to get purpose color
    @ObservedObject private var agent = MealAnalysisAgent.shared

    // Get color from window purpose, fallback to accent color
    private var displayColor: Color {
        window?.purpose.color ?? .nutriSyncAccent
    }

    var body: some View {
        // Just show the glass morphism text - no extra UI elements
        CompactMealAnalysisLoader(
            size: .inline,
            windowColor: displayColor
        )
        .padding(.vertical, 8)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
}

// Shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview("Window Card") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            // Create sample windows for different purposes
            let preWorkoutWindow = MealWindow.mockWindows(for: .performanceFocus).first!
            let postWorkoutWindow = MealWindow.mockWindows(for: .muscleGain(targetPounds: 5, timeline: 12))[1]
            let recoveryWindow = MealWindow.mockWindows(for: .muscleGain(targetPounds: 5, timeline: 12)).last!

            // Standard analyzing - pre-workout (orange)
            AnalyzingMealCard(timestamp: Date(), metadata: nil, window: preWorkoutWindow)
                .padding()

            // With metadata - restaurant (blue - post-workout)
            AnalyzingMealCard(
                timestamp: Date(),
                metadata: AnalysisMetadata(
                    toolsUsed: [.brandSearch, .deepAnalysis],
                    complexity: .restaurant,
                    analysisTime: 6.5,
                    confidence: 0.95,
                    brandDetected: "Chipotle",
                    ingredientCount: 8
                ),
                window: postWorkoutWindow
            )
            .padding()

            // With metadata - complex (purple - recovery)
            AnalyzingMealCard(
                timestamp: Date(),
                metadata: AnalysisMetadata(
                    toolsUsed: [.deepAnalysis, .nutritionLookup],
                    complexity: .complex,
                    analysisTime: 4.2,
                    confidence: 0.82,
                    brandDetected: nil,
                    ingredientCount: 12
                ),
                window: recoveryWindow
            )
            .padding()
        }
    }
}

#Preview("Timeline Row") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            let sustainedEnergyWindow = MealWindow.mockWindows(for: .weightLoss(targetPounds: 10, timeline: 8))[1]

            AnalyzingMealRow(timestamp: Date(), metadata: nil, window: sustainedEnergyWindow)
                .padding()

            // With metadata
            AnalyzingMealRow(
                timestamp: Date(),
                metadata: AnalysisMetadata(
                    toolsUsed: [.brandSearch],
                    complexity: .restaurant,
                    analysisTime: 5.2,
                    confidence: 0.92,
                    brandDetected: "Starbucks",
                    ingredientCount: 5
                ),
                window: sustainedEnergyWindow
            )
            .padding()

            // Preview of final state
            let mockMeal = LoggedMeal(
                name: "Chicken Salad",
                calories: 450,
                protein: 35,
                carbs: 20,
                fat: 25,
                timestamp: Date()
            )
            MealRow(meal: mockMeal)
                .padding()
        }
    }
}
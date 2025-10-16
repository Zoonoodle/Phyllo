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
        VStack(spacing: 12) {
            // Show stage indicators
            AnalysisStageIndicator(
                tool: agent.currentTool,
                color: displayColor,
                isCompleted: false
            )

            // Plain text status message
            Text(statusMessage.lowercased())
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(displayColor)
        }
        .padding(.vertical, 12)
    }

    // Get current status message
    private var statusMessage: String {
        // Use agent's actual progress if available
        if !agent.toolProgress.isEmpty && agent.isUsingTools {
            return agent.toolProgress
        }

        // Use tool-specific message if available
        if let tool = agent.currentTool {
            return tool.displayName
        }

        // Fallback
        return "analyzing meal..."
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
        // Timeline view stays minimal without stage indicators
        CompactMealAnalysisLoader(
            size: .inline,
            windowColor: displayColor,
            showStageIndicators: false  // No stage dots in timeline
        )
        .padding(.vertical, 8)
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
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
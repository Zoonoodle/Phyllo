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
        HStack(spacing: 16) {
            // New compact meal analysis loader with window-specific color
            CompactMealAnalysisLoader(
                size: .card,
                windowColor: displayColor
            )
            .frame(width: 80)
            
            // Meal info (loading state)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Analyzing")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(timeString(from: timestamp))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Tool progress indicator or metadata
                if let metadata = metadata {
                    // Show completed analysis metadata
                    VStack(alignment: .leading, spacing: 4) {
                        // Complexity badge
                        HStack(spacing: 6) {
                            Image(systemName: metadata.complexity.icon)
                                .font(.system(size: 10))
                                .foregroundColor(.nutriSyncAccent)
                            
                            Text(metadata.complexity.displayName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.nutriSyncAccent)
                            
                            if !metadata.toolsUsed.isEmpty {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("\(metadata.toolsUsed.count) tool\(metadata.toolsUsed.count == 1 ? "" : "s")")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        // Tools used badges
                        if !metadata.toolsUsed.isEmpty {
                            HStack(spacing: 4) {
                                ForEach(metadata.toolsUsed, id: \.self) { tool in
                                    HStack(spacing: 3) {
                                        Image(systemName: tool.icon)
                                            .font(.system(size: 9))
                                        Text(tool.displayName)
                                            .font(.system(size: 9))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(hex: tool.color).opacity(0.2))
                                    .foregroundColor(Color(hex: tool.color))
                                    .cornerRadius(4)
                                }
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                } else if agent.isUsingTools, agent.currentTool != nil {
                    HStack(spacing: 6) {
                        Image(systemName: agent.currentTool?.iconName ?? "sparkle")
                            .font(.system(size: 11))
                            .foregroundColor(.nutriSyncAccent)
                        
                        Text(agent.toolProgress)
                            .font(.system(size: 12))
                            .foregroundColor(.nutriSyncAccent.opacity(0.8))
                            .lineLimit(1)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    // Shimmer placeholder for macro data
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 12)
                        .shimmer()
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(displayColor.opacity(0.3), lineWidth: 1)
                )
        )
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
        HStack(spacing: 12) {
            // Time
            Text(timeFormatter.string(from: timestamp))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)

            // New compact meal analysis loader with window-specific color
            CompactMealAnalysisLoader(
                size: .inline,
                windowColor: displayColor
            )
            
            // Meal info (if metadata available)
            if let metadata = metadata {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        // Show completed analysis badge
                        Image(systemName: metadata.complexity.icon)
                            .font(.system(size: 10))
                            .foregroundColor(.nutriSyncAccent)
                        
                        Text(metadata.complexity.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    // Show tools if available
                    if !metadata.toolsUsed.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(metadata.toolsUsed.prefix(2), id: \.self) { tool in
                                Image(systemName: tool.icon)
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(hex: tool.color))
                            }
                            if metadata.toolsUsed.count > 2 {
                                Text("+\(metadata.toolsUsed.count - 2)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.nutriSyncBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(displayColor.opacity(0.3), lineWidth: 1)
                )
        )
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
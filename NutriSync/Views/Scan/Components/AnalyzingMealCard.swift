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
    @State private var shimmerPhase: CGFloat = 0
    @State private var currentMessageIndex: Int = 0
    @State private var messageTimer: Timer?

    // Get color from window purpose, fallback to accent color
    private var displayColor: Color {
        window?.purpose.color ?? .nutriSyncAccent
    }

    // Rotating status messages
    private let statusMessages = [
        "Identifying ingredients...",
        "Calculating nutrition...",
        "Analyzing portions...",
        "Finalizing analysis..."
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Main card content - matches FoodItemCard structure
            HStack(spacing: 16) {
                // Animated placeholder for emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 50, height: 50)

                    // Sparkle icon with pulse animation
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(displayColor.opacity(0.6))
                        .modifier(PulseAnimation())
                }

                // Meal info skeleton
                VStack(alignment: .leading, spacing: 4) {
                    // Status message with shimmer
                    Text(statusMessage)
                        .font(TimelineTypography.foodName)
                        .foregroundColor(displayColor)
                        .modifier(ShimmerEffect(isAnimating: true))

                    // Time and stage indicator
                    HStack(spacing: 8) {
                        Text(timeString(from: timestamp))
                            .font(TimelineTypography.foodCalories)
                            .foregroundColor(.white.opacity(TimelineOpacity.secondary))

                        Text("•")
                            .foregroundColor(.white.opacity(TimelineOpacity.quaternary))

                        // Stage indicators
                        AnalysisStageIndicator(
                            tool: agent.currentTool,
                            color: displayColor,
                            isCompleted: false
                        )
                    }

                    // Skeleton for macros
                    HStack(spacing: 8) {
                        SkeletonPill(width: 35)
                        SkeletonPill(width: 30)
                        SkeletonPill(width: 30)
                    }
                }

                Spacer()

                // Loading spinner instead of chevron
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: displayColor))
                    .scaleEffect(0.8)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(displayColor.opacity(0.2), lineWidth: 1)
                )
        )
        .onAppear {
            startMessageRotation()
        }
        .onDisappear {
            messageTimer?.invalidate()
        }
    }

    // Get current status message
    private var statusMessage: String {
        // Use agent's actual progress if available
        if !agent.toolProgress.isEmpty && agent.isUsingTools {
            return agent.toolProgress.lowercased()
        }

        // Use tool-specific message if available
        if let tool = agent.currentTool {
            return tool.displayName.lowercased()
        }

        // Fall back to rotating messages
        return statusMessages[currentMessageIndex].lowercased()
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func startMessageRotation() {
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMessageIndex = (currentMessageIndex + 1) % statusMessages.count
            }
        }
    }
}

// Skeleton pill for loading state
private struct SkeletonPill: View {
    let width: CGFloat
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.1))
            .frame(width: width, height: 12)
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0), location: 0),
                            .init(color: Color.white.opacity(0.15), location: 0.5),
                            .init(color: Color.white.opacity(0), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + shimmerPhase * (geometry.size.width * 2))
                }
                .mask(RoundedRectangle(cornerRadius: 4))
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    shimmerPhase = 1
                }
            }
    }
}

// Pulse animation modifier
private struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.7)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
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
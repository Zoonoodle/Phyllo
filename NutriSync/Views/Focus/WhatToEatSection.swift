//
//  WhatToEatSection.swift
//  NutriSync
//
//  Expandable section showing AI-generated food suggestions for a meal window
//

import SwiftUI

struct WhatToEatSection: View {
    let window: MealWindow
    @Binding var isExpanded: Bool
    let onRetry: (() -> Void)?
    /// Optional callback when user taps "Log This Meal" on a suggestion
    var onLogSuggestion: ((FoodSuggestion) -> Void)?
    /// When false, hides the header row and divider (for embedding in cards with custom headers)
    var showHeader: Bool = true

    @State private var showFoodSuggestionsTour = false
    private let tourManager = TourManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Divider separator (only when showing header)
            if showHeader {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
            }

            // Section content
            VStack(alignment: .leading, spacing: 12) {
                // Header row (only when showHeader is true)
                if showHeader {
                    headerRow
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }
                }

                // Content (always show when header is hidden, or when expanded)
                if isExpanded || !showHeader {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, showHeader ? 12 : 0)
            .padding(.vertical, showHeader ? 12 : 0)
        }
        .overlay {
            // Food Suggestions Tour
            if showFoodSuggestionsTour {
                FoodSuggestionsTour(
                    onComplete: {
                        tourManager.completeFoodSuggestionsTour()
                        showFoodSuggestionsTour = false
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: window.suggestionStatus) { _, newStatus in
            // Show tour when suggestions become ready for the first time
            if newStatus == .ready && !window.smartSuggestions.isEmpty && tourManager.shouldShowFoodSuggestionsTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showFoodSuggestionsTour = true
                }
            }
        }
        .onAppear {
            // Also check on appear in case suggestions were already ready
            if window.suggestionStatus == .ready && !window.smartSuggestions.isEmpty && tourManager.shouldShowFoodSuggestionsTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showFoodSuggestionsTour = true
                }
            }
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack {
            HStack(spacing: 8) {
                Text("🍽️")
                    .font(.system(size: 16))

                Text("What to Eat")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Badge or status indicator
            if window.suggestionStatus == .ready && !window.smartSuggestions.isEmpty {
                Text("\(window.smartSuggestions.count) ready")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.nutriSyncAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.nutriSyncAccent.opacity(0.2))
                    )
            } else if window.suggestionStatus == .generating {
                HStack(spacing: 4) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                        .scaleEffect(0.6)

                    Text("Loading...")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Chevron
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Expanded Content

    @ViewBuilder
    private var expandedContent: some View {
        switch window.suggestionStatus {
        case .pending:
            SuggestionEmptyStateView(status: .pending, windowStartTime: window.startTime)

        case .generating:
            SuggestionEmptyStateView(status: .generating)

        case .ready:
            if window.smartSuggestions.isEmpty {
                SuggestionEmptyStateView(status: .failed, onRetry: onRetry)
            } else {
                suggestionsList
            }

        case .failed:
            SuggestionEmptyStateView(status: .failed, onRetry: onRetry)
        }
    }

    // MARK: - Suggestions List

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Context note
            if let contextNote = window.suggestionContextNote {
                SuggestionContextNoteView(
                    contextNote: contextNote,
                    isFirstWindow: contextNote.contains("morning")
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Suggestion cards with staggered animation
            // Cards are now expandable - tap to expand/collapse, with optional log action
            ForEach(Array(window.smartSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                FoodSuggestionCard(
                    suggestion: suggestion,
                    onLogTap: onLogSuggestion != nil ? { onLogSuggestion?(suggestion) } : nil
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity
                            .combined(with: .scale(scale: 0.95))
                            .combined(with: .offset(y: 10))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05)),
                        removal: .opacity.animation(.easeOut(duration: 0.2))
                    )
                )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: window.smartSuggestions.count)
    }
}

// MARK: - Preview

#Preview("Ready State") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack {
            WhatToEatSection(
                window: previewWindow(status: .ready),
                isExpanded: .constant(true),
                onRetry: nil
            )
        }
        .padding()
    }
}

#Preview("Pending State") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack {
            WhatToEatSection(
                window: previewWindow(status: .pending),
                isExpanded: .constant(true),
                onRetry: nil
            )
        }
        .padding()
    }
}

#Preview("Generating State") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack {
            WhatToEatSection(
                window: previewWindow(status: .generating),
                isExpanded: .constant(true),
                onRetry: nil
            )
        }
        .padding()
    }
}

// Preview helper
private func previewWindow(status: SuggestionStatus) -> MealWindow {
    var window = MealWindow(
        name: "Midday Power",
        startTime: Date(),
        endTime: Date().addingTimeInterval(3600 * 3),
        targetCalories: 600,
        targetProtein: 40,
        targetCarbs: 60,
        targetFat: 20,
        purpose: .sustainedEnergy,
        flexibility: .moderate,
        type: .regular,
        suggestionStatus: status
    )

    if status == .ready {
        // Create suggestions with predicted scores
        var suggestion1 = FoodSuggestion(
            id: UUID(),
            name: "Grilled Chicken Salad",
            calories: 450,
            protein: 35.0,
            carbs: 20.0,
            fat: 22.0,
            foodGroup: .protein,
            reasoningShort: "Protein boost with vegetables",
            reasoningDetailed: "High protein to help you reach your targets.",
            howYoullFeel: "Satisfied and energized.",
            supportsGoal: "Helps with weight management.",
            generatedAt: Date(),
            basedOnMacroGap: nil
        )
        suggestion1.predictedScore = 8.6
        suggestion1.scoreFactors = [
            SuggestionScoreFactor(name: "Protein balance", contribution: 1.4),
            SuggestionScoreFactor(name: "Whole foods", contribution: 1.0)
        ]

        var suggestion2 = FoodSuggestion(
            id: UUID(),
            name: "Salmon with Quinoa",
            calories: 520,
            protein: 40.0,
            carbs: 35.0,
            fat: 18.0,
            foodGroup: .protein,
            reasoningShort: "Omega-3s for sustained energy",
            reasoningDetailed: "Rich in healthy fats and complete protein.",
            howYoullFeel: "Clear-minded and focused.",
            supportsGoal: "Supports metabolic health.",
            generatedAt: Date(),
            basedOnMacroGap: nil
        )
        suggestion2.predictedScore = 8.4
        suggestion2.scoreFactors = [
            SuggestionScoreFactor(name: "Omega-3s", contribution: 1.2),
            SuggestionScoreFactor(name: "Complete protein", contribution: 0.8)
        ]

        window.smartSuggestions = [suggestion1, suggestion2]
        window.suggestionContextNote = "Based on your morning meals, you need protein:"
    }

    return window
}

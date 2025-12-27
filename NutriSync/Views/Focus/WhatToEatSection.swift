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

    @State private var selectedSuggestion: FoodSuggestion?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Divider separator
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Section content
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                headerRow
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }

                // Expanded content
                if isExpanded {
                    expandedContent
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            FoodSuggestionDetailSheet(suggestion: suggestion)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
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
            SuggestionEmptyStateView(status: .pending)

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
            }

            // Suggestion cards
            ForEach(window.smartSuggestions) { suggestion in
                FoodSuggestionCard(suggestion: suggestion) {
                    selectedSuggestion = suggestion
                }
            }
        }
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
        window.smartSuggestions = [
            FoodSuggestion(
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
            ),
            FoodSuggestion(
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
        ]
        window.suggestionContextNote = "Based on your morning meals, you need protein:"
    }

    return window
}

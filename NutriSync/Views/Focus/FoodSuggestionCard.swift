//
//  FoodSuggestionCard.swift
//  NutriSync
//
//  Expandable food suggestion card with predicted score display.
//  Phase 5: Enhanced Suggestions redesign.
//

import SwiftUI

struct FoodSuggestionCard: View {
    let suggestion: FoodSuggestion
    var onLogTap: (() -> Void)?

    @State private var isExpanded = false
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header (always visible)
            collapsedHeader
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isPressed ? 0.08 : 0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isPressed ? 0.15 : 0.1), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }

    // MARK: - Collapsed Header

    private var collapsedHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            // Food emoji
            Text(suggestion.emoji)
                .font(.system(size: 24))
                .frame(width: 32)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Name row with score
                HStack {
                    Text(suggestion.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Predicted score (if available)
                    if let score = suggestion.predictedScore {
                        ScoreText(score: score, size: .small)
                    }

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 4)
                }

                // Macro summary
                Text(suggestion.macroSummary)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))

                // Short reasoning
                Text(suggestion.reasoningShort)
                    .font(.system(size: 13, weight: .regular))
                    .italic()
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 20) {
                // Predicted Score Section
                if let score = suggestion.predictedScore {
                    predictedScoreSection(score: score)
                }

                // Why This Fits Section
                whyThisFitsSection

                // Nutrition Section
                nutritionSection

                // Score Factors (if available)
                if let factors = suggestion.scoreFactors, !factors.isEmpty {
                    scoreFactorsSection(factors: factors)
                }

                // Log Button
                if onLogTap != nil {
                    logButton
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Predicted Score Section

    private func predictedScoreSection(score: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREDICTED SCORE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ScoreText(score: score, size: .medium, showTotal: true)
            }

            ScoreProgressBar.fromScore(score, height: 6, showPercentage: false)
        }
    }

    // MARK: - Why This Fits Section

    private var whyThisFitsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("WHY THIS FITS YOUR DAY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            Text(suggestion.reasoningDetailed)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NUTRITION")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            // Calories
            Text("\(suggestion.calories) cal")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.nutriSyncAccent)

            // Macros
            HStack(spacing: 16) {
                macroBox(value: Int(suggestion.protein), unit: "g", label: "Protein")
                macroBox(value: Int(suggestion.carbs), unit: "g", label: "Carbs")
                macroBox(value: Int(suggestion.fat), unit: "g", label: "Fat")
            }
        }
    }

    private func macroBox(value: Int, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Score Factors Section

    private func scoreFactorsSection(factors: [SuggestionScoreFactor]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SCORE FACTORS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            FactorChipGrid(factors: factors.prefix(4).map { factor in
                FactorChipData(
                    label: factor.name,
                    value: factor.contribution,
                    secondaryLabel: factor.detail
                )
            })
        }
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button(action: { onLogTap?() }) {
            Text("Log This Meal")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.nutriSyncAccent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("Collapsed") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack(spacing: 12) {
            FoodSuggestionCard(
                suggestion: previewSuggestionWithScore(),
                onLogTap: {}
            )

            FoodSuggestionCard(
                suggestion: previewSuggestionNoScore(),
                onLogTap: {}
            )
        }
        .padding()
    }
}

#Preview("Expanded") {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                FoodSuggestionCard(
                    suggestion: previewSuggestionWithScore(),
                    onLogTap: {}
                )
            }
            .padding()
        }
    }
}

// Preview helpers
private func previewSuggestionWithScore() -> FoodSuggestion {
    var suggestion = FoodSuggestion(
        id: UUID(),
        name: "Herb-Crusted Chicken",
        calories: 420,
        protein: 48.0,
        carbs: 12.0,
        fat: 18.0,
        foodGroup: .protein,
        reasoningShort: "Boosts your protein gap",
        reasoningDetailed: "You're 65g short on protein and your fiber scores have been low this week. This meal provides 48g protein and 6g fiber.",
        howYoullFeel: "Satisfied and energized for hours.",
        supportsGoal: "High protein supports muscle preservation.",
        generatedAt: Date(),
        basedOnMacroGap: nil
    )
    suggestion.predictedScore = 8.7
    suggestion.scoreFactors = [
        SuggestionScoreFactor(name: "Protein balance", contribution: 1.4),
        SuggestionScoreFactor(name: "Whole foods", contribution: 1.0),
        SuggestionScoreFactor(name: "Fiber content", contribution: 0.8),
        SuggestionScoreFactor(name: "Low sodium", contribution: 0.5)
    ]
    return suggestion
}

private func previewSuggestionNoScore() -> FoodSuggestion {
    FoodSuggestion(
        id: UUID(),
        name: "Salmon Quinoa Bowl",
        calories: 520,
        protein: 38.0,
        carbs: 42.0,
        fat: 22.0,
        foodGroup: .protein,
        reasoningShort: "High omega-3 + fiber",
        reasoningDetailed: "Rich in healthy fats and complete protein for sustained energy.",
        howYoullFeel: "Clear-minded and focused.",
        supportsGoal: "Supports metabolic health.",
        generatedAt: Date(),
        basedOnMacroGap: nil
    )
}

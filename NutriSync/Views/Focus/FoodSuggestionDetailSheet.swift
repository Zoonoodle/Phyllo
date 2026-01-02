//
//  FoodSuggestionDetailSheet.swift
//  NutriSync
//
//  Detail sheet showing full information about a food suggestion.
//  Phase 5: Updated with scoring components.
//

import SwiftUI

struct FoodSuggestionDetailSheet: View {
    let suggestion: FoodSuggestion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                // Content sections
                VStack(spacing: 24) {
                    // Predicted Score (if available)
                    if let score = suggestion.predictedScore {
                        predictedScoreSection(score: score)
                    }

                    whySection

                    // Portions (if available)
                    if let portions = suggestion.portions, !portions.isEmpty {
                        portionsSection(portions: portions)
                    }

                    // Recipe (if available)
                    if let recipe = suggestion.recipe {
                        recipeSection(recipe: recipe)
                    }

                    // Score Factors (if available)
                    if let factors = suggestion.scoreFactors, !factors.isEmpty {
                        scoreFactorsSection(factors: factors)
                    }

                    howYoullFeelSection
                    supportsGoalSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .background(Color.nutriSyncBackground)
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.3), .white.opacity(0.1))
            }
            .padding(16)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            // Large emoji
            Text(suggestion.emoji)
                .font(.system(size: 48))
                .padding(.top, 40)

            // Food name
            Text(suggestion.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            // Predicted score (if available)
            if let score = suggestion.predictedScore {
                HStack(spacing: 8) {
                    Text("Predicted:")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    ScoreText(score: score, size: .medium, showTotal: true)
                }
            }

            // Calories highlight
            Text("\(suggestion.calories) cal")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.nutriSyncAccent)

            // Macro boxes
            HStack(spacing: 20) {
                macroBox(value: Int(suggestion.protein), label: "protein")
                macroBox(value: Int(suggestion.carbs), label: "carbs")
                macroBox(value: Int(suggestion.fat), label: "fat")
            }
            .padding(.bottom, 24)
        }
    }

    private func macroBox(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Predicted Score Section

    private func predictedScoreSection(score: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("PREDICTED SCORE")

            VStack(alignment: .leading, spacing: 8) {
                ScoreText(score: score, size: .large, showTotal: true)
                ScoreProgressBar.fromScore(score)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Score Factors Section

    private func scoreFactorsSection(factors: [SuggestionScoreFactor]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("WHAT MAKES THIS HEALTHY")

            FactorChipGrid(factors: factors.prefix(4).map { factor in
                FactorChipData(
                    label: factor.name,
                    value: factor.contribution,
                    secondaryLabel: factor.detail
                )
            })
        }
    }

    // MARK: - Content Sections

    private var whySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("WHY THIS SUGGESTION")

            Text(suggestion.reasoningDetailed)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
    }

    private var howYoullFeelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("HOW YOU'LL FEEL")

            Text(suggestion.howYoullFeel)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
    }

    private var supportsGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("SUPPORTS YOUR GOAL")

            Text(suggestion.supportsGoal)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(4)
        }
    }

    // MARK: - Portions Section

    private func portionsSection(portions: [IngredientPortion]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("PORTIONS")

            VStack(alignment: .leading, spacing: 8) {
                ForEach(portions) { portion in
                    HStack {
                        Text(portion.name)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(portion.displayString)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    // MARK: - Recipe Section

    private func recipeSection(recipe: RecipeInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("RECIPE")

            VStack(alignment: .leading, spacing: 12) {
                // Source and metadata
                VStack(alignment: .leading, spacing: 6) {
                    Text(recipe.source.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 16) {
                        if let timeString = recipe.timeString {
                            Label(timeString, systemImage: "clock")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        if let difficulty = recipe.difficulty {
                            Label(difficulty.rawValue, systemImage: "chart.bar")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        if recipe.nutritionVerified {
                            Label("Verified", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.nutriSyncAccent)
                        }
                    }
                }

                // View Recipe Button
                Link(destination: recipe.url) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("View Full Recipe")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.nutriSyncAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white.opacity(0.5))
            .tracking(1)
    }
}

// MARK: - Preview

#Preview("With Score") {
    FoodSuggestionDetailSheet(
        suggestion: previewSuggestionWithScoreDetail()
    )
}

#Preview("Without Score") {
    FoodSuggestionDetailSheet(
        suggestion: previewSuggestionNoScoreDetail()
    )
}

private func previewSuggestionWithScoreDetail() -> FoodSuggestion {
    var suggestion = FoodSuggestion(
        id: UUID(),
        name: "Grilled Chicken Salad",
        calories: 450,
        protein: 35.0,
        carbs: 20.0,
        fat: 22.0,
        foodGroup: .protein,
        reasoningShort: "Protein boost with vegetables you're missing",
        reasoningDetailed: "You've logged 16g of protein so far today, and your target is 130g. This salad provides 35g of high-quality protein from grilled chicken, plus fiber and vitamins from mixed greens that you haven't had yet today.",
        howYoullFeel: "The combination of lean protein and fiber-rich vegetables will keep you satisfied for 3-4 hours without feeling heavy. The balanced macros help maintain steady blood sugar, avoiding the afternoon energy crash.",
        supportsGoal: "High-protein meals increase satiety hormones and help preserve muscle while in a calorie deficit. The fiber from vegetables adds volume with minimal calories, making it easier to stay within your targets.",
        generatedAt: Date(),
        basedOnMacroGap: MacroGap(
            calories: 1695,
            protein: 114,
            carbs: 176,
            fat: 54,
            primaryGap: "protein"
        )
    )
    suggestion.predictedScore = 8.6
    suggestion.scoreFactors = [
        SuggestionScoreFactor(name: "Protein balance", contribution: 1.4, detail: "35g high-quality protein"),
        SuggestionScoreFactor(name: "Whole foods", contribution: 1.0, detail: "Fresh vegetables & lean meat"),
        SuggestionScoreFactor(name: "Fiber content", contribution: 0.6, detail: "6g from greens"),
        SuggestionScoreFactor(name: "Caloric density", contribution: 0.4, detail: "Filling yet moderate")
    ]
    return suggestion
}

private func previewSuggestionNoScoreDetail() -> FoodSuggestion {
    FoodSuggestion(
        id: UUID(),
        name: "Grilled Chicken Salad",
        calories: 450,
        protein: 35.0,
        carbs: 20.0,
        fat: 22.0,
        foodGroup: .protein,
        reasoningShort: "Protein boost with vegetables you're missing",
        reasoningDetailed: "You've logged 16g of protein so far today, and your target is 130g. This salad provides 35g of high-quality protein from grilled chicken.",
        howYoullFeel: "The combination of lean protein and fiber-rich vegetables will keep you satisfied for 3-4 hours.",
        supportsGoal: "High-protein meals increase satiety hormones and help preserve muscle.",
        generatedAt: Date(),
        basedOnMacroGap: nil
    )
}

//
//  FoodSuggestionCard.swift
//  NutriSync
//
//  Individual food suggestion card for display in WhatToEatSection
//

import SwiftUI

struct FoodSuggestionCard: View {
    let suggestion: FoodSuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Food emoji
                Text(suggestion.emoji)
                    .font(.system(size: 24))
                    .frame(width: 32)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Name row with chevron
                    HStack {
                        Text(suggestion.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()

        VStack(spacing: 12) {
            FoodSuggestionCard(
                suggestion: FoodSuggestion(
                    id: UUID(),
                    name: "Grilled Chicken Salad",
                    calories: 450,
                    protein: 35.0,
                    carbs: 20.0,
                    fat: 22.0,
                    foodGroup: .protein,
                    reasoningShort: "Protein boost with vegetables you're missing",
                    reasoningDetailed: "You've logged 16g of protein so far today, and your target is 130g.",
                    howYoullFeel: "The combination of lean protein and fiber-rich vegetables will keep you satisfied.",
                    supportsGoal: "High-protein meals increase satiety hormones and help preserve muscle.",
                    generatedAt: Date(),
                    basedOnMacroGap: nil
                ),
                onTap: {}
            )

            FoodSuggestionCard(
                suggestion: FoodSuggestion(
                    id: UUID(),
                    name: "Salmon with Quinoa",
                    calories: 520,
                    protein: 40.0,
                    carbs: 35.0,
                    fat: 18.0,
                    foodGroup: .protein,
                    reasoningShort: "Omega-3s and complete protein for sustained energy",
                    reasoningDetailed: "Your morning was carb-focused with toast. This meal adds healthy omega-3 fats.",
                    howYoullFeel: "Omega-3 fatty acids support brain function and reduce inflammation.",
                    supportsGoal: "Fatty fish like salmon supports metabolic health.",
                    generatedAt: Date(),
                    basedOnMacroGap: nil
                ),
                onTap: {}
            )
        }
        .padding()
    }
}

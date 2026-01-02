//
//  InsightBox.swift
//  NutriSync
//
//  Container for displaying score insights and explanations.
//  Used to explain why a score was given and how to improve.
//

import SwiftUI

/// Displays insight text with optional title
struct InsightBox: View {
    let title: String
    let text: String
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                Text(title.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .tracking(0.5)
            }

            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.insightBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.insightBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Inline Insight

/// Compact single-line insight for banners and cards
struct InlineInsight: View {
    let text: String
    var style: Style = .neutral

    enum Style {
        case positive
        case negative
        case neutral

        var color: Color {
            switch self {
            case .positive: return .factorPositive
            case .negative: return .factorNegative
            case .neutral: return Color.white.opacity(0.6)
            }
        }

        var icon: String? {
            switch self {
            case .positive: return "arrow.up.right"
            case .negative: return "arrow.down.right"
            case .neutral: return nil
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let iconName = style.icon {
                Image(systemName: iconName)
                    .font(.system(size: 10, weight: .medium))
            }

            Text(text)
                .font(.system(size: 13))
                .lineLimit(1)
        }
        .foregroundStyle(style.color)
    }
}

// MARK: - Why This Score Section

/// Full section explaining score breakdown
struct WhyThisScoreSection: View {
    let title: String
    let factors: [FactorChipData]
    let insight: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.5))
                .tracking(0.5)

            FactorChipGrid(factors: factors)

            if let insightText = insight {
                InsightBox(title: "Insight", text: insightText)
            }
        }
    }
}

// MARK: - Preview

#Preview("Insight Box") {
    VStack(spacing: 16) {
        InsightBox(
            title: "Today's Insight",
            text: "Good food choices but portion control needs work. Your breakfast window was heavy - try spreading calories more evenly across your remaining windows."
        )

        InsightBox(
            title: "Insight",
            text: "This window exceeded all macro targets. Protein was closest to goal at 71%. Consider splitting the smoothie bowl across two windows for better adherence.",
            icon: "lightbulb"
        )
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

#Preview("Inline Insights") {
    VStack(alignment: .leading, spacing: 12) {
        InlineInsight(text: "On target", style: .positive)
        InlineInsight(text: "Over target by 67%", style: .negative)
        InlineInsight(text: "Protein goal met, calories exceeded", style: .neutral)
        InlineInsight(text: "Not started", style: .neutral)
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

#Preview("Why This Score Section") {
    WhyThisScoreSection(
        title: "Why This Score",
        factors: [
            FactorChipData(label: "Calories", value: -3.2, secondaryLabel: "167% of target"),
            FactorChipData(label: "Protein", value: -0.8, secondaryLabel: "71% of target"),
            FactorChipData(label: "Carbs", value: -1.5, secondaryLabel: "205% of target"),
            FactorChipData(label: "Fat", value: -0.6, secondaryLabel: "194% of target")
        ],
        insight: "This window exceeded all macro targets. Protein was closest to goal at 71%. Consider splitting the smoothie bowl across two windows for better adherence."
    )
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

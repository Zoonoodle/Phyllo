//
//  FactorChip.swift
//  NutriSync
//
//  Rectangular chip displaying a score factor's contribution.
//  Shows the factor name, optional secondary info, and +/- value.
//

import SwiftUI

/// Displays a factor's contribution to a score
struct FactorChip: View {
    let label: String
    let value: Double  // Positive or negative contribution
    var secondaryLabel: String? = nil  // e.g., "167% of target"

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(1)

            if let secondary = secondaryLabel {
                Text(secondary)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(1)
            }

            Text(formattedValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minWidth: 140, alignment: .leading)
        .background(Color.chipBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.chipBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var formattedValue: String {
        if abs(value) < 0.05 {
            return "0.0"
        } else if value > 0 {
            return String(format: "+%.1f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private var valueColor: Color {
        if abs(value) < 0.05 {
            return .factorNeutral
        } else if value > 0 {
            return .factorPositive
        } else {
            return .factorNegative
        }
    }
}

// MARK: - Window Adherence Chip

/// Specialized chip for window macro adherence
struct AdherenceChip: View {
    let macroName: String  // "Calories", "Protein", etc.
    let actual: Int
    let target: Int
    let contribution: Double

    var body: some View {
        FactorChip(
            label: macroName,
            value: contribution,
            secondaryLabel: adherenceText
        )
    }

    private var adherenceText: String {
        guard target > 0 else { return "No target" }
        let percentage = Int((Double(actual) / Double(target)) * 100)
        return "\(percentage)% of target"
    }
}

// MARK: - Factor Chip Grid

/// Displays multiple factor chips in a 2-column grid
struct FactorChipGrid: View {
    let factors: [FactorChipData]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(factors) { factor in
                FactorChip(
                    label: factor.label,
                    value: factor.value,
                    secondaryLabel: factor.secondaryLabel
                )
            }
        }
    }
}

/// Data model for factor chip grid
struct FactorChipData: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    var secondaryLabel: String? = nil
}

// MARK: - Preview

#Preview("Factor Chips") {
    VStack(spacing: 16) {
        Text("Individual Chips").font(.caption).foregroundStyle(.secondary)

        HStack(spacing: 12) {
            FactorChip(label: "Protein balance", value: 1.4)
            FactorChip(label: "Whole foods", value: 1.0)
        }

        HStack(spacing: 12) {
            FactorChip(label: "Fiber content", value: -0.6)
            FactorChip(label: "Caloric density", value: 0.3)
        }

        HStack(spacing: 12) {
            FactorChip(label: "Neutral factor", value: 0.0)
        }
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

#Preview("Adherence Chips") {
    VStack(spacing: 16) {
        Text("Window Adherence").font(.caption).foregroundStyle(.secondary)

        HStack(spacing: 12) {
            AdherenceChip(macroName: "Calories", actual: 833, target: 500, contribution: -3.2)
            AdherenceChip(macroName: "Protein", actual: 35, target: 50, contribution: -0.8)
        }

        HStack(spacing: 12) {
            AdherenceChip(macroName: "Carbs", actual: 102, target: 50, contribution: -1.5)
            AdherenceChip(macroName: "Fat", actual: 38, target: 20, contribution: -0.6)
        }
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

#Preview("Factor Grid") {
    FactorChipGrid(factors: [
        FactorChipData(label: "Protein balance", value: 1.4),
        FactorChipData(label: "Whole foods", value: 1.0),
        FactorChipData(label: "Fiber content", value: -0.6),
        FactorChipData(label: "Caloric density", value: 0.3)
    ])
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

//
//  ScoreProgressBar.swift
//  NutriSync
//
//  Horizontal progress bar for displaying score as a percentage.
//  Used in meal analysis, window detail, and daily score views.
//

import SwiftUI

/// Horizontal progress bar showing score as percentage fill
struct ScoreProgressBar: View {
    let progress: Double  // 0-1 scale (e.g., 0.86 for 86%)
    var height: CGFloat = 6
    var showPercentage: Bool = true
    var useScoreColor: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: height)

                    // Filled progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(fillColor)
                        .frame(width: max(0, min(geometry.size.width, geometry.size.width * progress)), height: height)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: height)

            if showPercentage {
                Text(percentageText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }

    private var fillColor: Color {
        guard useScoreColor else {
            return .nutriSyncAccent
        }
        // Convert progress (0-1) to score (0-10)
        let score = progress * 10
        return Color.scoreColor(for: score)
    }

    private var percentageText: String {
        let percentage = Int(progress * 100)
        return "(\(percentage)%)"
    }
}

// MARK: - Convenience Initializers

extension ScoreProgressBar {
    /// Create from 0-10 score
    static func fromScore(_ score: Double, height: CGFloat = 6, showPercentage: Bool = true) -> ScoreProgressBar {
        ScoreProgressBar(
            progress: score / 10.0,
            height: height,
            showPercentage: showPercentage
        )
    }

    /// Create from 0-100 internal score
    static func fromInternal(_ internalScore: Int, height: CGFloat = 6, showPercentage: Bool = true) -> ScoreProgressBar {
        ScoreProgressBar(
            progress: Double(internalScore) / 100.0,
            height: height,
            showPercentage: showPercentage
        )
    }
}

// MARK: - Preview

#Preview("Progress Bars") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Excellent (86%)").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.86)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Good (75%)").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.75)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Okay (55%)").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.55)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Poor (39%)").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.39)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Bad (20%)").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.20)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("No percentage").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.72, showPercentage: false)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Taller bar (10pt)").font(.caption).foregroundStyle(.secondary)
            ScoreProgressBar(progress: 0.80, height: 10)
        }
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

#Preview("Combined Score Display") {
    VStack(alignment: .leading, spacing: 8) {
        ScoreText(score: 8.6, size: .medium, showTotal: true)
        ScoreProgressBar.fromScore(8.6)
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

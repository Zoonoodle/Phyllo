//
//  ScoreText.swift
//  NutriSync
//
//  Unified score text display component for 1-10 scale scores.
//  Used across meal cards, window banners, and detail views.
//

import SwiftUI

/// Displays a score on the 1-10 scale with appropriate styling
struct ScoreText: View {
    let score: Double  // 0-10 scale
    var size: ScoreSize = .medium
    var showTotal: Bool = false  // Shows "/ 10" suffix
    var useScoreColor: Bool = true  // Color based on score value

    enum ScoreSize {
        case small   // 14pt - inline in cards
        case medium  // 24pt - section headers
        case large   // 36pt - hero display

        var fontSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 24
            case .large: return 36
            }
        }

        var fontWeight: Font.Weight {
            switch self {
            case .small: return .semibold
            case .medium, .large: return .bold
            }
        }

        var totalFontSize: CGFloat {
            switch self {
            case .small: return 11
            case .medium: return 16
            case .large: return 20
            }
        }
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(formattedScore)
                .font(.system(size: size.fontSize, weight: size.fontWeight, design: .rounded))
                .foregroundStyle(scoreColor)

            if showTotal {
                Text("/ 10")
                    .font(.system(size: size.totalFontSize, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
    }

    private var formattedScore: String {
        if score <= 0 {
            return "--"
        }
        return String(format: "%.1f", score)
    }

    private var scoreColor: Color {
        guard useScoreColor else {
            return .white.opacity(0.9)
        }
        return Color.scoreColor(for: score)
    }
}

// MARK: - Convenience Initializers

extension ScoreText {
    /// Create from 0-100 internal score (converts to 0-10 display)
    static func fromInternal(_ internalScore: Int, size: ScoreSize = .medium, showTotal: Bool = false) -> ScoreText {
        ScoreText(
            score: Double(internalScore) / 10.0,
            size: size,
            showTotal: showTotal
        )
    }
}

// MARK: - Preview

#Preview("Score Sizes") {
    VStack(spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
            Text("Small (inline)").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ScoreText(score: 8.6, size: .small)
                ScoreText(score: 5.2, size: .small)
                ScoreText(score: 3.1, size: .small)
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Medium (section header)").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ScoreText(score: 9.2, size: .medium)
                ScoreText(score: 7.5, size: .medium, showTotal: true)
            }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Large (hero)").font(.caption).foregroundStyle(.secondary)
            ScoreText(score: 8.6, size: .large, showTotal: true)
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Empty state").font(.caption).foregroundStyle(.secondary)
            ScoreText(score: 0, size: .medium, showTotal: true)
        }
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

#Preview("All Score Ranges") {
    VStack(spacing: 12) {
        ForEach([9.5, 8.0, 6.5, 4.0, 2.0], id: \.self) { score in
            HStack {
                ScoreText(score: score, size: .medium, showTotal: true)
                Spacer()
                Text(scoreLabel(for: score))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    .padding(24)
    .background(Color.nutriSyncBackground)
    .preferredColorScheme(.dark)
}

private func scoreLabel(for score: Double) -> String {
    switch score {
    case 8.5...10.0: return "Excellent"
    case 7.0..<8.5: return "Good"
    case 5.0..<7.0: return "Okay"
    case 3.0..<5.0: return "Poor"
    default: return "Needs Work"
    }
}

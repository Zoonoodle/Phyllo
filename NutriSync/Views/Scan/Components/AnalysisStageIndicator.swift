//
//  AnalysisStageIndicator.swift
//  NutriSync
//
//  Created by Claude on 2025-10-16.
//

import SwiftUI

// MARK: - Analysis Stage Mapping
extension MealAnalysisAgent.AnalysisTool {
    var stageIndex: Int {
        switch self {
        case .initial: return 0
        case .brandSearch: return 1
        case .deepAnalysis: return 2
        case .nutritionLookup: return 3
        }
    }
}

// MARK: - Stage Indicator View
struct AnalysisStageIndicator: View {
    let currentStage: Int  // 0-4 (5 total stages)
    let color: Color
    let isCompleted: Bool

    private let totalStages = 5
    private let dotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 4

    init(tool: MealAnalysisAgent.AnalysisTool?, color: Color = .green, isCompleted: Bool = false) {
        if isCompleted {
            self.currentStage = 5  // All stages complete
        } else if let tool = tool {
            self.currentStage = tool.stageIndex + 1  // +1 because we're showing progress through the stage
        } else {
            self.currentStage = 0
        }
        self.color = color
        self.isCompleted = isCompleted
    }

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<totalStages, id: \.self) { index in
                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(isActive(index) ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStage)
            }
        }
        .padding(.vertical, 4)
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentStage {
            // Completed stages - full color
            return color
        } else if index == currentStage && !isCompleted {
            // Current stage - pulsing
            return color.opacity(0.6)
        } else {
            // Future stages - dim
            return color.opacity(0.2)
        }
    }

    private func isActive(_ index: Int) -> Bool {
        return index == currentStage && !isCompleted
    }
}

// MARK: - Preview
struct AnalysisStageIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Stage 0: Initial
            VStack {
                Text("Initial Analysis")
                AnalysisStageIndicator(tool: .initial, color: .green)
            }

            // Stage 1: Brand Search
            VStack {
                Text("Brand Search")
                AnalysisStageIndicator(tool: .brandSearch, color: .blue)
            }

            // Stage 2: Deep Analysis
            VStack {
                Text("Deep Analysis")
                AnalysisStageIndicator(tool: .deepAnalysis, color: .orange)
            }

            // Stage 3: Nutrition Lookup
            VStack {
                Text("Nutrition Lookup")
                AnalysisStageIndicator(tool: .nutritionLookup, color: .purple)
            }

            // Completed
            VStack {
                Text("Completed")
                AnalysisStageIndicator(tool: nil, color: .green, isCompleted: true)
            }
        }
        .padding()
        .background(Color(hex: "0a0a0a"))
    }
}

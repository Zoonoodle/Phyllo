//
//  MealAnalysisProgressRing.swift
//  NutriSync
//
//  Created by Claude on 2025-09-03.
//

import SwiftUI

struct MealAnalysisProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat // 50, 80, or custom
    let color: Color // Window purpose color
    let showPercentage: Bool = true // Always show percentage for meal analysis
    let lineWidth: CGFloat = 2
    
    var body: some View {
        ZStack {
            // Background ring with open bottom (76% of circle)
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(90))
            
            // Progress fill
            Circle()
                .trim(from: 0, to: progress * 0.76)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(126))
                .animation(.linear(duration: 1), value: progress)
            
            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(fontSize(for: size))
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
    }
    
    private func fontSize(for size: CGFloat) -> Font {
        switch size {
        case 0..<60:
            return TimelineTypography.progressPercentage // Size 15 for small (50px)
        case 60..<100:
            return .system(size: 20, weight: .bold) // Size 20 for medium (80px)
        default:
            return .system(size: 28, weight: .bold) // Size 28 for large (120px+)
        }
    }
}

// Preview
struct MealAnalysisProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Small inline version (50x50)
            MealAnalysisProgressRing(
                progress: 0.31,
                size: 50,
                color: .green
            )
            
            // Medium card version (80x80)
            MealAnalysisProgressRing(
                progress: 0.67,
                size: 80,
                color: .blue
            )
            
            // Large version (120x120)
            MealAnalysisProgressRing(
                progress: 0.89,
                size: 120,
                color: .orange
            )
        }
        .padding()
        .background(Color.black)
    }
}
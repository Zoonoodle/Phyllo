//
//  MacroBalanceCard.swift
//  NutriSync
//
//  Minimal editorial macro balance display for Momentum tab
//

import SwiftUI

struct MacroBalanceCard: View {
    let protein: Int
    let proteinTarget: Int
    let carbs: Int
    let carbsTarget: Int
    let fat: Int
    let fatTarget: Int
    let periodLabel: String

    private var overallScore: Int {
        let proteinScore = proteinTarget > 0 ? min(Double(protein) / Double(proteinTarget), 1.2) : 0
        let carbsScore = carbsTarget > 0 ? min(Double(carbs) / Double(carbsTarget), 1.2) : 0
        let fatScore = fatTarget > 0 ? min(Double(fat) / Double(fatTarget), 1.2) : 0

        // Penalize over/under consumption
        let proteinAccuracy = 1.0 - abs(1.0 - proteinScore)
        let carbsAccuracy = 1.0 - abs(1.0 - carbsScore)
        let fatAccuracy = 1.0 - abs(1.0 - fatScore)

        let averageAccuracy = (proteinAccuracy + carbsAccuracy + fatAccuracy) / 3.0
        return Int(averageAccuracy * 100)
    }

    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header with title and overall score
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MACRO BALANCE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(0.8)

                        Text(periodLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    Spacer()

                    // Overall percentage
                    Text("\(overallScore)%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)
                        .contentTransition(.numericText())
                }

                // Macro bars
                VStack(spacing: 12) {
                    MacroRow(
                        name: "Protein",
                        current: protein,
                        target: proteinTarget,
                        color: Color.blue.opacity(0.8)
                    )

                    MacroRow(
                        name: "Carbs",
                        current: carbs,
                        target: carbsTarget,
                        color: Color.green.opacity(0.8)
                    )

                    MacroRow(
                        name: "Fat",
                        current: fat,
                        target: fatTarget,
                        color: Color.yellow.opacity(0.8)
                    )
                }
            }
        }
    }

    private var scoreColor: Color {
        switch overallScore {
        case 0..<40: return .red.opacity(0.7)
        case 40..<60: return .orange.opacity(0.7)
        case 60..<80: return .yellow.opacity(0.7)
        default: return PerformanceDesignSystem.successMuted
        }
    }
}

// MARK: - Macro Row

private struct MacroRow: View {
    let name: String
    let current: Int
    let target: Int
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    private var percentage: Int {
        guard target > 0 else { return 0 }
        return Int((Double(current) / Double(target)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text("\(current)g / \(target)g")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MacroBalanceCard(
            protein: 95,
            proteinTarget: 120,
            carbs: 180,
            carbsTarget: 200,
            fat: 55,
            fatTarget: 65,
            periodLabel: "This Week"
        )

        MacroBalanceCard(
            protein: 45,
            proteinTarget: 120,
            carbs: 80,
            carbsTarget: 200,
            fat: 25,
            fatTarget: 65,
            periodLabel: "Today"
        )
    }
    .padding()
    .background(Color.nutriSyncBackground)
}

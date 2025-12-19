//
//  StreakCard.swift
//  NutriSync
//
//  Large editorial streak display for Momentum tab
//

import SwiftUI

struct StreakCard: View {
    let currentStreak: Int
    let bestStreak: Int

    var body: some View {
        PerformanceCard {
            HStack(spacing: 0) {
                // Left: Current streak (large editorial number)
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONSISTENCY STREAK")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(0.8)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(currentStreak)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.nutriSyncAccent)
                            .contentTransition(.numericText())

                        Text("days")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }

                    // Motivational message based on streak
                    Text(streakMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Right: Best streak (secondary)
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 28))
                        .foregroundColor(currentStreak > 0 ? .orange.opacity(0.8) : .white.opacity(0.2))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Best")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        Text("\(bestStreak)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var streakMessage: String {
        switch currentStreak {
        case 0:
            return "Start your streak today"
        case 1:
            return "Great start! Keep it going"
        case 2...6:
            return "Building momentum"
        case 7...13:
            return "One week strong!"
        case 14...29:
            return "Two weeks of consistency"
        case 30...59:
            return "A month of dedication"
        case 60...89:
            return "Two months! Incredible"
        default:
            return "You're unstoppable!"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StreakCard(currentStreak: 14, bestStreak: 21)
        StreakCard(currentStreak: 0, bestStreak: 7)
        StreakCard(currentStreak: 45, bestStreak: 45)
    }
    .padding()
    .background(Color.nutriSyncBackground)
}

//
//  QuickStatsGrid.swift
//  NutriSync
//
//  Quick stats grid for Performance tab
//

import SwiftUI

struct QuickStatsGrid: View {
    let streak: Int
    let fastingHours: Double
    let weeklyAverage: Double
    let trend: ProgressTimelineViewModel.TrendDirection
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                icon: "flame.fill",
                title: "STREAK",
                value: "\(streak) days",
                color: .orange
            )
            
            StatCard(
                icon: "timer",
                title: "FASTING",
                value: formatFastingTime(fastingHours),
                color: Color(hex: "AF52DE")
            )
            
            StatCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "WEEKLY AVG",
                value: "\(Int(weeklyAverage))%",
                color: Color(hex: "007AFF")
            )
            
            StatCard(
                icon: trend.icon,
                title: "TREND",
                value: trend.text,
                color: trend.color
            )
        }
    }
    
    private func formatFastingTime(_ hours: Double) -> String {
        if hours < 1 {
            let minutes = Int(hours * 60)
            return "\(minutes)m"
        } else {
            let h = Int(hours)
            let m = Int((hours - Double(h)) * 60)
            if m > 0 {
                return "\(h)h \(m)m"
            } else {
                return "\(h)h"
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.nutriSyncElevated)
        .cornerRadius(12)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        QuickStatsGrid(
            streak: 7,
            fastingHours: 14.5,
            weeklyAverage: 72.5,
            trend: .improving
        )
        .padding()
    }
}
//
//  QuickStatsGrid.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct QuickStatsGrid: View {
    @StateObject private var mockData = MockDataManager.shared
    @State private var animateValues = false
    
    var body: some View {
        SimplePhylloCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Key Metrics")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                // 2x2 Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickStatItem(
                        icon: "bolt.fill",
                        iconColor: .yellow,
                        title: "Avg Energy",
                        value: "6.8",
                        unit: "/10",
                        trend: .up(12),
                        animateValue: animateValues
                    )
                    
                    QuickStatItem(
                        icon: "moon.fill",
                        iconColor: .purple,
                        title: "Sleep Quality",
                        value: "7.2",
                        unit: "/10",
                        trend: .down(5),
                        animateValue: animateValues
                    )
                    
                    QuickStatItem(
                        icon: "scalemass",
                        iconColor: .blue,
                        title: "Weight",
                        value: String(format: "%.1f", mockData.currentWeight),
                        unit: "kg",
                        trend: .down(2),
                        animateValue: animateValues
                    )
                    
                    QuickStatItem(
                        icon: "target",
                        iconColor: .phylloAccent,
                        title: "Goal Progress",
                        value: "73",
                        unit: "%",
                        trend: .up(9),
                        animateValue: animateValues
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                animateValues = true
            }
        }
    }
}

struct QuickStatItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let trend: TrendDirection
    let animateValue: Bool
    
    @State private var displayValue: Double = 0
    
    enum TrendDirection {
        case up(Int)
        case down(Int)
        case neutral
        
        var color: Color {
            switch self {
            case .up: return .phylloAccent
            case .down: return .red
            case .neutral: return .phylloTextSecondary
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var value: String {
            switch self {
            case .up(let val): return "+\(val)%"
            case .down(let val): return "-\(val)%"
            case .neutral: return "0%"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Title
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.2))
                    .cornerRadius(6)
                
                Spacer()
                
                // Trend
                HStack(spacing: 2) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(trend.value)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(trend.color)
            }
            
            // Title
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
            
            // Value
            HStack(alignment: .bottom, spacing: 2) {
                if animateValue {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("--")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.phylloTextSecondary)
                    .offset(y: -2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack {
        QuickStatsGrid()
            .padding()
        
        Spacer()
    }
    .background(Color.phylloBackground)
    .preferredColorScheme(.dark)
}
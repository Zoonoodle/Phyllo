//
//  PerformancePillarMiniCard.swift
//  NutriSync
//
//  Mini card version of performance pillars for hero section
//

import SwiftUI

struct PerformancePillarMiniCard: View {
    let title: String
    let percentage: Double
    let color: Color
    let detail: String
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(percentage))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color.opacity(0.8))
                            .frame(width: geometry.size.width * percentage / 100)
                            .animation(.easeInOut(duration: 0.3), value: percentage)
                    }
                }
                .frame(height: 6)
                
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
        }
        .frame(height: 100)
    }
}
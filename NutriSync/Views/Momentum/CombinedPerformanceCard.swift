//
//  CombinedPerformanceCard.swift
//  NutriSync
//
//  Combined performance card showing all three metrics in one card
//

import SwiftUI

struct CombinedPerformanceCard: View {
    struct Metric {
        let title: String
        let percentage: Double
        let color: Color
        let detail: String
        let onTap: (() -> Void)?
    }
    
    let timing: Metric
    let nutrients: Metric
    let adherence: Metric
    
    @State private var tappedMetric: String? = nil
    
    var body: some View {
        PerformanceCard {
            VStack(spacing: 0) {
                // Timing metric
                metricRow(timing)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Nutrients metric
                metricRow(nutrients)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                // Adherence metric
                metricRow(adherence)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: tappedMetric)
    }
    
    private func metricRow(_ metric: Metric) -> some View {
        HStack(spacing: 16) {
            // Left side: Title and detail
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(metric.detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Right side: Progress and percentage
            HStack(spacing: 12) {
                // Progress bar (horizontal)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [metric.color, metric.color.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * min(metric.percentage / 100, 1.0))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: metric.percentage)
                    }
                }
                .frame(width: 100, height: 8)
                
                // Percentage
                Text("\(Int(metric.percentage))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(metric.color)
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }
        }
        .contentShape(Rectangle())
        .scaleEffect(tappedMetric == metric.title ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                tappedMetric = metric.title
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    tappedMetric = nil
                }
                metric.onTap?()
            }
        }
    }
}

// Preview
#Preview {
    CombinedPerformanceCard(
        timing: .init(
            title: "Timing",
            percentage: 75,
            color: .green,
            detail: "On track today",
            onTap: nil
        ),
        nutrients: .init(
            title: "Nutrients", 
            percentage: 45,
            color: .orange,
            detail: "Building diversity",
            onTap: nil
        ),
        adherence: .init(
            title: "Adherence",
            percentage: 90,
            color: .blue,
            detail: "Strong week",
            onTap: nil
        )
    )
    .padding()
    .background(Color.black)
}
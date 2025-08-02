//
//  PhylloScoreMini.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  Compact PhylloScore display for story chapters

import SwiftUI

struct PhylloScoreMini: View {
    let score: Int
    let trend: InsightsEngine.ScoreTrend?
    let showLabel: Bool
    let animate: Bool
    
    @State private var displayedScore: Int = 0
    @State private var pulseAnimation = false
    
    init(score: Int, trend: InsightsEngine.ScoreTrend? = nil, showLabel: Bool = true, animate: Bool = true) {
        self.score = score
        self.trend = trend
        self.showLabel = showLabel
        self.animate = animate
    }
    
    private var scoreColor: Color {
        if score >= 80 { return .green }
        else if score >= 60 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Score Circle
            ZStack {
                // Background circle with subtle animation
                Circle()
                    .stroke(scoreColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: CGFloat(displayedScore) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: displayedScore)
                
                // Score value
                Text("\(displayedScore)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
            
            if showLabel {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PhylloScore")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let trend = trend {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.system(size: 12))
                                .foregroundColor(trend.color)
                            
                            Text(trend.description)
                                .font(.system(size: 12))
                                .foregroundColor(.phylloTextSecondary)
                        }
                    } else {
                        Text("Starting point")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
        }
        .onAppear {
            if animate {
                // Animate score counting up
                withAnimation(.easeOut(duration: 1.0)) {
                    displayedScore = score
                }
                
                // Start pulse animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    pulseAnimation = true
                }
            } else {
                displayedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                displayedScore = newValue
            }
        }
    }
}

// MARK: - Score Comparison View

struct PhylloScoreComparison: View {
    let startScore: Int
    let currentScore: Int
    let daysElapsed: Int
    
    private var improvement: Int {
        currentScore - startScore
    }
    
    private var improvementPercent: Double {
        guard startScore > 0 else { return 0 }
        return Double(improvement) / Double(startScore) * 100
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                // Start score
                VStack(spacing: 8) {
                    Text("Day 1")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    
                    PhylloScoreMini(score: startScore, showLabel: false)
                    
                    Text("Starting")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                }
                
                // Arrow with improvement
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.phylloTextTertiary)
                    
                    Text("+\(improvement)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                
                // Current score
                VStack(spacing: 8) {
                    Text("Day \(daysElapsed)")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    
                    PhylloScoreMini(score: currentScore, showLabel: false)
                    
                    Text("Current")
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                }
            }
            
            // Improvement summary
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("\(Int(improvementPercent))% improvement")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

#Preview("PhylloScoreMini") {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 32) {
            PhylloScoreMini(score: 42)
            
            PhylloScoreMini(score: 75, trend: .improving)
            
            PhylloScoreMini(score: 85, trend: .stable, showLabel: false)
            
            PhylloScoreComparison(startScore: 42, currentScore: 75, daysElapsed: 7)
        }
        .padding()
    }
}
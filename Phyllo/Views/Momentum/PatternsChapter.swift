//
//  PatternsChapter.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  The patterns chapter showing AI-discovered correlations

import SwiftUI

struct PatternsChapter: View {
    @Binding var animateContent: Bool
    @Binding var expandedInsight: String?
    let scoreBreakdown: InsightsEngine.ScoreBreakdown?
    let micronutrientStatus: InsightsEngine.MicronutrientStatus?
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Chapter Title
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Unique Patterns")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                
                Text("After 14 days, we've discovered patterns unique to your body.")
                    .font(.system(size: 18))
                    .foregroundColor(.phylloTextSecondary)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.8).delay(0.2), value: animateContent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Score Evolution Pattern
            if let score = scoreBreakdown {
                VStack(spacing: 16) {
                    SectionHeader(title: "PhylloScore Patterns", icon: "chart.line.uptrend.xyaxis")
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Pattern 1: Best scoring days
                        PatternCard(
                            title: "Your Best Days",
                            pattern: "PhylloScore peaks on days with morning protein",
                            insight: "Starting with 30g+ protein before 9 AM correlates with 15-point higher scores",
                            icon: "sunrise.fill",
                            color: .orange
                        )
                        
                        // Pattern 2: Window timing
                        PatternCard(
                            title: "Window Timing Impact",
                            pattern: "3-hour meal windows optimize your energy",
                            insight: "Eating within 3-hour windows shows 22% better macro balance scores",
                            icon: "clock.fill",
                            color: .purple
                        )
                        
                        // Current score context
                        HStack(spacing: 16) {
                            PhylloScoreMini(score: score.totalScore, trend: score.trend, showLabel: false)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Score")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextSecondary)
                                
                                Text("Following your patterns")
                                    .font(.system(size: 12))
                                    .foregroundColor(.phylloTextTertiary)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.3), value: animateContent)
            }
            
            // Micronutrient Patterns
            if let microStatus = micronutrientStatus {
                VStack(spacing: 16) {
                    SectionHeader(title: "Micronutrient Insights", icon: "leaf.fill")
                    
                    VStack(spacing: 12) {
                        // Pattern 1: Best sources
                        PatternCard(
                            title: "Your Best Sources",
                            pattern: "Lunch windows provide 60% of daily vitamins",
                            insight: "Your 12-2 PM meals consistently deliver the most micronutrients",
                            icon: "sun.max.fill",
                            color: .green
                        )
                        
                        // Pattern 2: Common gaps
                        if !microStatus.topDeficiencies.isEmpty {
                            PatternCard(
                                title: "Consistent Gaps",
                                pattern: "\(microStatus.topDeficiencies.first?.nutrient.name ?? "Vitamin D") tends to be low",
                                insight: "Consider supplementation or targeted food choices for this nutrient",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.8).delay(0.4), value: animateContent)
            }
            
            // Energy Correlation
            VStack(spacing: 16) {
                SectionHeader(title: "Energy Correlations", icon: "bolt.fill")
                
                EnergyCorrelationView()
                    .opacity(animateContent ? 1 : 0)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .animation(.spring(response: 0.8).delay(0.5), value: animateContent)
            }
            
            // Personalized Recommendations
            VStack(spacing: 16) {
                SectionHeader(title: "Your Optimization Plan", icon: "sparkles")
                
                VStack(spacing: 12) {
                    RecommendationCard(
                        title: "Morning Protocol",
                        recommendation: "Start with 30g protein before 9 AM",
                        expectedResult: "+15 PhylloScore points",
                        priority: .high
                    )
                    
                    RecommendationCard(
                        title: "Window Timing",
                        recommendation: "Keep meals within 3-hour windows",
                        expectedResult: "22% better macro balance",
                        priority: .medium
                    )
                    
                    if let firstDeficiency = micronutrientStatus?.topDeficiencies.first {
                        RecommendationCard(
                            title: "Nutrient Focus",
                            recommendation: "Add \(firstDeficiency.nutrient.name)-rich foods",
                            expectedResult: "Address primary deficiency",
                            priority: .medium
                        )
                    }
                }
            }
            .opacity(animateContent ? 1 : 0)
            .offset(y: animateContent ? 0 : 20)
            .animation(.spring(response: 0.8).delay(0.6), value: animateContent)
        }
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let title: String
    let pattern: String
    let insight: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.2))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(pattern)
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                }
                
                Spacer()
            }
            
            Text(insight)
                .font(.system(size: 13))
                .foregroundColor(.phylloTextTertiary)
                .padding(.leading, 48)
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
}

// MARK: - Energy Correlation View

struct EnergyCorrelationView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Mock correlation data
            HStack(spacing: 20) {
                CorrelationStat(
                    label: "Morning Protein",
                    correlation: "+68%",
                    impact: "energy",
                    color: .green
                )
                
                CorrelationStat(
                    label: "Late Eating",
                    correlation: "-42%",
                    impact: "sleep",
                    color: .red
                )
                
                CorrelationStat(
                    label: "Hydration",
                    correlation: "+35%",
                    impact: "focus",
                    color: .blue
                )
            }
            
            Text("Based on 14 days of your data")
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CorrelationStat: View {
    let label: String
    let correlation: String
    let impact: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(correlation)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(impact)
                .font(.system(size: 11))
                .foregroundColor(.phylloTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let title: String
    let recommendation: String
    let expectedResult: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return .red
            case .medium: return .orange
            case .low: return .yellow
            }
        }
        
        var label: String {
            switch self {
            case .high: return "High Impact"
            case .medium: return "Medium Impact"
            case .low: return "Low Impact"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            VStack {
                Circle()
                    .fill(priority.color)
                    .frame(width: 8, height: 8)
                Spacer()
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(priority.label)
                        .font(.system(size: 11))
                        .foregroundColor(priority.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(priority.color.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Text(recommendation)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text(expectedResult)
                        .font(.system(size: 13))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        ScrollView {
            PatternsChapter(
                animateContent: .constant(true),
                expandedInsight: .constant(nil),
                scoreBreakdown: InsightsEngine.ScoreBreakdown(
                    totalScore: 75,
                    mealTimingScore: 20,
                    macroBalanceScore: 18,
                    micronutrientScore: 22,
                    consistencyScore: 15,
                    trend: .improving
                ),
                micronutrientStatus: InsightsEngine.MicronutrientStatus(
                    nutrients: [],
                    topDeficiencies: [
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Vitamin D", unit: "mcg", rda: 20.0),
                            consumed: 5.0,
                            percentageOfRDA: 25.0,
                            status: .deficient
                        )
                    ],
                    wellSupplied: []
                )
            )
            .padding()
        }
    }
}
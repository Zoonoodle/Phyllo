//
//  NutritionDashboardInsightsView.swift
//  NutriSync
//
//  INSIGHTS View - AI-powered nutrition insights
//

import SwiftUI

struct NutritionDashboardInsightsView: View {
    @ObservedObject var viewModel: NutritionDashboardViewModel
    @ObservedObject var insightsEngine: InsightsEngine
    
    var body: some View {
        VStack(spacing: 20) {
            if insights.isEmpty {
                emptyInsightsView
            } else {
                ForEach(insights) { insight in
                    InsightCard(insight: insight)
                }
            }
            
            // Generate insights button
            generateInsightsButton
        }
    }
    
    // MARK: - Empty State
    
    private var emptyInsightsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple.opacity(0.6))
            
            Text("No insights yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Complete more meals and check-ins to unlock personalized insights")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    // MARK: - Generate Button
    
    private var generateInsightsButton: some View {
        Button(action: { 
            // Insights are generated automatically by the ViewModel
            // This button is just a placeholder for now
        }) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 16))
                
                Text("Generate New Insights")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.nutriSyncAccent)
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var insights: [NutritionDashboardViewModel.NutritionInsight] { viewModel.insights }
}

// MARK: - Insight Card Component

struct InsightCard: View {
    let insight: NutritionDashboardViewModel.NutritionInsight
    
    private var insightIcon: String {
        switch insight.type {
        case .positive: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .suggestion: return "lightbulb.fill"
        case .trend: return "chart.line.uptrend.xyaxis"
        }
    }
    
    private var insightColor: Color {
        switch insight.type {
        case .positive: return .green
        case .warning: return .orange
        case .suggestion: return .blue
        case .trend: return .purple
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insightIcon)
                    .font(.system(size: 24))
                    .foregroundColor(insightColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(insight.message)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(insightColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
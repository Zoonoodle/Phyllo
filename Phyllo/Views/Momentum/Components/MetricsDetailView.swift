//
//  MetricsDetailView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct MetricsDetailView: View {
    @StateObject private var mockData = MockDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange = TimeRange.week
    @State private var animateValues = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Time Range Selector
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Primary Metrics Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MetricCard(
                                icon: "bolt.fill",
                                iconColor: .yellow,
                                title: "Avg Energy",
                                value: "6.8",
                                unit: "/10",
                                trend: .up(12),
                                animateValue: animateValues
                            )
                            
                            MetricCard(
                                icon: "moon.fill",
                                iconColor: .purple,
                                title: "Sleep Quality",
                                value: "7.2",
                                unit: "/10",
                                trend: .down(5),
                                animateValue: animateValues
                            )
                            
                            MetricCard(
                                icon: "scalemass",
                                iconColor: .blue,
                                title: "Weight",
                                value: String(format: "%.1f", mockData.currentWeight),
                                unit: "kg",
                                trend: .down(2),
                                animateValue: animateValues
                            )
                            
                            MetricCard(
                                icon: "target",
                                iconColor: .phylloAccent,
                                title: "Goal Progress",
                                value: "73",
                                unit: "%",
                                trend: .up(9),
                                animateValue: animateValues
                            )
                        }
                        .padding(.horizontal)
                        
                        // Secondary Metrics
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nutrition Metrics")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                DetailedMetricRow(
                                    title: "Calorie Accuracy",
                                    value: 92,
                                    description: "How close to daily target"
                                )
                                
                                DetailedMetricRow(
                                    title: "Protein Consistency",
                                    value: 87,
                                    description: "Daily protein goal achievement"
                                )
                                
                                DetailedMetricRow(
                                    title: "Meal Timing",
                                    value: 78,
                                    description: "Eating within optimal windows"
                                )
                                
                                DetailedMetricRow(
                                    title: "Hydration",
                                    value: 65,
                                    description: "Daily water intake goals"
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Streak Information
                        HStack(spacing: 20) {
                            VStack(spacing: 8) {
                                Text("\(mockData.currentStreak)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.phylloAccent)
                                Text("Current Streak")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.phylloElevated)
                            .cornerRadius(16)
                            
                            VStack(spacing: 8) {
                                Text("\(mockData.bestStreak)")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                Text("Best Streak")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.phylloElevated)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Metrics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.phylloAccent)
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

struct MetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let trend: QuickStatItem.TrendDirection
    let animateValue: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.2))
                    .cornerRadius(8)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(trend.value)
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(trend.color)
            }
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.phylloTextTertiary)
            
            HStack(alignment: .bottom, spacing: 2) {
                if animateValue {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("--")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Text(unit)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.phylloTextSecondary)
                    .offset(y: -2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.phylloElevated)
        .cornerRadius(16)
    }
}

struct DetailedMetricRow: View {
    let title: String
    let value: Int
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                }
                
                Spacer()
                
                Text("\(value)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(colorForPercentage(value))
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorForPercentage(value))
                        .frame(width: geometry.size.width * CGFloat(value) / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
    
    private func colorForPercentage(_ percentage: Int) -> Color {
        if percentage < 40 {
            return .red
        } else if percentage < 70 {
            return .orange
        } else {
            return .phylloAccent
        }
    }
}

#Preview {
    MetricsDetailView()
        .preferredColorScheme(.dark)
}
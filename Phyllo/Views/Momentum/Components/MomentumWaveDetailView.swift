//
//  MomentumWaveDetailView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct MomentumWaveDetailView: View {
    @StateObject private var mockData = MockDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedDay: Int? = nil
    @State private var animateWave = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
    }
    
    // Mock daily scores
    private let weeklyScores: [DailyScore] = [
        DailyScore(day: "Mon", score: 72, date: Date().addingTimeInterval(-6 * 86400)),
        DailyScore(day: "Tue", score: 85, date: Date().addingTimeInterval(-5 * 86400)),
        DailyScore(day: "Wed", score: 78, date: Date().addingTimeInterval(-4 * 86400)),
        DailyScore(day: "Thu", score: 91, date: Date().addingTimeInterval(-3 * 86400)),
        DailyScore(day: "Fri", score: 88, date: Date().addingTimeInterval(-2 * 86400)),
        DailyScore(day: "Sat", score: 82, date: Date().addingTimeInterval(-1 * 86400)),
        DailyScore(day: "Today", score: 87, date: Date())
    ]
    
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
                        
                        // Summary Stats
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Average",
                                value: "\(averageScore)",
                                subtitle: "PhylloScore"
                            )
                            
                            StatCard(
                                title: "Trend",
                                value: "↑12%",
                                subtitle: "vs last period",
                                valueColor: .phylloAccent
                            )
                            
                            StatCard(
                                title: "Best Day",
                                value: "91",
                                subtitle: "Thursday"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Wave Visualization
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Momentum")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            GeometryReader { geometry in
                                ZStack {
                                    // Background grid
                                    VStack(spacing: 0) {
                                        ForEach(0..<5) { i in
                                            Divider()
                                                .background(Color.white.opacity(0.05))
                                            if i < 4 {
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                    // Wave visualization
                                    ZStack(alignment: .bottom) {
                                        // Bars
                                        HStack(alignment: .bottom, spacing: 0) {
                                            ForEach(Array(weeklyScores.enumerated()), id: \.offset) { index, score in
                                                WaveBar(
                                                    score: score,
                                                    isSelected: selectedDay == index,
                                                    height: geometry.size.height,
                                                    animateWave: animateWave,
                                                    index: index
                                                )
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        selectedDay = selectedDay == index ? nil : index
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Connecting curve
                                        WaveCurve(scores: weeklyScores.map { $0.score }, height: geometry.size.height)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.phylloAccent, Color.phylloAccent.opacity(0.5)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 3
                                            )
                                            .shadow(color: Color.phylloAccent.opacity(0.5), radius: 10, y: 5)
                                            .opacity(animateWave ? 1 : 0)
                                            .animation(.easeOut(duration: 1).delay(0.5), value: animateWave)
                                    }
                                    
                                    // Selected day tooltip
                                    if let selected = selectedDay {
                                        VStack {
                                            DayTooltip(score: weeklyScores[selected])
                                                .offset(x: tooltipOffset(for: selected, in: geometry.size.width))
                                            Spacer()
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                            
                            // Day labels
                            HStack(spacing: 0) {
                                ForEach(weeklyScores) { score in
                                    Text(score.day)
                                        .font(.system(size: 12))
                                        .foregroundColor(.phylloTextTertiary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Insights
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Insights")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            InsightCard(
                                icon: "arrow.up.circle.fill",
                                iconColor: .phylloAccent,
                                title: "Strong Recovery",
                                description: "Your score bounced back quickly after Wednesday's dip"
                            )
                            
                            InsightCard(
                                icon: "calendar.circle.fill",
                                iconColor: .orange,
                                title: "Weekend Pattern",
                                description: "Scores tend to drop on weekends - plan ahead"
                            )
                            
                            InsightCard(
                                icon: "lightbulb.circle.fill",
                                iconColor: .yellow,
                                title: "Peak Performance",
                                description: "Thursday shows your best adherence - replicate this pattern"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Momentum Insights")
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
            withAnimation {
                animateWave = true
            }
        }
    }
    
    private var averageScore: Int {
        let total = weeklyScores.reduce(0) { $0 + $1.score }
        return total / weeklyScores.count
    }
    
    private func tooltipOffset(for index: Int, in width: CGFloat) -> CGFloat {
        let barWidth = width / CGFloat(weeklyScores.count)
        let position = CGFloat(index) * barWidth + barWidth / 2
        return position - width / 2
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    var valueColor: Color = .white
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.phylloTextTertiary)
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.phylloTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.phylloElevated)
        .cornerRadius(12)
    }
}

struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.phylloTextSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.phylloElevated)
        .cornerRadius(16)
    }
}

#Preview {
    MomentumWaveDetailView()
        .preferredColorScheme(.dark)
}
//
//  ScoreEvolutionChart.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  Chart showing PhylloScore evolution over time

import SwiftUI
import Charts

struct ScoreEvolutionChart: View {
    let dataPoints: [ScoreDataPoint]
    let showLabels: Bool
    let height: CGFloat
    
    @State private var animateChart = false
    @State private var selectedPoint: ScoreDataPoint?
    
    init(dataPoints: [ScoreDataPoint], showLabels: Bool = true, height: CGFloat = 200) {
        self.dataPoints = dataPoints
        self.showLabels = showLabels
        self.height = height
    }
    
    private var minScore: Int {
        dataPoints.map { $0.score }.min() ?? 0
    }
    
    private var maxScore: Int {
        max(dataPoints.map { $0.score }.max() ?? 100, 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showLabels {
                HStack {
                    Text("PhylloScore Evolution")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let last = dataPoints.last, dataPoints.count > 1 {
                        let first = dataPoints.first!
                        let change = last.score - first.score
                        let changePercent = Double(change) / Double(first.score) * 100
                        
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 12))
                            Text("\(abs(Int(changePercent)))%")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }
            
            Chart(dataPoints) { point in
                // Area under the line
                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Score", animateChart ? point.score : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.phylloAccent.opacity(0.3), Color.phylloAccent.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Line
                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Score", animateChart ? point.score : 0)
                )
                .foregroundStyle(Color.phylloAccent)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                
                // Points
                PointMark(
                    x: .value("Day", point.day),
                    y: .value("Score", animateChart ? point.score : 0)
                )
                .foregroundStyle(Color.phylloAccent)
                .symbolSize(selectedPoint?.id == point.id ? 120 : 60)
            }
            .frame(height: height)
            .chartYScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(Color.phylloTextTertiary)
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(Color.phylloTextTertiary)
                        .font(.system(size: 10))
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    // Goal zones
                    Rectangle()
                        .fill(Color.green.opacity(0.05))
                        .frame(height: geometry.size.height * 0.2)
                        .offset(y: 0)
                    
                    Rectangle()
                        .fill(Color.orange.opacity(0.05))
                        .frame(height: geometry.size.height * 0.2)
                        .offset(y: geometry.size.height * 0.2)
                    
                    Rectangle()
                        .fill(Color.red.opacity(0.05))
                        .frame(height: geometry.size.height * 0.6)
                        .offset(y: geometry.size.height * 0.4)
                }
            }
            .chartAngleSelection(value: .constant(nil))
            .onTapGesture { location in
                // Handle tap to select point
            }
            
            // Selected point detail
            if let selected = selectedPoint {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(selected.day)")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextTertiary)
                        
                        Text("Score: \(selected.score)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    if !selected.note.isEmpty {
                        Text(selected.note)
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
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
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }
}

// MARK: - Data Model

struct ScoreDataPoint: Identifiable {
    let id = UUID()
    let day: Int
    let score: Int
    let note: String
    
    init(day: Int, score: Int, note: String = "") {
        self.day = day
        self.score = score
        self.note = note
    }
}

// MARK: - Mock Data Generator

extension ScoreEvolutionChart {
    static func generateMockData(days: Int, startScore: Int = 42) -> [ScoreDataPoint] {
        var points: [ScoreDataPoint] = []
        var currentScore = startScore
        
        for day in 1...days {
            // Simulate gradual improvement with some variation
            let change = Int.random(in: -5...8)
            currentScore = max(30, min(95, currentScore + change))
            
            let note: String
            switch day {
            case 1: note = "Started journey"
            case 7: note = "First week complete"
            case 14: note = "Patterns emerging"
            case 21: note = "Breakthrough week"
            case 30: note = "Current"
            default: note = ""
            }
            
            points.append(ScoreDataPoint(day: day, score: currentScore, note: note))
        }
        
        return points
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 32) {
            // 7-day chart
            ScoreEvolutionChart(
                dataPoints: ScoreEvolutionChart.generateMockData(days: 7)
            )
            
            // 30-day chart without labels
            ScoreEvolutionChart(
                dataPoints: ScoreEvolutionChart.generateMockData(days: 30),
                showLabels: false,
                height: 150
            )
        }
        .padding()
    }
}
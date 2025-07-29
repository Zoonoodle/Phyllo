//
//  MomentumWaveView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct MomentumWaveView: View {
    @StateObject private var mockData = MockDataManager.shared
    @State private var selectedDay: Int? = nil
    @State private var animateWave = false
    
    // Mock daily scores for past 7 days
    private let dailyScores: [DailyScore] = [
        DailyScore(day: "Mon", score: 72, date: Date().addingTimeInterval(-6 * 86400)),
        DailyScore(day: "Tue", score: 85, date: Date().addingTimeInterval(-5 * 86400)),
        DailyScore(day: "Wed", score: 78, date: Date().addingTimeInterval(-4 * 86400)),
        DailyScore(day: "Thu", score: 91, date: Date().addingTimeInterval(-3 * 86400)),
        DailyScore(day: "Fri", score: 88, date: Date().addingTimeInterval(-2 * 86400)),
        DailyScore(day: "Sat", score: 82, date: Date().addingTimeInterval(-1 * 86400)),
        DailyScore(day: "Today", score: 87, date: Date())
    ]
    
    var body: some View {
        SimplePhylloCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("7-Day Momentum")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Average Score
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(averageScore)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.phylloAccent)
                        Text("avg score")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextTertiary)
                    }
                }
                
                // Wave Visualization
                GeometryReader { geometry in
                    ZStack {
                        // Background grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<4) { i in
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                if i < 3 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // Wave bars and curve
                        ZStack(alignment: .bottom) {
                            // Bars
                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(Array(dailyScores.enumerated()), id: \.offset) { index, score in
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
                            WaveCurve(scores: dailyScores.map { $0.score }, height: geometry.size.height)
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
                                DayTooltip(score: dailyScores[selected])
                                    .offset(x: tooltipOffset(for: selected, in: geometry.size.width))
                                Spacer()
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .frame(height: 160)
                
                // Day labels
                HStack(spacing: 0) {
                    ForEach(dailyScores) { score in
                        Text(score.day)
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextTertiary)
                            .frame(maxWidth: .infinity)
                    }
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
        let total = dailyScores.reduce(0) { $0 + $1.score }
        return total / dailyScores.count
    }
    
    private func tooltipOffset(for index: Int, in width: CGFloat) -> CGFloat {
        let barWidth = width / CGFloat(dailyScores.count)
        let position = CGFloat(index) * barWidth + barWidth / 2
        return position - width / 2
    }
}

struct WaveBar: View {
    let score: DailyScore
    let isSelected: Bool
    let height: CGFloat
    let animateWave: Bool
    let index: Int
    
    private var barHeight: CGFloat {
        (CGFloat(score.score) / 100) * height * 0.8
    }
    
    private var barColor: Color {
        if score.score < 40 {
            return .red
        } else if score.score < 70 {
            return .orange
        } else {
            return .phylloAccent
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [barColor, barColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: animateWave ? barHeight : 0)
                .frame(maxWidth: .infinity)
                .scaleEffect(x: isSelected ? 1.2 : 1.0, y: 1.0, anchor: .bottom)
                .shadow(color: barColor.opacity(0.5), radius: isSelected ? 10 : 5, y: 5)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.1),
                    value: animateWave
                )
                .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

struct WaveCurve: Shape {
    let scores: [Int]
    let height: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let points = scores.enumerated().map { index, score in
            let x = (rect.width / CGFloat(scores.count - 1)) * CGFloat(index)
            let y = rect.height - (CGFloat(score) / 100 * height * 0.8)
            return CGPoint(x: x, y: y)
        }
        
        guard !points.isEmpty else { return path }
        
        path.move(to: points[0])
        
        // Create smooth curve through points
        for i in 0..<points.count - 1 {
            let current = points[i]
            let next = points[i + 1]
            let controlPoint1 = CGPoint(x: current.x + (next.x - current.x) / 3, y: current.y)
            let controlPoint2 = CGPoint(x: current.x + (next.x - current.x) * 2 / 3, y: next.y)
            
            path.addCurve(to: next, control1: controlPoint1, control2: controlPoint2)
        }
        
        return path
    }
}

struct DayTooltip: View {
    let score: DailyScore
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(score.score)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(score.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.system(size: 12))
                .foregroundColor(.phylloTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.phylloSurface)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

struct DailyScore: Identifiable {
    let id = UUID()
    let day: String
    let score: Int
    let date: Date
}

#Preview {
    VStack {
        MomentumWaveView()
            .padding()
        
        Spacer()
    }
    .background(Color.phylloBackground)
    .preferredColorScheme(.dark)
}
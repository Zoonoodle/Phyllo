//
//  PremiumActivityRings.swift
//  NutriSync
//
//  Premium Apple Watch-inspired activity rings for Performance tab
//

import SwiftUI

struct PremiumRingSpecs {
    static let ringWidth: CGFloat = 10
    static let ringSpacing: CGFloat = 8
    static let outerRingSize: CGFloat = 180
    static let middleRingSize: CGFloat = 154
    static let innerRingSize: CGFloat = 128
    
    static let glowRadius: CGFloat = 8
    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: Double = 0.3
}

struct PremiumActivityRings: View {
    let timingScore: Double
    let nutrientScore: Double
    let adherenceScore: Double
    
    @State private var animatedTimingScore: Double = 0
    @State private var animatedNutrientScore: Double = 0
    @State private var animatedAdherenceScore: Double = 0
    
    private var overallScore: Double {
        (timingScore + nutrientScore + adherenceScore) / 3
    }
    
    private var rings: [(id: String, progress: Double, color: Color, size: CGFloat, delay: Double)] {
        [
            (id: "timing", progress: animatedTimingScore, color: Color(hex: "FF3B30"), size: PremiumRingSpecs.outerRingSize, delay: 0),
            (id: "nutrient", progress: animatedNutrientScore, color: Color(hex: "04DE71"), size: PremiumRingSpecs.middleRingSize, delay: 0.15),
            (id: "adherence", progress: animatedAdherenceScore, color: Color(hex: "007AFF"), size: PremiumRingSpecs.innerRingSize, delay: 0.3)
        ]
    }
    
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.nutriSyncBackground,
                    Color.nutriSyncBackground.opacity(0.5)
                ],
                center: .center,
                startRadius: 20,
                endRadius: 150
            )
            
            ForEach(rings, id: \.id) { ring in
                CircularProgressRing(
                    progress: ring.progress,
                    color: ring.color,
                    size: ring.size
                )
                .animation(.spring(
                    response: 0.8,
                    dampingFraction: 0.85
                ).delay(ring.delay), value: ring.progress)
            }
            
            VStack(spacing: 2) {
                Text("\(Int(overallScore * 100))%")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: overallScore)
                
                Text("Overall")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(height: 240)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                animatedTimingScore = timingScore
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.15)) {
                animatedNutrientScore = nutrientScore
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85).delay(0.3)) {
                animatedAdherenceScore = adherenceScore
            }
        }
    }
}

struct CircularProgressRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    
    private let lineWidth: CGFloat = PremiumRingSpecs.ringWidth
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [
                            color,
                            color.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.6), radius: PremiumRingSpecs.glowRadius, x: 0, y: 0)
        }
    }
}

struct RingLabelsView: View {
    let timingScore: Double
    let nutrientScore: Double
    let adherenceScore: Double
    
    var body: some View {
        HStack(spacing: 30) {
            RingLabel(
                icon: "clock.fill",
                title: "TIMING",
                value: "\(Int(timingScore * 100))%",
                color: Color(hex: "FF3B30")
            )
            
            RingLabel(
                icon: "leaf.fill",
                title: "NUTRIENTS",
                value: "\(Int(nutrientScore * 100))%",
                color: Color(hex: "04DE71")
            )
            
            RingLabel(
                icon: "checkmark.shield.fill",
                title: "ADHERENCE",
                value: "\(Int(adherenceScore * 100))%",
                color: Color(hex: "007AFF")
            )
        }
    }
}

struct RingLabel: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            PremiumActivityRings(
                timingScore: 1.0,
                nutrientScore: 0.19,
                adherenceScore: 0.34
            )
            
            RingLabelsView(
                timingScore: 1.0,
                nutrientScore: 0.19,
                adherenceScore: 0.34
            )
            .padding(.horizontal, 40)
        }
    }
}
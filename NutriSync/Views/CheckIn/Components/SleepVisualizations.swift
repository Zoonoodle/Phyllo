//
//  SleepVisualizations.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

// MARK: - Moon Phase Animation
struct MoonPhaseVisualization: View {
    let sleepHours: Double
    let userAge: Int = 25 // TODO: Get from user profile
    
    @State private var animateGlow = false
    @State private var animateStars = false
    @State private var animatedPhase: CGFloat = 0
    
    // Age-based optimal sleep ranges
    private var optimalSleepRange: ClosedRange<Double> {
        switch userAge {
        case 14...17: return 8.0...10.0
        case 18...25: return 7.0...9.0
        case 26...64: return 7.0...9.0
        case 65...: return 7.0...8.0
        default: return 7.0...9.0
        }
    }
    
    // Calculate moon phase based on optimal sleep for age
    private var targetMoonPhase: CGFloat {
        let optimal = optimalSleepRange
        let midpoint = (optimal.lowerBound + optimal.upperBound) / 2
        
        if sleepHours == 0 {
            return 0 // Completely invisible
        } else if sleepHours < optimal.lowerBound {
            // Growing linearly from 0 to 1 as we approach optimal range
            // At optimal.lowerBound, moon should be nearly full
            let progress = CGFloat(sleepHours / optimal.lowerBound)
            return progress * 0.95 // Cap at 0.95 so there's a visible difference when reaching optimal
        } else if sleepHours <= optimal.upperBound {
            // Full moon throughout optimal range
            return 1.0
        } else {
            // Gradual degradation after optimal
            let excess = sleepHours - optimal.upperBound
            // At 12 hours (for age 25, that's 3 hours past optimal), should be at 0.5
            let hoursToHalfMoon = 12.0 - optimal.upperBound
            let degradationRate = 0.5 / hoursToHalfMoon
            return max(0.5, 1.0 - CGFloat(excess * degradationRate))
        }
    }
    
    private var starCount: Int {
        if sleepHours == 0 {
            return 3 // A few stars when no sleep
        } else if optimalSleepRange.contains(sleepHours) {
            return 12
        } else if sleepHours < optimalSleepRange.lowerBound {
            return max(3, Int(12 * animatedPhase))
        } else {
            return max(6, Int(12 * animatedPhase))
        }
    }
    
    var sleepQuality: SleepQuality {
        if optimalSleepRange.contains(sleepHours) {
            return .optimal
        } else if sleepHours < optimalSleepRange.lowerBound - 2 {
            return .poor
        } else if sleepHours < optimalSleepRange.lowerBound {
            return .suboptimal
        } else if sleepHours > optimalSleepRange.upperBound + 2 {
            return .excessive
        } else {
            return .slightlyOver
        }
    }
    
    enum SleepQuality {
        case poor, suboptimal, optimal, slightlyOver, excessive
    }
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // Stars around the moon
                ForEach(0..<starCount, id: \.self) { index in
                    StarView(
                        index: index,
                        totalStars: starCount,
                        animate: animateStars
                    )
                }
                
                // Moon
                MoonShape(phase: animatedPhase)
                    .fill(Color.white.opacity(animatedPhase > 0 ? 0.9 : 0))
                    .frame(width: 80, height: 80)
                    .shadow(color: .white.opacity(animatedPhase > 0 ? (animateGlow ? 0.6 : 0.3) : 0), 
                           radius: animateGlow ? 20 : 10)
                    .scaleEffect(animateGlow ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateGlow
                    )
                    .onChange(of: targetMoonPhase) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.8)) {
                            animatedPhase = newValue
                        }
                    }
            }
            .frame(width: 200, height: 200)
            
            // Sleep insight text
            SleepInsightText(
                sleepHours: sleepHours,
                quality: sleepQuality,
                optimalRange: optimalSleepRange
            )
        }
        .onAppear {
            animateGlow = true
            withAnimation(.easeInOut(duration: 3.0).repeatForever()) {
                animateStars = true
            }
            // Set initial animated phase
            animatedPhase = targetMoonPhase
        }
    }
}

// MARK: - Moon Shape
struct MoonShape: Shape {
    var phase: CGFloat // 0 = new moon, 1 = full moon
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        if phase <= 0.01 {
            // Completely invisible - no moon
            return path
        } else if phase >= 0.99 {
            // Full moon
            path.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
            return path
        } else {
            // Draw crescent/gibbous moon growing from left to right
            // We'll use two arcs to create the moon shape
            
            // Start at top
            path.move(to: CGPoint(x: center.x, y: center.y - radius))
            
            // Left edge - always a semicircle (the illuminated edge)
            path.addArc(center: center, radius: radius,
                       startAngle: .degrees(-90),
                       endAngle: .degrees(90),
                       clockwise: false)
            
            // Right edge - varies with phase to create the crescent
            if phase < 0.5 {
                // Crescent moon (less than half)
                // The terminator (shadow line) curves inward
                let innerCurve = 1.0 - (phase * 2) // 1.0 to 0.0 as phase goes 0 to 0.5
                let xOffset = radius * innerCurve
                
                // Draw the curved terminator from bottom to top
                path.addCurve(
                    to: CGPoint(x: center.x, y: center.y - radius),
                    control1: CGPoint(x: center.x + xOffset, y: center.y + radius * 0.55),
                    control2: CGPoint(x: center.x + xOffset, y: center.y - radius * 0.55)
                )
            } else {
                // Gibbous moon (more than half)
                // The terminator curves outward
                let outerCurve = (phase - 0.5) * 2 // 0.0 to 1.0 as phase goes 0.5 to 1.0
                let xOffset = radius * outerCurve
                
                // Draw the curved terminator from bottom to top
                path.addCurve(
                    to: CGPoint(x: center.x, y: center.y - radius),
                    control1: CGPoint(x: center.x + xOffset, y: center.y + radius * 0.55),
                    control2: CGPoint(x: center.x + xOffset, y: center.y - radius * 0.55)
                )
            }
            
            path.closeSubpath()
        }
        
        return path
    }
}

// MARK: - Star View
struct StarView: View {
    let index: Int
    let totalStars: Int
    let animate: Bool
    
    @State private var opacity: Double = 0
    
    private var position: CGPoint {
        let angle = (CGFloat(index) / CGFloat(totalStars)) * 2 * .pi
        let radius: CGFloat = 70 + CGFloat(index % 3) * 15
        let x = 100 + radius * cos(angle)
        let y = 100 + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    var body: some View {
        Text("✦")
            .font(.system(size: CGFloat(8 + (index % 3) * 2)))
            .foregroundColor(.white)
            .position(position)
            .opacity(animate ? opacity : 0)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.2),
                value: animate
            )
            .onAppear {
                opacity = 0.3 + Double(index % 3) * 0.2
            }
    }
}

// MARK: - Sleep Insight Text
struct SleepInsightText: View {
    let sleepHours: Double
    let quality: MoonPhaseVisualization.SleepQuality
    let optimalRange: ClosedRange<Double>
    
    private var insightText: String {
        switch quality {
        case .poor:
            return "Severe sleep deprivation. Expect increased hunger (22% ↑ ghrelin), cravings for high-carb foods, and reduced satiety signals."
        case .suboptimal:
            return "Below optimal sleep. You may experience stronger appetite and preference for calorie-dense foods today."
        case .optimal:
            return "Perfect sleep for your age! Your hunger hormones (ghrelin & leptin) are balanced for optimal nutrition choices."
        case .slightlyOver:
            return "Slightly above optimal. Good recovery, but watch for potential grogginess affecting meal timing."
        case .excessive:
            return "Excessive sleep can disrupt metabolism. Consider adjusting meal timing to restore energy balance."
        }
    }
    
    private var rangeText: String {
        "Optimal for your age: \(Int(optimalRange.lowerBound))-\(Int(optimalRange.upperBound)) hours"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(rangeText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.nutriSyncTextTertiary)
            
            Text(insightText)
                .font(.system(size: 13))
                .foregroundColor(.nutriSyncTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 50) {
                Text("Moon Phase Visualization (Age 25)")
                    .foregroundColor(.white)
                    .font(.title2)
                
                VStack(spacing: 40) {
                    ForEach([0.0, 2.0, 4.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0], id: \.self) { hours in
                        VStack(spacing: 20) {
                            HStack {
                                Text("\(hours, specifier: "%.1f") hours")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Spacer()
                                
                                if hours >= 7.0 && hours <= 9.0 {
                                    Text("OPTIMAL")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            .frame(width: 300)
                            
                            MoonPhaseVisualization(sleepHours: hours)
                        }
                    }
                }
            }
            .padding(.vertical, 40)
        }
    }
}
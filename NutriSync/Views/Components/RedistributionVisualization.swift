import SwiftUI

struct RedistributionVisualization: View {
    let redistribution: RedistributionResult
    @State private var animateChanges = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(redistribution.adjustedWindows.enumerated()), id: \.offset) { index, window in
                HStack(spacing: 12) {
                    // Window time label
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Window \(index + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                        
                        Text(window.reason)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    .frame(width: 80, alignment: .leading)
                    
                    // Before/After bars
                    HStack(spacing: 0) {
                        // Original bar (semi-transparent)
                        CalorieBar(
                            value: window.originalMacros.totalCalories,
                            maxValue: 1000,
                            color: Color.white.opacity(0.1),
                            label: "\(window.originalMacros.totalCalories)",
                            isAnimated: false
                        )
                        
                        // Adjusted bar (highlighted)
                        CalorieBar(
                            value: window.adjustedMacros.totalCalories,
                            maxValue: 1000,
                            color: colorForWindow(window),
                            label: "\(window.adjustedMacros.totalCalories)",
                            isAnimated: animateChanges
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Change indicator
                    if let change = calculateChange(for: window) {
                        ChangeIndicator(change: change)
                            .opacity(animateChanges ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: animateChanges)
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                RedistributionLegendItem(color: Color.white.opacity(0.1), label: "Original")
                RedistributionLegendItem(color: Color(hex: "10b981"), label: "Adjusted")
                
                Spacer()
                
                if false { // Remove preview badge for now
                    Text("PREVIEW")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateChanges = true
            }
        }
    }
    
    private func calculateChange(for window: AdjustedWindow) -> Int? {
        let change = window.adjustedMacros.totalCalories - window.originalMacros.totalCalories
        return change != 0 ? change : nil
    }
    
    private func colorForWindow(_ window: AdjustedWindow) -> Color {
        if let change = calculateChange(for: window) {
            return change > 0 ? Color(hex: "10b981") : .blue
        }
        return Color.white.opacity(0.5)
    }
}

struct CalorieBar: View {
    let value: Int
    let maxValue: Int
    let color: Color
    let label: String
    let isAnimated: Bool
    
    private var width: CGFloat {
        CGFloat(value) / CGFloat(maxValue)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Rectangle()
                    .fill(Color.white.opacity(0.03))
                
                // Value bar
                Rectangle()
                    .fill(color)
                    .frame(width: isAnimated ? geometry.size.width * width : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isAnimated)
                
                // Label
                if isAnimated {
                    Text(label)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .offset(x: min(geometry.size.width * width + 4, geometry.size.width - 35))
                        .opacity(isAnimated ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.4), value: isAnimated)
                }
            }
        }
        .frame(height: 28)
        .cornerRadius(6)
    }
}

struct ChangeIndicator: View {
    let change: Int
    
    private var icon: String {
        change > 0 ? "arrow.up" : "arrow.down"
    }
    
    private var color: Color {
        change > 0 ? .phylloAccent : .blue
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
            
            Text("\(abs(change))")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }
}

private struct RedistributionLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.5))
        }
    }
}

#Preview {
    RedistributionVisualization(
        redistribution: RedistributionResult(
            adjustedWindows: [
                AdjustedWindow(
                    windowId: "morning-fuel",
                    originalMacros: MacroTargets(
                        protein: 30,
                        carbs: 45,
                        fat: 12
                    ),
                    adjustedMacros: MacroTargets(
                        protein: 35,
                        carbs: 50,
                        fat: 14
                    ),
                    adjustmentRatio: 1.125,
                    reason: "Increased to compensate for earlier underconsumption"
                )
            ],
            explanation: "You ate 25% less than planned in your previous window. I've distributed those nutrients across your remaining meals.",
            educationalTip: "💡 Eating consistently helps maintain stable energy levels throughout the day.",
            trigger: .underconsumption(percentUnder: 25),
            confidenceScore: 0.85,
            totalRedistributed: MacroTargets(
                protein: 5,
                carbs: 5,
                fat: 2
            )
        )
    )
    .padding()
    .background(Color.black)
}
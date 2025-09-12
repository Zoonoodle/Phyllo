import SwiftUI

// MARK: - Redistribution Timeline Indicator
// Shows live redistribution status in the timeline view

struct RedistributionTimelineIndicator: View {
    let redistribution: RedistributionResult
    @State private var isExpanded = false
    @State private var animateIn = false
    @State private var dismissing = false
    
    var totalCaloriesRedistributed: Int {
        redistribution.totalRedistributed.totalCalories
    }
    
    var affectedWindowCount: Int {
        redistribution.adjustedWindows.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header (always visible)
            HStack(spacing: 12) {
                // Animated icon
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.phylloAccent)
                    .rotationEffect(.degrees(animateIn ? 360 : 0))
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: animateIn)
                
                // Summary text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Macros Redistributed")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                    
                    Text("\(totalCaloriesRedistributed) calories across \(affectedWindowCount) windows")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Expand/collapse button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.phylloAccent.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.phylloAccent.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Expanded detail view
            if isExpanded {
                VStack(spacing: 12) {
                    // Redistribution flow visualization
                    RedistributionFlowVisualization(
                        adjustedWindows: redistribution.adjustedWindows
                    )
                    .frame(height: 80)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Explanation
                    Text(redistribution.explanation)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    // Educational tip if available
                    if let tip = redistribution.educationalTip {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow.opacity(0.8))
                            
                            Text(tip)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                    }
                    
                    // Dismiss button
                    Button(action: dismiss) {
                        Text("Got it")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.phylloAccent)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.phylloAccent.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .padding(.bottom, 12)
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 0.8 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateIn = true
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            dismissing = true
        }
    }
}

// MARK: - Redistribution Flow Visualization

struct RedistributionFlowVisualization: View {
    let adjustedWindows: [AdjustedWindow]
    @State private var animateFlow = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Flow lines between windows
                ForEach(Array(adjustedWindows.enumerated()), id: \.offset) { index, _ in
                    if index < adjustedWindows.count - 1 {
                        FlowArrow(
                            from: windowPosition(index: index, in: geometry),
                            to: windowPosition(index: index + 1, in: geometry),
                            animate: animateFlow
                        )
                    }
                }
                
                // Window nodes
                HStack(spacing: 0) {
                    ForEach(Array(adjustedWindows.enumerated()), id: \.offset) { index, window in
                        WindowNode(
                            window: window,
                            isAnimated: animateFlow
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateFlow = true
            }
        }
    }
    
    private func windowPosition(index: Int, in geometry: GeometryProxy) -> CGPoint {
        let width = geometry.size.width
        let count = CGFloat(adjustedWindows.count)
        let spacing = width / count
        let x = spacing * (CGFloat(index) + 0.5)
        let y = geometry.size.height / 2
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Flow Arrow Component

struct FlowArrow: View {
    let from: CGPoint
    let to: CGPoint
    let animate: Bool
    
    @State private var phase: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Create curved path
            let controlPoint = CGPoint(
                x: (from.x + to.x) / 2,
                y: min(from.y, to.y) - 20
            )
            path.addQuadCurve(to: to, control: controlPoint)
        }
        .stroke(
            Color.phylloAccent.opacity(0.3),
            style: StrokeStyle(
                lineWidth: 2,
                lineCap: .round,
                dash: [5, 5],
                dashPhase: phase
            )
        )
        .onAppear {
            if animate {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 10
                }
            }
        }
    }
}

// MARK: - Window Node Component

struct WindowNode: View {
    let window: AdjustedWindow
    let isAnimated: Bool
    
    @State private var scale: CGFloat = 0
    
    var changeAmount: Int {
        window.adjustedMacros.totalCalories - window.originalMacros.totalCalories
    }
    
    var changeColor: Color {
        if changeAmount > 0 {
            return .phylloAccent
        } else if changeAmount < 0 {
            return .orange
        } else {
            return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Change indicator
            ZStack {
                Circle()
                    .fill(changeColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Circle()
                    .stroke(changeColor, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(scale)
                
                VStack(spacing: 0) {
                    Image(systemName: changeAmount > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 10, weight: .bold))
                    Text("\(abs(changeAmount))")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(changeColor)
            }
            
            // Window identifier (abbreviated)
            Text(windowName)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
        }
        .opacity(scale)
        .onAppear {
            if isAnimated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1
                }
            }
        }
    }
    
    private var windowName: String {
        // Extract a short identifier from the window ID
        let components = window.windowId.split(separator: "-")
        if let first = components.first {
            return String(first.prefix(4))
        }
        return "Win"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RedistributionTimelineIndicator(
            redistribution: RedistributionResult(
                adjustedWindows: [
                    AdjustedWindow(
                        windowId: "morning-fuel",
                        originalMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
                        adjustedMacros: MacroTargets(protein: 25, carbs: 35, fat: 12),
                        adjustmentRatio: 0.85,
                        reason: "Reduced due to earlier overconsumption"
                    ),
                    AdjustedWindow(
                        windowId: "lunch-power",
                        originalMacros: MacroTargets(protein: 40, carbs: 50, fat: 20),
                        adjustedMacros: MacroTargets(protein: 35, carbs: 45, fat: 18),
                        adjustmentRatio: 0.9,
                        reason: "Slightly reduced"
                    ),
                    AdjustedWindow(
                        windowId: "afternoon-boost",
                        originalMacros: MacroTargets(protein: 25, carbs: 30, fat: 10),
                        adjustedMacros: MacroTargets(protein: 30, carbs: 35, fat: 12),
                        adjustmentRatio: 1.15,
                        reason: "Increased to balance day"
                    )
                ],
                explanation: "You ate 30% more than planned in your morning window. I've adjusted your remaining meals to keep you on track for the day.",
                educationalTip: "Protein and fiber help you feel fuller with smaller portions",
                trigger: .overconsumption(percentOver: 30),
                confidenceScore: 0.85,
                totalRedistributed: MacroTargets(protein: 15, carbs: 20, fat: 7)
            )
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
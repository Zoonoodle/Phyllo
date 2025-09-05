import SwiftUI

// MARK: - Redistribution Nudge Component

struct RedistributionNudge: View {
    let redistribution: RedistributionResult
    let onAccept: () -> Void
    let onReject: () -> Void
    
    @State private var showingDetails = false
    @State private var animationProgress: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Gradient background matching onboarding theme
            LinearGradient(
                colors: [Color.phylloAccent.opacity(0.15), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 2)
            .opacity(animationProgress)
            
            VStack(spacing: 20) {
                // Icon with gentle pulse animation
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundColor(.phylloAccent)
                    .scaleEffect(animationProgress)
                    .scaleEffect(showingDetails ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showingDetails)
                
                // Clear, friendly explanation
                VStack(spacing: 8) {
                    Text("Adjusting Your Day")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(redistribution.explanation)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(animationProgress)
                
                // Visual preview of changes
                if !redistribution.adjustedWindows.isEmpty {
                    RedistributionVisualizationPreview(redistribution: redistribution)
                        .frame(height: 120)
                        .opacity(animationProgress)
                        .scaleEffect(animationProgress)
                }
                
                // Action buttons matching onboarding style
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onReject()
                        }
                    }) {
                        Text("Keep Original")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onAccept()
                        }
                    }) {
                        Text("Apply Changes")
                            .font(.callout.weight(.semibold))
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "10b981"))
                            .cornerRadius(12)
                            .shadow(color: Color(hex: "10b981").opacity(0.3), radius: 8, y: 4)
                    }
                }
                .opacity(animationProgress)
                
                // Educational snippet
                if let educationalTip = redistribution.educationalTip {
                    Button(action: { 
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showingDetails.toggle()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: showingDetails ? "chevron.up.circle" : "questionmark.circle")
                                .font(.caption)
                            Text(showingDetails ? educationalTip : "Why this adjustment?")
                                .font(.caption)
                                .lineLimit(showingDetails ? nil : 1)
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.05))
                        .cornerRadius(8)
                    }
                    .opacity(animationProgress)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .shadow(color: Color.black.opacity(0.1), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "10b981").opacity(0.1), lineWidth: 1)
            )
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Redistribution Visualization Preview

struct RedistributionVisualizationPreview: View {
    let redistribution: RedistributionResult
    @State private var animatedValues: [String: CGFloat] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 8) {
                ForEach(Array(redistribution.adjustedWindows.prefix(4)), id: \.windowId) { window in
                    VStack(spacing: 4) {
                        // Window name (truncated)
                        Text(windowName(for: window))
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                        
                        // Before/After bars
                        ZStack(alignment: .bottom) {
                            // Original bar (ghost)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: barHeight(for: window.originalMacros.calories, in: geometry))
                            
                            // Adjusted bar (animated)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(adjustmentColor(for: window))
                                .frame(height: animatedBarHeight(for: window, in: geometry))
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Calorie change
                        Text(calorieChangeText(for: window))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(adjustmentColor(for: window))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            animateBars()
        }
    }
    
    private func windowName(for window: AdjustedWindow) -> String {
        // Extract a short name from the window ID or reason
        let components = window.windowId.split(separator: "-")
        if let firstComponent = components.first {
            return String(firstComponent.prefix(8))
        }
        return "Window"
    }
    
    private func barHeight(for calories: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxCalories = redistribution.adjustedWindows.reduce(0) { max, window in
            Swift.max(max, Swift.max(window.originalMacros.calories, window.adjustedMacros.calories))
        }
        guard maxCalories > 0 else { return 0 }
        
        let ratio = CGFloat(calories) / CGFloat(maxCalories)
        return ratio * (geometry.size.height - 40) // Leave space for labels
    }
    
    private func animatedBarHeight(for window: AdjustedWindow, in geometry: GeometryProxy) -> CGFloat {
        let targetHeight = barHeight(for: window.adjustedMacros.calories, in: geometry)
        let animatedValue = animatedValues[window.windowId] ?? 0
        return targetHeight * animatedValue
    }
    
    private func adjustmentColor(for window: AdjustedWindow) -> Color {
        let change = window.adjustedMacros.calories - window.originalMacros.calories
        if change > 0 {
            return .green
        } else if change < 0 {
            return .orange
        } else {
            return .gray
        }
    }
    
    private func calorieChangeText(for window: AdjustedWindow) -> String {
        let change = window.adjustedMacros.calories - window.originalMacros.calories
        if change > 0 {
            return "+\(change)"
        } else if change < 0 {
            return "\(change)"
        } else {
            return "0"
        }
    }
    
    private func animateBars() {
        for (index, window) in redistribution.adjustedWindows.enumerated() {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.1)
            ) {
                animatedValues[window.windowId] = 1
            }
        }
    }
}

// MARK: - Preview Provider

struct RedistributionNudge_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            RedistributionNudge(
                redistribution: sampleRedistributionResult(),
                onAccept: { print("Accepted") },
                onReject: { print("Rejected") }
            )
            .padding()
        }
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
    
    static func sampleRedistributionResult() -> RedistributionResult {
        RedistributionResult(
            adjustedWindows: [
                AdjustedWindow(
                    windowId: "morning-window",
                    originalMacros: MacroTargets(protein: 30, carbs: 40, fat: 15),
                    adjustedMacros: MacroTargets(protein: 28, carbs: 35, fat: 12),
                    adjustmentRatio: 0.875,
                    reason: "Reduced due to earlier overconsumption"
                ),
                AdjustedWindow(
                    windowId: "lunch-window",
                    originalMacros: MacroTargets(protein: 40, carbs: 60, fat: 20),
                    adjustedMacros: MacroTargets(protein: 35, carbs: 50, fat: 18),
                    adjustmentRatio: 0.833,
                    reason: "Adjusted for balance"
                )
            ],
            explanation: "You ate 30% more than planned. I've reduced your upcoming meals to help balance your day.",
            educationalTip: "Try adding more protein and fiber to feel fuller with smaller portions.",
            trigger: .overconsumption(percentOver: 30),
            confidenceScore: 0.85,
            totalRedistributed: MacroTargets(protein: 15, carbs: 15, fat: 5)
        )
    }
}
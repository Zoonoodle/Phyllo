import SwiftUI

struct RedistributionVisualization: View {
    let redistribution: RedistributionResult
    @State private var animateChanges = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(redistribution.adjustedWindows) { window in
                HStack(spacing: 12) {
                    // Window time label
                    VStack(alignment: .leading, spacing: 4) {
                        Text(window.name)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.phylloText)
                        
                        Text(formatTimeRange(window))
                            .font(.caption2)
                            .foregroundColor(.phylloTextTertiary)
                    }
                    .frame(width: 80, alignment: .leading)
                    
                    // Before/After bars
                    HStack(spacing: 0) {
                        // Original bar (semi-transparent)
                        if let original = findOriginalWindow(for: window) {
                            CalorieBar(
                                value: original.targetCalories,
                                maxValue: 1000,
                                color: .phylloTextTertiary.opacity(0.3),
                                label: "\(original.targetCalories)",
                                isAnimated: false
                            )
                        }
                        
                        // Adjusted bar (highlighted)
                        CalorieBar(
                            value: window.targetCalories,
                            maxValue: 1000,
                            color: colorForWindow(window),
                            label: "\(window.targetCalories)",
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
                LegendItem(color: .phylloTextTertiary.opacity(0.3), label: "Original")
                LegendItem(color: .phylloAccent, label: "Adjusted")
                
                Spacer()
                
                if redistribution.isPreview {
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
    
    private func findOriginalWindow(for window: MealWindow) -> MealWindow? {
        redistribution.originalWindows.first { $0.id == window.id }
    }
    
    private func calculateChange(for window: MealWindow) -> Int? {
        guard let original = findOriginalWindow(for: window) else { return nil }
        let change = window.targetCalories - original.targetCalories
        return change != 0 ? change : nil
    }
    
    private func colorForWindow(_ window: MealWindow) -> Color {
        if let trigger = redistribution.triggerWindowId,
           window.id == trigger {
            return .orange // Highlight trigger window
        }
        
        if let change = calculateChange(for: window) {
            return change > 0 ? .phylloAccent : .blue
        }
        
        return .phylloTextSecondary
    }
    
    private func formatTimeRange(_ window: MealWindow) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: window.startTime)
        let end = formatter.string(from: window.endTime)
        return "\(start)"
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

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.phylloTextSecondary)
        }
    }
}

#Preview {
    RedistributionVisualization(
        redistribution: RedistributionResult(
            originalWindows: [
                MealWindow(
                    id: "1",
                    name: "Morning Fuel",
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(7200),
                    targetCalories: 400,
                    targetProtein: 30,
                    targetCarbs: 45,
                    targetFat: 12,
                    purpose: .sustainedEnergy,
                    order: 1,
                    isConsumed: false
                )
            ],
            adjustedWindows: [
                MealWindow(
                    id: "1",
                    name: "Morning Fuel",
                    startTime: Date(),
                    endTime: Date().addingTimeInterval(7200),
                    targetCalories: 450,
                    targetProtein: 35,
                    targetCarbs: 50,
                    targetFat: 14,
                    purpose: .sustainedEnergy,
                    order: 1,
                    isConsumed: false
                )
            ],
            trigger: .underconsumption(percent: 25),
            triggerWindowId: "1",
            adjustmentReason: "You ate less than planned",
            isPreview: false,
            affectedWindowIds: ["1"],
            totalCaloriesDelta: 50,
            appliedConstraints: []
        )
    )
    .padding()
    .background(Color.phylloBackground)
}
import SwiftUI

// MARK: - Redistributed Window Card
// Enhanced window card showing redistribution effects inline

struct RedistributedWindowCard: View {
    let window: MealWindow
    let originalMacros: MacroTargets?  // Original targets before redistribution
    let isRedistributed: Bool
    let redistributionReason: String?
    
    @State private var showDetails = false
    @State private var animateRedistribution = false
    
    private var changeAmount: Int? {
        guard let original = originalMacros else { return nil }
        return window.effectiveCalories - original.totalCalories
    }
    
    private var changePercentage: Int? {
        guard let original = originalMacros,
              original.totalCalories > 0 else { return nil }
        let change = window.effectiveCalories - original.totalCalories
        return Int((Double(change) / Double(original.totalCalories)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            VStack(spacing: 12) {
                // Header with redistribution indicator
                HStack {
                    // Window time and name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(window.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(timeRangeText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Redistribution badge if applicable
                    if isRedistributed, let change = changeAmount {
                        RedistributionBadge(
                            change: change,
                            percentage: changePercentage ?? 0,
                            isAnimated: animateRedistribution
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showDetails.toggle()
                            }
                        }
                    }
                }
                
                // Progress bars showing original vs adjusted
                if isRedistributed {
                    RedistributedProgressBars(
                        current: MacroTargets(
                            protein: window.consumed.protein,
                            carbs: window.consumed.carbs,
                            fat: window.consumed.fat
                        ),
                        adjusted: MacroTargets(
                            protein: window.effectiveProtein,
                            carbs: window.effectiveCarbs,
                            fat: window.effectiveFat
                        ),
                        original: originalMacros,
                        isAnimated: animateRedistribution
                    )
                } else {
                    // Normal progress bars
                    StandardProgressBars(
                        current: MacroTargets(
                            protein: window.consumed.protein,
                            carbs: window.consumed.carbs,
                            fat: window.consumed.fat
                        ),
                        target: MacroTargets(
                            protein: window.effectiveProtein,
                            carbs: window.effectiveCarbs,
                            fat: window.effectiveFat
                        )
                    )
                }
                
                // Macro details
                HStack(spacing: 16) {
                    RedistributedMacroIndicator(
                        label: "Protein",
                        current: window.consumed.protein,
                        target: window.effectiveProtein,
                        original: originalMacros?.protein,
                        color: .blue
                    )
                    
                    RedistributedMacroIndicator(
                        label: "Carbs",
                        current: window.consumed.carbs,
                        target: window.effectiveCarbs,
                        original: originalMacros?.carbs,
                        color: .orange
                    )
                    
                    RedistributedMacroIndicator(
                        label: "Fat",
                        current: window.consumed.fat,
                        target: window.effectiveFat,
                        original: originalMacros?.fat,
                        color: .purple
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isRedistributed ? Color.phylloAccent.opacity(0.2) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            
            // Expandable redistribution details
            if showDetails, let reason = redistributionReason {
                RedistributionDetailsPanel(
                    reason: reason,
                    originalMacros: originalMacros,
                    adjustedMacros: MacroTargets(
                        protein: window.effectiveProtein,
                        carbs: window.effectiveCarbs,
                        fat: window.effectiveFat
                    )
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .onAppear {
            if isRedistributed {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                    animateRedistribution = true
                }
            }
        }
    }
    
    private var timeRangeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: window.startTime)) - \(formatter.string(from: window.endTime))"
    }
}

// MARK: - Redistribution Badge

struct RedistributionBadge: View {
    let change: Int
    let percentage: Int
    let isAnimated: Bool
    
    @State private var scale: CGFloat = 0
    
    private var color: Color {
        change > 0 ? .phylloAccent : .orange
    }
    
    private var icon: String {
        change > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            
            VStack(alignment: .leading, spacing: 0) {
                Text("\(change > 0 ? "+" : "")\(change) cal")
                    .font(.caption.weight(.semibold))
                
                Text("\(percentage > 0 ? "+" : "")\(percentage)%")
                    .font(.system(size: 9))
                    .opacity(0.8)
            }
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isAnimated ? scale : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1
            }
        }
    }
}

// MARK: - Redistributed Progress Bars

struct RedistributedProgressBars: View {
    let current: MacroTargets
    let adjusted: MacroTargets
    let original: MacroTargets?
    let isAnimated: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.05))
                
                // Original target (ghost bar)
                if let original = original {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.03))
                        .frame(width: barWidth(for: original.totalCalories, in: geometry))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                .animation(.easeOut(duration: 0.3), value: isAnimated)
                        )
                }
                
                // Current consumption
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [Color.phylloAccent, Color.phylloAccent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: isAnimated ? barWidth(for: current.totalCalories, in: geometry) : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isAnimated)
                
                // Adjusted target marker
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2)
                    .offset(x: barWidth(for: adjusted.totalCalories, in: geometry) - 1)
                    .opacity(isAnimated ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.3), value: isAnimated)
            }
        }
        .frame(height: 8)
    }
    
    private func barWidth(for calories: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxCalories = Double(max(adjusted.totalCalories, original?.totalCalories ?? 0)) * 1.2
        guard maxCalories > 0 else { return 0 }
        return (CGFloat(calories) / CGFloat(maxCalories)) * geometry.size.width
    }
}

// MARK: - Standard Progress Bars

struct StandardProgressBars: View {
    let current: MacroTargets
    let target: MacroTargets
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.05))
                
                // Progress
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.phylloAccent)
                    .frame(width: progressWidth(in: geometry))
            }
        }
        .frame(height: 8)
    }
    
    private func progressWidth(in geometry: GeometryProxy) -> CGFloat {
        guard target.totalCalories > 0 else { return 0 }
        let progress = min(1, CGFloat(current.totalCalories) / CGFloat(target.totalCalories))
        return progress * geometry.size.width
    }
}

// MARK: - Redistributed Macro Indicator

struct RedistributedMacroIndicator: View {
    let label: String
    let current: Int
    let target: Int
    let original: Int?
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 2) {
                Text("\(current)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("/")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
                
                // Show adjusted target with original crossed out
                if let original = original, original != target {
                    Text("\(original)g")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                        .strikethrough()
                    
                    Text("\(target)g")
                        .font(.caption.weight(.medium))
                        .foregroundColor(color)
                } else {
                    Text("\(target)g")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Redistribution Details Panel

struct RedistributionDetailsPanel: View {
    let reason: String
    let originalMacros: MacroTargets?
    let adjustedMacros: MacroTargets
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
            
            // Reason explanation
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.phylloAccent)
                
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            
            // Before/After comparison
            if let original = originalMacros {
                HStack(spacing: 20) {
                    MacroComparison(
                        label: "Original",
                        macros: original,
                        color: .white.opacity(0.3)
                    )
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                    
                    MacroComparison(
                        label: "Adjusted",
                        macros: adjustedMacros,
                        color: .phylloAccent
                    )
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
                .frame(height: 8)
        }
        .background(Color.white.opacity(0.02))
    }
}

// MARK: - Macro Comparison

struct MacroComparison: View {
    let label: String
    let macros: MacroTargets
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(color)
            
            Text("\(macros.totalCalories) cal")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
            
            Text("P: \(macros.protein)g | C: \(macros.carbs)g | F: \(macros.fat)g")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}
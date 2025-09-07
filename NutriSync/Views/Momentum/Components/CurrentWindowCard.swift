import SwiftUI

struct CurrentWindowCard: View {
    @State private var isVisible = false
    let window: MealWindow
    @ObservedObject var viewModel: NutritionDashboardViewModel
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text(window.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(PerformanceDesignSystem.textPrimary)
                    
                    Spacer()
                    
                    // Time remaining pill
                    let remaining = timeRemaining(until: window.endTime)
                    Text(remaining)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PerformanceDesignSystem.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // Progress
                HStack(spacing: 12) {
                    // Calories consumed
                    let consumedCalories = viewModel.caloriesConsumedInWindow(window)
                    Label {
                        Text("\(consumedCalories) / \(window.targetCalories) cal")
                            .font(.system(size: 14))
                    } icon: {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(PerformanceDesignSystem.textSecondary)
                    
                    // Protein progress
                    let consumedProtein = viewModel.mealsInWindow(window).reduce(0) { $0 + $1.protein }
                    if consumedProtein > 0 || window.targetProtein > 0 {
                        Label {
                            Text("\(consumedProtein)g / \(window.targetProtein)g")
                                .font(.system(size: 14))
                        } icon: {
                            Image(systemName: "p.circle.fill")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(PerformanceDesignSystem.textSecondary)
                    }
                }
                
                // Visual progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        let consumedCalories = viewModel.caloriesConsumedInWindow(window)
                        let progress = min(CGFloat(consumedCalories) / CGFloat(max(window.targetCalories, 1)), 1.0)
                        Rectangle()
                            .fill(progressColor(for: progress))
                            .frame(width: geometry.size.width * progress, height: 4)
                            .cornerRadius(2)
                    }
                }
                .frame(height: 4)
                
                // Action hint
                let consumedCalories = viewModel.caloriesConsumedInWindow(window)
                if consumedCalories < window.targetCalories {
                    let remaining = window.targetCalories - consumedCalories
                    Text("Add \(remaining) calories to meet target")
                        .font(.system(size: 13))
                        .foregroundColor(PerformanceDesignSystem.textTertiary)
                } else if consumedCalories > window.targetCalories {
                    let excess = consumedCalories - window.targetCalories
                    Text("\(excess) calories over target")
                        .font(.system(size: 13))
                        .foregroundColor(PerformanceDesignSystem.warningMuted)
                } else {
                    Text("Target achieved! Great job")
                        .font(.system(size: 13))
                        .foregroundColor(PerformanceDesignSystem.successMuted)
                }
            }
        }
        .scaleEffect(isVisible ? 1 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            isVisible = true
        }
    }
    
    private func timeRemaining(until endTime: Date) -> String {
        let now = Date()
        let interval = endTime.timeIntervalSince(now)
        
        guard interval > 0 else { return "Ended" }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
    
    private func progressColor(for progress: CGFloat) -> Color {
        if progress < 0.3 {
            return PerformanceDesignSystem.errorMuted
        } else if progress < 0.7 {
            return PerformanceDesignSystem.warningMuted
        } else if progress <= 1.0 {
            return PerformanceDesignSystem.successMuted
        } else {
            // Over target
            return PerformanceDesignSystem.warningMuted
        }
    }
}
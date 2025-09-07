import SwiftUI

struct NextWindowCard: View {
    @State private var isVisible = false
    let window: MealWindow
    
    var body: some View {
        PerformanceCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(window.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(PerformanceDesignSystem.textPrimary)
                    
                    Text(formatTimeRange(window))
                        .font(.system(size: 13))
                        .foregroundColor(PerformanceDesignSystem.textTertiary)
                }
                
                Spacer()
                
                // Status pill
                let timeUntil = window.startTime.timeIntervalSince(Date())
                let statusText = formatTimeUntil(timeUntil)
                let statusColor = getStatusColor(for: timeUntil)
                
                Text(statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .scaleEffect(isVisible ? 1 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.1), value: isVisible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isVisible = true
            }
        }
    }
    
    private func formatTimeRange(_ window: MealWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        return "\(formatter.string(from: window.startTime)) - \(formatter.string(from: window.endTime))"
    }
    
    private func formatTimeUntil(_ interval: TimeInterval) -> String {
        guard interval > 0 else { return "Active" }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 12 {
            return "Tomorrow"
        } else if hours > 0 {
            return "In \(hours)h"
        } else if minutes > 0 {
            return "In \(minutes)m"
        } else {
            return "Soon"
        }
    }
    
    private func getStatusColor(for interval: TimeInterval) -> Color {
        if interval < 0 {
            // Window has started
            return PerformanceDesignSystem.successMuted
        } else if interval < 1800 {
            // Within 30 minutes
            return PerformanceDesignSystem.warningMuted
        } else {
            // More than 30 minutes away
            return PerformanceDesignSystem.textSecondary
        }
    }
}
import SwiftUI

struct PerformancePillarCard: View {
    @State private var progressValue: CGFloat = 0
    let title: String
    let value: Int
    let trend: TrendDirection
    let trendValue: String
    let status: PerformanceStatus
    let message: String?
    
    enum TrendDirection {
        case up, down, stable
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }
    
    enum PerformanceStatus {
        case excellent, good, needsWork
        var color: Color {
            switch self {
            case .excellent: return PerformanceDesignSystem.successMuted
            case .good: return PerformanceDesignSystem.textSecondary
            case .needsWork: return PerformanceDesignSystem.warningMuted
            }
        }
    }
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 8) {
                // Label
                Text(title.uppercased())
                    .font(PerformanceDesignSystem.labelFont)
                    .foregroundColor(PerformanceDesignSystem.textTertiary)
                
                // Value
                Text("\(value)%")
                    .font(PerformanceDesignSystem.valueFont)
                    .foregroundColor(status.color)
                
                // Trend
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10))
                    Text(trendValue)
                        .font(PerformanceDesignSystem.trendFont)
                }
                .foregroundColor(PerformanceDesignSystem.textSecondary)
                
                // Contextual message
                if let message = message {
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(PerformanceDesignSystem.textTertiary)
                        .lineLimit(1)
                }
                
                // Progress bar (subtle)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(status.color.opacity(0.6))
                            .frame(width: geometry.size.width * progressValue, height: 4)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressValue)
                    }
                }
                .frame(height: 4)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                progressValue = CGFloat(value) / 100
            }
        }
        .onChange(of: value) { _, newValue in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                progressValue = CGFloat(newValue) / 100
            }
        }
    }
}
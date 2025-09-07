import SwiftUI

struct PerformanceInsightCard: View {
    @State private var isVisible = false
    let insight: String
    let action: String?
    var onAction: (() -> Void)?
    
    var body: some View {
        PerformanceCard {
            VStack(alignment: .leading, spacing: 8) {
                // Header with icon
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow.opacity(0.6))
                    
                    Text("INSIGHT")
                        .font(PerformanceDesignSystem.labelFont)
                        .foregroundColor(PerformanceDesignSystem.textTertiary)
                }
                
                // Insight text
                Text(insight)
                    .font(.system(size: 14))
                    .foregroundColor(PerformanceDesignSystem.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
                
                // Action button if provided
                if let action = action {
                    Button(action: {
                        onAction?()
                    }) {
                        HStack(spacing: 4) {
                            Text(action)
                                .font(.system(size: 13, weight: .medium))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(PerformanceDesignSystem.successMuted)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .scaleEffect(isVisible ? 1 : 0.95)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2), value: isVisible)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isVisible = true
            }
        }
    }
}
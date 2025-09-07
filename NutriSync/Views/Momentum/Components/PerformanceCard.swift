import SwiftUI

struct PerformanceCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(PerformanceDesignSystem.cardPadding)
            .background(PerformanceDesignSystem.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PerformanceDesignSystem.cornerRadius)
                    .stroke(PerformanceDesignSystem.cardBorder, lineWidth: PerformanceDesignSystem.borderWidth)
            )
            .cornerRadius(PerformanceDesignSystem.cornerRadius)
    }
}
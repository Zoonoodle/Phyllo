import SwiftUI
import UIKit

struct DayPurposeCard: View {
    let dayPurpose: DayPurpose?
    @State private var expandedSections: Set<String> = []
    @State private var selectedCategory: StrategyCategory = .nutrition
    
    enum StrategyCategory: String, CaseIterable {
        case nutrition = "nutrition"
        case energy = "energy"
        case performance = "performance"
        case recovery = "recovery"
        
        var icon: String {
            switch self {
            case .nutrition: return "leaf.circle.fill"
            case .energy: return "bolt.circle.fill"
            case .performance: return "figure.run.circle.fill"
            case .recovery: return "moon.circle.fill"
            }
        }
        
        var title: String {
            switch self {
            case .nutrition: return "Nutrition"
            case .energy: return "Energy"
            case .performance: return "Performance"
            case .recovery: return "Recovery"
            }
        }
        
        var color: Color {
            switch self {
            case .nutrition: return .green
            case .energy: return .yellow
            case .performance: return .orange
            case .recovery: return .purple
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Today's Strategy")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Compact date
                Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            if let dayPurpose = dayPurpose {
                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(StrategyCategory.allCases, id: \.self) { category in
                            categoryPill(category)
                        }
                    }
                }
                
                // Content for selected category
                VStack(alignment: .leading, spacing: 12) {
                    // Icon and title
                    HStack(spacing: 10) {
                        Image(systemName: selectedCategory.icon)
                            .font(.system(size: 24))
                            .foregroundStyle(selectedCategory.color)
                        
                        Text(selectedCategory.title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                        
                        Spacer()
                    }
                    
                    // Content with better readability
                    Text(getStrategyContent(for: selectedCategory, from: dayPurpose))
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Key priorities as chips
                if !dayPurpose.keyPriorities.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top Priorities")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(dayPurpose.keyPriorities.prefix(3).enumerated()), id: \.offset) { index, priority in
                                    priorityChip(priority, index: index)
                                }
                            }
                        }
                    }
                }
            } else {
                // Empty state with better design
                VStack(spacing: 16) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(LinearGradient(
                            colors: [.phylloAccent, .phylloAccent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    VStack(spacing: 6) {
                        Text("Strategy Awaits")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                        
                        Text("Complete your morning check-in for today's personalized plan")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding(20)
        .background(Color.phylloCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func categoryPill(_ category: StrategyCategory) -> some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 14))
            
            Text(category.title)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(selectedCategory == category ? Color.black : category.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(selectedCategory == category ? category.color : category.color.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(category.color.opacity(0.3), lineWidth: selectedCategory == category ? 0 : 1)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedCategory = category
            }
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    private func priorityChip(_ priority: String, index: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(.phylloAccent)
            
            Text(simplifyPriorityText(priority))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.phylloAccent.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.phylloAccent.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func getStrategyContent(for category: StrategyCategory, from dayPurpose: DayPurpose) -> String {
        let content: String
        switch category {
        case .nutrition:
            content = dayPurpose.nutritionalStrategy
        case .energy:
            content = dayPurpose.energyManagement
        case .performance:
            content = dayPurpose.performanceOptimization
        case .recovery:
            content = dayPurpose.recoveryFocus
        }
        
        // Simplify and shorten the content
        return simplifyStrategyText(content)
    }
    
    private func simplifyStrategyText(_ text: String) -> String {
        // Take first 2 sentences or up to 150 characters
        let sentences = text.components(separatedBy: ". ")
        if sentences.count >= 2 {
            return sentences.prefix(2).joined(separator: ". ") + "."
        } else if text.count > 150 {
            let truncated = String(text.prefix(150))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return truncated + "..."
        }
        return text
    }
    
    private func simplifyPriorityText(_ text: String) -> String {
        // Shorten common priority phrases
        let replacements = [
            "Hit ": "",
            "target": "goal",
            "Prioritize": "",
            "Fuel workouts effectively with": "Smart",
            "targeted": "",
            "pre- and post-workout": "workout",
            "Maintain consistent": "",
            "by spacing meals appropriately": "",
            "throughout the day": "daily"
        ]
        
        var simplified = text
        for (old, new) in replacements {
            simplified = simplified.replacingOccurrences(of: old, with: new)
        }
        
        // Trim and capitalize
        simplified = simplified.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit to 30 characters
        if simplified.count > 30 {
            let truncated = String(simplified.prefix(27))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return truncated + "..."
        }
        
        return simplified
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        ScrollView {
            DayPurposeCard(
                dayPurpose: DayPurpose(
                    nutritionalStrategy: "Focus on protein-rich meals early in the day to support muscle recovery from yesterday's workout. Distribute carbohydrates strategically around your afternoon training session.",
                    energyManagement: "Maintain steady energy with balanced meals every 3-4 hours. Avoid large gaps between meals to prevent energy dips during critical work periods.",
                    performanceOptimization: "Pre-workout window at 2 PM should emphasize quick-digesting carbs. Post-workout window needs high protein with moderate carbs for optimal recovery.",
                    recoveryFocus: "Evening meals should be lighter with emphasis on anti-inflammatory foods. Include magnesium-rich foods to support sleep quality and muscle recovery.",
                    keyPriorities: [
                        "Hit 150g protein target",
                        "Time carbs around workout",
                        "Light dinner for better sleep"
                    ]
                )
            )
            .padding()
        }
    }
}
import SwiftUI

struct RedistributionLearningTip: View {
    let tip: LearningTip
    let onDismiss: () -> Void
    let onLearnMore: () -> Void
    
    @State private var isExpanded = false
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with icon and title
            HStack(spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(tip.briefDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            // Expandable detail section
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(tip.fullExplanation)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !tip.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Examples:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                            
                            ForEach(tip.examples, id: \.self) { example in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green.opacity(0.6))
                                    
                                    Text(example)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: onLearnMore) {
                            Label("Learn More", systemImage: "book.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Button(action: { 
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text("Got it")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
            
            // Expand/Collapse button
            if !isExpanded {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text("Tap to learn more")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.green.opacity(0.3),
                                    Color.mint.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}

// Learning tip data model
struct LearningTip: Identifiable {
    let id = UUID()
    let title: String
    let briefDescription: String
    let fullExplanation: String
    let examples: [String]
    let icon: String
    let category: TipCategory
    
    enum TipCategory {
        case redistribution
        case timing
        case macros
        case optimization
    }
}

// Pre-configured tips for redistribution
extension LearningTip {
    static let redistributionTips = [
        LearningTip(
            title: "Smart Proximity Adjustment",
            briefDescription: "Calories move to nearby windows first",
            fullExplanation: "When you miss or modify a meal, NutriSync intelligently redistributes those calories to windows closest in time. This maintains your metabolic rhythm and prevents energy gaps.",
            examples: [
                "Missed 10am meal → Extra calories at 12pm lunch",
                "Light dinner → Boost tomorrow's breakfast",
                "Skipped pre-workout → Enhanced post-workout meal"
            ],
            icon: "arrow.triangle.branch",
            category: .redistribution
        ),
        
        LearningTip(
            title: "25% Deviation Rule",
            briefDescription: "Automatic rebalancing when windows vary significantly",
            fullExplanation: "If any meal window deviates more than 25% from its target, NutriSync suggests redistributing calories to maintain your daily goals without overwhelming any single eating period.",
            examples: [
                "300 cal breakfast (target: 500) triggers suggestion",
                "800 cal lunch (target: 600) prompts rebalancing",
                "Consistently light dinners adapt future windows"
            ],
            icon: "chart.line.uptrend.xyaxis",
            category: .redistribution
        ),
        
        LearningTip(
            title: "Bedtime Buffer Protection",
            briefDescription: "Last meal stays 3+ hours before sleep",
            fullExplanation: "NutriSync protects your sleep quality by ensuring your final meal window ends at least 3 hours before bedtime, preventing late-night calorie dumps that could disrupt rest.",
            examples: [
                "10pm bedtime = last meal by 7pm",
                "Late dinner calories → Next day breakfast",
                "Evening snack limits automatically enforced"
            ],
            icon: "moon.stars",
            category: .timing
        ),
        
        LearningTip(
            title: "Workout Window Priority",
            briefDescription: "Pre/post-workout meals get special treatment",
            fullExplanation: "Meal windows around workouts are protected during redistribution to maintain performance. These windows keep their protein and carb ratios optimized for muscle recovery.",
            examples: [
                "Post-workout protein preserved during shifts",
                "Pre-workout carbs maintained for energy",
                "Recovery windows get redistribution priority"
            ],
            icon: "figure.strengthtraining.traditional",
            category: .optimization
        ),
        
        LearningTip(
            title: "Macro Preservation",
            briefDescription: "Protein stays consistent, carbs/fats adjust",
            fullExplanation: "During redistribution, NutriSync maintains at least 70% of each window's protein target while flexibly adjusting carbs and fats to meet calorie needs.",
            examples: [
                "40g protein target → minimum 28g maintained",
                "Carbs scale with window size changes",
                "Fats adjust to balance total calories"
            ],
            icon: "chart.pie",
            category: .macros
        )
    ]
    
    static func randomTip(for category: TipCategory? = nil) -> LearningTip {
        let tips = category != nil 
            ? redistributionTips.filter { $0.category == category }
            : redistributionTips
        return tips.randomElement() ?? redistributionTips[0]
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        RedistributionLearningTip(
            tip: LearningTip.redistributionTips[0],
            onDismiss: {},
            onLearnMore: {}
        )
        
        RedistributionLearningTip(
            tip: LearningTip.redistributionTips[1],
            onDismiss: {},
            onLearnMore: {}
        )
    }
    .padding()
    .background(Color.black)
}
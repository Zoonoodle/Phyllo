import SwiftUI
import UIKit

struct DayPurposeCard: View {
    let dayPurpose: DayPurpose?
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Strategy")
                .font(.headline)
                .foregroundStyle(.white)
            
            if let dayPurpose = dayPurpose {
                VStack(spacing: 12) {
                    expandableSection(
                        title: "🎯 Nutritional Strategy",
                        content: dayPurpose.nutritionalStrategy,
                        id: "nutrition"
                    )
                    
                    expandableSection(
                        title: "⚡ Energy Management",
                        content: dayPurpose.energyManagement,
                        id: "energy"
                    )
                    
                    expandableSection(
                        title: "💪 Performance Optimization",
                        content: dayPurpose.performanceOptimization,
                        id: "performance"
                    )
                    
                    expandableSection(
                        title: "🛌 Recovery Focus",
                        content: dayPurpose.recoveryFocus,
                        id: "recovery"
                    )
                    
                    if !dayPurpose.keyPriorities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Key Priorities")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            
                            ForEach(Array(dayPurpose.keyPriorities.prefix(3).enumerated()), id: \.offset) { index, priority in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.phylloAccent.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                    
                                    Text(priority)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day purpose will be generated during your morning check-in")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text("Complete your check-in to receive personalized daily nutrition strategy")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(Color.phylloCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func expandableSection(title: String, content: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                Image(systemName: expandedSections.contains(id) ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedSections.contains(id) {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
            }
            
            if expandedSections.contains(id) {
                Text(content)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
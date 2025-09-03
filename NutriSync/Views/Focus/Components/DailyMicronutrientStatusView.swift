import SwiftUI
import UIKit

struct DailyMicronutrientStatusView: View {
    let micronutrientStatus: [ScheduleViewModel.MicronutrientStatus]
    @State private var expandedNutrients: Set<String> = []
    
    private var significantNutrients: [ScheduleViewModel.MicronutrientStatus] {
        micronutrientStatus
            .filter { nutrient in
                nutrient.percentage < 80 || nutrient.percentage > 150
            }
            .sorted { abs($0.percentage - 100) > abs($1.percentage - 100) }
            .prefix(8)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Micronutrient Status")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                if !significantNutrients.isEmpty {
                    Text("\(significantNutrients.count) need attention")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            if significantNutrients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.phylloAccent)
                        
                        Text("All micronutrients within optimal range")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Text("Great job maintaining balanced nutrition!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.phylloAccent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 12) {
                    ForEach(significantNutrients, id: \.name) { nutrient in
                        DailyMicronutrientRow(
                            nutrient: nutrient,
                            isExpanded: expandedNutrients.contains(nutrient.name)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if expandedNutrients.contains(nutrient.name) {
                                    expandedNutrients.remove(nutrient.name)
                                } else {
                                    expandedNutrients.insert(nutrient.name)
                                }
                            }
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.phylloCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DailyMicronutrientRow: View {
    let nutrient: ScheduleViewModel.MicronutrientStatus
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var statusColor: Color {
        switch nutrient.status {
        case .deficient:
            return .red
        case .optimal:
            return .phylloAccent
        case .excess:
            return .orange
        }
    }
    
    private var statusIcon: String {
        switch nutrient.status {
        case .deficient:
            return "arrow.down.circle.fill"
        case .optimal:
            return "checkmark.circle.fill"
        case .excess:
            return "arrow.up.circle.fill"
        }
    }
    
    private var statusText: String {
        switch nutrient.status {
        case .deficient:
            return "Low"
        case .optimal:
            return "Optimal"
        case .excess:
            return "High"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
                
                Text(nutrient.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("\(Int(nutrient.percentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(statusColor)
                    
                    Text("•")
                        .foregroundStyle(.white.opacity(0.3))
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    if nutrient.recommendation != nil {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            
            if isExpanded, let recommendation = nutrient.recommendation {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendation")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.5))
                    
                    Text(recommendation)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(statusColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
            VStack(spacing: 20) {
                DailyMicronutrientStatusView(
                    micronutrientStatus: [
                        ScheduleViewModel.MicronutrientStatus(
                            name: "Vitamin D",
                            status: .deficient,
                            percentage: 45,
                            amount: 200,
                            unit: "IU",
                            recommendation: "Consider adding fatty fish like salmon or fortified dairy products. 15 minutes of midday sun exposure can also help."
                        ),
                        ScheduleViewModel.MicronutrientStatus(
                            name: "Iron",
                            status: .deficient,
                            percentage: 68,
                            amount: 12,
                            unit: "mg",
                            recommendation: "Add lean red meat, spinach, or fortified cereals. Pair with vitamin C sources for better absorption."
                        ),
                        ScheduleViewModel.MicronutrientStatus(
                            name: "Sodium",
                            status: .excess,
                            percentage: 185,
                            amount: 4200,
                            unit: "mg",
                            recommendation: "Reduce processed foods and restaurant meals. Choose fresh ingredients and season with herbs instead of salt."
                        ),
                        ScheduleViewModel.MicronutrientStatus(
                            name: "Magnesium",
                            status: .deficient,
                            percentage: 72,
                            amount: 280,
                            unit: "mg",
                            recommendation: "Include dark leafy greens, nuts, seeds, and whole grains in your next meals."
                        ),
                        ScheduleViewModel.MicronutrientStatus(
                            name: "Calcium",
                            status: .optimal,
                            percentage: 95,
                            amount: 950,
                            unit: "mg",
                            recommendation: nil
                        )
                    ]
                )
                
                DailyMicronutrientStatusView(
                    micronutrientStatus: [
                        ScheduleViewModel.MicronutrientStatus(
                            name: "All Nutrients",
                            status: .optimal,
                            percentage: 100,
                            amount: 0,
                            unit: "",
                            recommendation: nil
                        )
                    ]
                )
            }
            .padding()
        }
    }
}
//
//  MicroNutritionPage.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

// Fixed micronutrient mappings by window purpose
struct WindowMicronutrients {
    let primary: (name: String, icon: String)
    let secondary: (name: String, icon: String)
    let tertiary: (name: String, icon: String)
}

struct MicroNutritionPage: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    
    // Get aggregated micronutrient data from meals in this window
    private var micronutrientData: [(name: String, percentage: Double)] {
        var aggregated: [String: Double] = [:]
        
        // Get meals for this window
        let windowMeals = viewModel.mealsInWindow(window)
        
        // Aggregate micronutrients from all meals
        for meal in windowMeals {
            for (nutrientName, amount) in meal.micronutrients {
                aggregated[nutrientName, default: 0] += amount
            }
        }
        
        // Convert to percentages based on RDA
        var results: [(name: String, percentage: Double)] = []
        for (name, amount) in aggregated {
            if let nutrientInfo = MicronutrientData.getNutrient(byName: name) {
                let percentage = amount / nutrientInfo.averageRDA
                results.append((name: name, percentage: percentage))
            } else {
                // If nutrient not found in database, assume 100% RDA = 100 units
                results.append((name: name, percentage: amount / 100))
            }
        }
        
        return results.sorted { $0.name < $1.name }
    }
    
    // Get health impact petal scores
    private var petalScores: [(petal: HealthImpactPetal, score: Double)] {
        var scores: [HealthImpactPetal: (totalScore: Double, count: Int)] = [:]
        var antiNutrientPenalties: [HealthImpactPetal: Double] = [:]
        
        for (name, percentage) in micronutrientData {
            if let nutrientInfo = MicronutrientData.getNutrient(byName: name) {
                if nutrientInfo.isAntiNutrient {
                    // Calculate penalties
                    if let limit = nutrientInfo.dailyLimit, let severity = nutrientInfo.severity {
                        let consumed = percentage * nutrientInfo.averageRDA
                        let penalty = MicronutrientData.calculateAntiNutrientPenalty(
                            consumed: consumed,
                            limit: limit,
                            severity: severity
                        )
                        
                        for petal in nutrientInfo.healthImpacts {
                            antiNutrientPenalties[petal, default: 0] += penalty
                        }
                    }
                } else {
                    // Add positive contribution
                    for petal in nutrientInfo.healthImpacts {
                        scores[petal, default: (0, 0)].totalScore += percentage
                        scores[petal, default: (0, 0)].count += 1
                    }
                }
            }
        }
        
        // Calculate final scores
        var petalResults: [(petal: HealthImpactPetal, score: Double)] = []
        for petal in HealthImpactPetal.allCases {
            let (totalScore, count) = scores[petal] ?? (0, 0)
            let averageScore = count > 0 ? totalScore / Double(count) : 0
            let penalty = antiNutrientPenalties[petal] ?? 0
            let finalScore = max(0, averageScore - (penalty / 100))
            petalResults.append((petal: petal, score: finalScore))
        }
        
        return petalResults.sorted { $0.petal.displayOrder < $1.petal.displayOrder }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            HStack {
                Text("Phyllo Petals")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Hexagon flower visualization - wrapped to control size
            VStack {
                HexagonFlowerView(
                    micronutrients: micronutrientData,
                    userGoal: viewModel.userProfile.primaryGoal
                )
            }
            .frame(height: 180) // Match the height of calorie ring
            
            // Health impact petal bars
            HStack(spacing: 12) {
                ForEach(petalScores, id: \.petal) { petalScore in
                    HealthImpactBar(
                        petal: petalScore.petal,
                        score: petalScore.score,
                        isPrimaryForGoal: isGoalRelevantPetal(petalScore.petal, for: viewModel.userProfile.primaryGoal)
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 40) // Match macro page top padding
        .padding(.bottom, 34) // Match macro page bottom padding
    }
    
    // Helper function to determine goal relevance
    private func isGoalRelevantPetal(_ petal: HealthImpactPetal, for goal: NutritionGoal?) -> Bool {
        guard let goal = goal else { return false }
        
        switch goal {
        case .muscleGain:
            return petal == .strength || petal == .energy
        case .weightLoss:
            return petal == .energy || petal == .heart
        case .performanceFocus:
            return petal == .energy || petal == .focus
        case .athleticPerformance:
            return petal == .energy || petal == .heart || petal == .antioxidant
        case .betterSleep:
            return petal == .focus || petal == .antioxidant
        case .maintainWeight, .overallWellbeing:
            return false // All petals equally important
        }
    }
}

struct MicronutrientBar: View {
    let micronutrient: MicronutrientConsumption
    
    private var color: Color {
        switch micronutrient.percentage {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return Color.phylloAccent
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Micronutrient name at top
            Text(micronutrient.info.name)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            // Progress bar in middle (matching MacroProgressBar)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(micronutrient.percentage, 1)), height: 5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: micronutrient.percentage)
                }
            }
            .frame(height: 5)
            
            // Consumed / Target with unit on bottom
            Text(micronutrient.displayString)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

struct HealthImpactBar: View {
    let petal: HealthImpactPetal
    let score: Double
    let isPrimaryForGoal: Bool
    
    private var color: Color {
        petal.color
    }
    
    private var displayPercentage: Int {
        Int(score * 100)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Health impact icon and name at top
            VStack(spacing: 4) {
                Image(systemName: petal.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Text(petal.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                
                // Goal relevance indicator
                if isPrimaryForGoal {
                    Image(systemName: "target")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.phylloAccent)
                }
            }
            
            // Progress bar in middle
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(min(score, 1)), height: 5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: score)
                }
            }
            .frame(height: 5)
            
            // Score percentage on bottom
            Text("\(displayPercentage)%")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        if let window = viewModel.mealWindows.first {
            MicroNutritionPage(window: window, viewModel: viewModel)
                .padding()
        }
    }
}

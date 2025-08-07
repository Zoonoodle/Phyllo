//
//  MicroNutritionPage.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI
import Foundation

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
    
    // Get health impact petal scores (needed for HexagonFlowerView)
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
    
    // Get top micronutrients with their petal associations
    private var topMicronutrients: [(name: String, consumed: Double, percentage: Double, unit: String, petalColor: Color)] {
        var nutrients: [(name: String, consumed: Double, percentage: Double, unit: String, petalColor: Color)] = []
        
        for (name, percentage) in micronutrientData {
            if let nutrientInfo = MicronutrientData.getNutrient(byName: name) {
                // Skip anti-nutrients in the bar display
                if nutrientInfo.isAntiNutrient {
                    continue
                }
                
                let consumed = percentage * nutrientInfo.averageRDA
                
                // Get the primary petal color for this nutrient
                let petalColor = nutrientInfo.healthImpacts.first?.color ?? .gray
                
                nutrients.append((
                    name: name,
                    consumed: consumed,
                    percentage: percentage,
                    unit: nutrientInfo.unit,
                    petalColor: petalColor
                ))
            }
        }
        
        // Sort by percentage and take top 6-8 nutrients
        return Array(nutrients.sorted { $0.percentage > $1.percentage }.prefix(8))
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
                    userGoal: viewModel.userProfile.primaryGoal,
                    nutritionContexts: getCurrentContexts()
                )
            }
            .frame(height: 180) // Match the height of calorie ring
            
            // Micronutrient bars - show top micronutrients from meals
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topMicronutrients, id: \.name) { nutrient in
                        MicronutrientBarWithPetal(
                            name: nutrient.name,
                            consumed: nutrient.consumed,
                            percentage: nutrient.percentage,
                            unit: nutrient.unit,
                            petalColor: nutrient.petalColor
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
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
    
    // Determine current nutrition contexts based on window and time
    private func getCurrentContexts() -> [NutritionContext] {
        var contexts: [NutritionContext] = []
        let now = TimeProvider.shared.currentTime
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Morning context (6 AM - 10 AM)
        if hour >= 6 && hour < 10 {
            contexts.append(.morning)
        }
        
        // Check window purpose for workout context
        switch window.purpose {
        case .preworkout:
            // Assume workout is coming soon, so post-workout context doesn't apply yet
            break
        case .postworkout:
            // Calculate time since window start (approximating workout time)
            let timeElapsed = now.timeIntervalSince(window.startTime)
            contexts.append(.postWorkout(intensity: .moderate, timeElapsed: timeElapsed))
        default:
            break
        }
        
        // Pre-sleep context (after 8 PM)
        if hour >= 20 {
            let sleepTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
            let hoursUntilSleep = sleepTime.timeIntervalSince(now) / 3600
            contexts.append(.preSleep(hoursUntilSleep: max(0, hoursUntilSleep)))
        }
        
        // Check if this is a morning/metabolic boost window (often breaking fast)
        if window.purpose == .metabolicBoost && hour < 10 {
            contexts.append(.fasting)
        }
        
        return contexts
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

struct MicronutrientBarWithPetal: View {
    let name: String
    let consumed: Double
    let percentage: Double
    let unit: String
    let petalColor: Color
    
    private var progressColor: Color {
        switch percentage {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return Color.phylloAccent
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Micronutrient name at top
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Progress bar in middle
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 5)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * CGFloat(min(percentage, 1)), height: 5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: percentage)
                }
            }
            .frame(height: 5)
            
            // Amount and percentage on bottom
            VStack(spacing: 2) {
                Text(String(format: "%.1f%@", consumed, unit))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(petalColor)
                
                Text("\(Int(percentage * 100))%")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: 65)
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

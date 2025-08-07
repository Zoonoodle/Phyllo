//
//  HexagonFlowerView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct HexagonFlowerView: View {
    let micronutrients: [(name: String, percentage: Double)]
    var size: CGFloat = 180 // Default size, can be customized
    var showLabels: Bool = true // Option to show/hide labels
    var showPurposeText: Bool = true // Option to show/hide purpose text
    var userGoal: NutritionGoal? = nil // For showing goal-relevant badges
    var nutritionContexts: [NutritionContext] = [] // Context for smart evaluation
    
    @State private var selectedPetal: HealthImpactPetal? = nil
    @State private var showPetalDetail = false
    
    // Health impact petals with aggregated scores
    private var petalScores: [(petal: HealthImpactPetal, score: Double, isPrimaryForGoal: Bool)] {
        var scores: [HealthImpactPetal: (totalScore: Double, count: Int)] = [:]
        var antiNutrientPenalties: [HealthImpactPetal: Double] = [:]
        
        // Process regular nutrients
        for (name, percentage) in micronutrients {
            if let nutrientInfo = MicronutrientData.getNutrient(byName: name) {
                if nutrientInfo.isAntiNutrient {
                    // Calculate context-aware penalties for anti-nutrients
                    if let limit = nutrientInfo.dailyLimit, let severity = nutrientInfo.severity {
                        let consumed = percentage * limit // percentage is actually amount/RDA
                        let penalty = MicronutrientData.calculateContextAwarePenalty(
                            nutrientName: name,
                            consumed: consumed,
                            limit: limit,
                            severity: severity,
                            contexts: nutritionContexts
                        )
                        
                        // Apply penalty to relevant petals
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
        
        // Calculate final scores with penalties
        var petalResults: [(petal: HealthImpactPetal, score: Double, isPrimaryForGoal: Bool)] = []
        
        for petal in HealthImpactPetal.allCases {
            let (totalScore, count) = scores[petal] ?? (0, 0)
            let averageScore = count > 0 ? totalScore / Double(count) : 0
            let penalty = antiNutrientPenalties[petal] ?? 0
            let finalScore = max(0, averageScore - (penalty / 100)) // Convert penalty percentage to decimal
            
            let isPrimary = isGoalRelevantPetal(petal, for: userGoal)
            petalResults.append((petal: petal, score: finalScore, isPrimaryForGoal: isPrimary))
        }
        
        // Sort by display order
        return petalResults.sorted { $0.petal.displayOrder < $1.petal.displayOrder }
    }
    
    // Overall score is average of all petal scores
    private var overallScore: Int {
        guard !petalScores.isEmpty else { return 0 }
        let average = petalScores.reduce(0) { $0 + $1.score } / Double(petalScores.count)
        return Int(average * 100)
    }
    
    // Helper function to determine if a petal is relevant to user's goal
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
    
    // Create petal data for health impact categories
    private var petalData: [(color: Color, rotation: Double, petalName: String, icon: String, score: Double, isPrimaryForGoal: Bool)] {
        return petalScores.enumerated().map { index, petalInfo in
            let rotation = Double(index) * 60 // 6 petals at 60-degree intervals
            return (
                color: petalInfo.petal.color,
                rotation: rotation,
                petalName: petalInfo.petal.rawValue,
                icon: petalInfo.petal.icon,
                score: petalInfo.score,
                isPrimaryForGoal: petalInfo.isPrimaryForGoal
            )
        }
    }
    
    // Create labels for health impact petals
    private var petalLabels: [(name: String, rotation: Double)] {
        return petalScores.enumerated().map { index, petalInfo in
            (name: petalInfo.petal.rawValue, rotation: Double(index) * 60)
        }
    }
    
    
    private func colorForPercentage(_ percentage: Double) -> Color {
        switch percentage {
        case 0..<0.5: return .red
        case 0.5..<0.7: return .orange
        case 0.7..<0.9: return .yellow
        default: return Color.phylloAccent
        }
    }
    
    var body: some View {
        ZStack {
            // Hexagon petals (draw before circle for proper layering)
            ForEach(Array(petalData.enumerated()), id: \.offset) { index, petal in
                HealthImpactPetalView(
                    color: petal.color,
                    rotation: petal.rotation,
                    petalName: petal.petalName,
                    icon: petal.icon,
                    score: petal.score,
                    isPrimaryForGoal: petal.isPrimaryForGoal,
                    size: size,
                    showPurposeText: false // Don't show text to reduce clutter
                )
                .onTapGesture {
                    selectedPetal = petalScores[index].petal
                    showPetalDetail = true
                }
                .zIndex(selectedPetal == petalScores[index].petal ? 2 : 0)
                .scaleEffect(selectedPetal == petalScores[index].petal ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPetal)
            }
            
            // Center circle with overall score
            Circle()
                .fill(Color.phylloBackground)
                .frame(width: size * 0.45, height: size * 0.45) // Slightly smaller to give more room to petals
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 2) {
                        Text("\(overallScore)%")
                            .font(.system(size: size * 0.13, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Micros")
                            .font(.system(size: size * 0.07))
                            .foregroundColor(.white.opacity(0.5))
                    }
                )
                .zIndex(1)
        }
        .frame(width: size, height: size)
        .sheet(isPresented: $showPetalDetail) {
            if let petal = selectedPetal {
                PetalDetailView(
                    petal: petal,
                    micronutrients: getDetailedNutrientsForPetal(petal)
                )
                .presentationDetents([.medium])
                .presentationBackground(Color.phylloBackground)
            }
        }
    }
    
    // Get the specific micronutrients that contribute to a health impact petal
    private func getDetailedNutrientsForPetal(_ petal: HealthImpactPetal) -> [(name: String, amount: Double, percentage: Double)] {
        var nutrients: [(name: String, amount: Double, percentage: Double)] = []
        
        for (name, percentage) in micronutrients {
            if let nutrientInfo = MicronutrientData.getNutrient(byName: name) {
                if nutrientInfo.healthImpacts.contains(petal) {
                    let amount = percentage * nutrientInfo.averageRDA
                    nutrients.append((name: name, amount: amount, percentage: percentage))
                }
            }
        }
        
        return nutrients.sorted { $0.percentage > $1.percentage }
    }
}

struct HealthImpactPetalView: View {
    let color: Color
    let rotation: Double
    let petalName: String
    let icon: String
    let score: Double
    let isPrimaryForGoal: Bool
    var size: CGFloat = 180 // Parent size
    var showPurposeText: Bool = true
    
    // Calculate opacity based on score - similar to ring effect
    private var fillOpacity: Double {
        // Start very transparent (0.05) and gradually increase to 0.3 at 100%
        let minOpacity = 0.05
        let maxOpacity = 0.3
        return minOpacity + (maxOpacity - minOpacity) * score
    }
    
    private var strokeOpacity: Double {
        // Stroke starts invisible and becomes fully visible at 50%
        if score < 0.5 {
            return score * 2 // 0-0.5 maps to 0-1 opacity
        } else {
            return 1.0
        }
    }
    
    var body: some View {
        HexagonShape()
            .fill(color.opacity(fillOpacity))
            .overlay(
                HexagonShape()
                    .stroke(color.opacity(strokeOpacity), lineWidth: 2)
            )
            .overlay(
                // Health impact icon and name inside petal
                ZStack {
                    VStack(spacing: 2) {
                        if !icon.isEmpty {
                            Image(systemName: icon)
                                .font(.system(size: size * 0.08, weight: .medium))
                                .foregroundColor(.white.opacity(score > 0.3 ? 1.0 : score * 3))
                                .rotationEffect(.degrees(-rotation)) // Counter-rotate to keep upright
                        }
                        
                        if showPurposeText && score > 0.3 {
                            Text(petalName)
                                .font(.system(size: size * 0.045, weight: .medium))
                                .foregroundColor(.white.opacity(score > 0.5 ? 1.0 : score * 2))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.5)
                                .rotationEffect(.degrees(-rotation)) // Counter-rotate to keep upright
                        }
                    }
                    
                    // Goal relevance badge (top-right corner)
                    if isPrimaryForGoal {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "target")
                                    .font(.system(size: size * 0.05, weight: .bold))
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.phylloAccent)
                                            .frame(width: size * 0.08, height: size * 0.08)
                                    )
                                    .rotationEffect(.degrees(-rotation)) // Counter-rotate to keep upright
                            }
                            Spacer()
                        }
                        .padding(size * 0.02)
                    }
                }
            )
            .frame(width: size * 0.33, height: size * 0.4)
            .scaleEffect(0.85) // Slightly smaller to allow more spacing
            .offset(x: size * 0.35) // Increased offset to space out petals more
            .rotationEffect(.degrees(rotation))
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: rotation)
    }
}

struct PetalDetailView: View {
    let petal: HealthImpactPetal
    let micronutrients: [(name: String, amount: Double, percentage: Double)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        Image(systemName: petal.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(petal.color)
                        
                        Text(petal.rawValue)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Contributing Micronutrients")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // Micronutrients list
            ScrollView {
                VStack(spacing: 16) {
                    if micronutrients.isEmpty {
                        Text("No micronutrients tracked for this health impact")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.vertical, 40)
                    } else {
                        ForEach(micronutrients, id: \.name) { nutrient in
                            PetalMicronutrientRow(
                                name: nutrient.name,
                                amount: nutrient.amount,
                                percentage: nutrient.percentage,
                                color: petal.color
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.phylloBackground)
    }
}

struct PetalMicronutrientRow: View {
    let name: String
    let amount: Double
    let percentage: Double
    let color: Color
    
    private var unit: String {
        if let info = MicronutrientData.getNutrient(byName: name) {
            return info.unit
        }
        return "mg"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: "%.1f%@", amount, unit))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * min(percentage, 1), height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(Int(percentage * 100))% of daily target")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.phylloElevated)
        )
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        let radius = min(width, height) / 2
        
        var path = Path()
        
        for i in 0..<6 {
            let angle = (Double(i) * 60 - 30) * .pi / 180
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct PetalLabel: View {
    let text: String
    let rotation: Double
    let offset: CGFloat
    var size: CGFloat = 180 // Parent size for scaling
    
    // Determine if text should be on left or right side based on rotation
    private var isLeftSide: Bool {
        let normalizedRotation = rotation.truncatingRemainder(dividingBy: 360)
        // Fix the logic: 120-240 degrees should have text on left
        return normalizedRotation >= 120 && normalizedRotation <= 240
    }
    
    // Determine if arrow should point vertically
    private var isVertical: Bool {
        let normalizedRotation = rotation.truncatingRemainder(dividingBy: 360)
        return (normalizedRotation >= 45 && normalizedRotation <= 135) || 
               (normalizedRotation >= 225 && normalizedRotation <= 315)
    }
    
    var body: some View {
        Group {
            if isLeftSide {
                // Text on left, arrow pointing right
                HStack(spacing: 4) {
                    Text(text)
                        .font(.system(size: size * 0.06, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    ArrowShape(pointingLeft: false, isVertical: isVertical)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 15, height: 15)
                }
            } else {
                // Arrow pointing left, text on right
                HStack(spacing: 4) {
                    ArrowShape(pointingLeft: true, isVertical: isVertical)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 15, height: 15)
                    
                    Text(text)
                        .font(.system(size: size * 0.06, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .offset(x: offset * cos(rotation * .pi / 180), y: offset * sin(rotation * .pi / 180))
    }
}

struct ArrowShape: Shape {
    let pointingLeft: Bool
    let isVertical: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isVertical {
            // Vertical arrow
            let midX = rect.midX
            path.move(to: CGPoint(x: midX, y: pointingLeft ? rect.maxY : rect.minY))
            path.addLine(to: CGPoint(x: midX, y: pointingLeft ? rect.minY : rect.maxY))
            
            // Arrowhead
            if pointingLeft {
                path.move(to: CGPoint(x: midX - 3, y: rect.minY + 3))
                path.addLine(to: CGPoint(x: midX, y: rect.minY))
                path.addLine(to: CGPoint(x: midX + 3, y: rect.minY + 3))
            } else {
                path.move(to: CGPoint(x: midX - 3, y: rect.maxY - 3))
                path.addLine(to: CGPoint(x: midX, y: rect.maxY))
                path.addLine(to: CGPoint(x: midX + 3, y: rect.maxY - 3))
            }
        } else {
            // Horizontal arrow
            let midY = rect.midY
            path.move(to: CGPoint(x: pointingLeft ? rect.maxX : rect.minX, y: midY))
            path.addLine(to: CGPoint(x: pointingLeft ? rect.minX : rect.maxX, y: midY))
            
            // Arrowhead
            if pointingLeft {
                path.move(to: CGPoint(x: rect.minX + 3, y: midY - 3))
                path.addLine(to: CGPoint(x: rect.minX, y: midY))
                path.addLine(to: CGPoint(x: rect.minX + 3, y: midY + 3))
            } else {
                path.move(to: CGPoint(x: rect.maxX - 3, y: midY - 3))
                path.addLine(to: CGPoint(x: rect.maxX, y: midY))
                path.addLine(to: CGPoint(x: rect.maxX - 3, y: midY + 3))
            }
        }
        
        return path
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("Health Impact Petal System")
                .font(.title2)
                .foregroundColor(.white)
            
            // Good nutrition with muscle building goal
            HexagonFlowerView(
                micronutrients: [
                    ("Vitamin B12", 0.82),
                    ("Iron", 0.91),
                    ("Magnesium", 0.78),
                    ("Vitamin D", 0.65),
                    ("Omega-3", 0.45),
                    ("Zinc", 0.88),
                    ("Calcium", 0.72),
                    ("Vitamin C", 0.85),
                    ("Protein", 0.92)
                ],
                userGoal: .muscleGain(targetPounds: 10, timeline: 12)
            )
            
            // Poor nutrition with anti-nutrients
            HexagonFlowerView(
                micronutrients: [
                    ("Vitamin B12", 0.10),
                    ("Iron", 0.25),
                    ("Sodium", 1.8), // Anti-nutrient above limit
                    ("Added Sugar", 1.5), // Anti-nutrient above limit
                    ("Vitamin D", 0.15),
                    ("Omega-3", 0.20)
                ],
                userGoal: .performanceFocus
            )
        }
    }
}
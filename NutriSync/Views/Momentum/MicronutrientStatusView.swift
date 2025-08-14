//
//  MicronutrientStatusView.swift
//  NutriSync
//
//  Created on 2/2/25.
//
//  Enhanced micronutrient display with smart prioritization and full grid view

import SwiftUI

// MARK: - Prioritized Nutrient Model

struct PrioritizedNutrient {
    let status: InsightsEngine.MicronutrientStatus.NutrientStatus
    let priorityScore: Double
    let priorityReason: String
}

// MARK: - Nutrient Prioritization Engine

struct NutrientPrioritizationEngine {
    static func getPrioritizedNutrients(
        from status: InsightsEngine.MicronutrientStatus,
        userGoal: NutritionGoal?,
        currentWindow: MealWindow?,
        currentTime: Date = Date(),
        maxCount: Int = 4
    ) -> [PrioritizedNutrient] {
        
        var scoredNutrients: [(nutrient: InsightsEngine.MicronutrientStatus.NutrientStatus, score: Double, reason: String)] = []
        
        // Process both good nutrients and anti-nutrients
        for nutrientStatus in status.nutrients {
            guard let info = MicronutrientData.getNutrient(byName: nutrientStatus.nutrient.name) else { continue }
            
            var score = 0.0
            var reasons: [String] = []
            
            if info.isAntiNutrient {
                // Anti-nutrient scoring
                let guidanceLevel = info.getGuidanceLevel(consumed: nutrientStatus.consumed)
                if guidanceLevel == .critical {
                    score += 100
                    reasons.append("Critical level")
                } else if guidanceLevel == .excessive {
                    score += 70
                    reasons.append("Excessive intake")
                }
            } else {
                // Good nutrient scoring
                
                // 1. Deficiency score (highest priority)
                if nutrientStatus.percentageOfRDA < 30 {
                    score += (30 - nutrientStatus.percentageOfRDA) * 3 // Triple weight for severe deficiency
                    reasons.append("Severely low")
                } else if nutrientStatus.percentageOfRDA < 50 {
                    score += (50 - nutrientStatus.percentageOfRDA) * 2 // Double weight
                    reasons.append("Low intake")
                } else if nutrientStatus.percentageOfRDA < 80 {
                    score += (80 - nutrientStatus.percentageOfRDA) * 1
                    reasons.append("Below target")
                }
                
                // 2. Goal relevance score
                if let goal = userGoal {
                    let goalScore = calculateGoalRelevanceScore(nutrient: info, goal: goal)
                    if goalScore > 0 {
                        score += goalScore
                        reasons.append("Important for \(goal.displayName.lowercased())")
                    }
                }
                
                // 3. Window relevance score
                if let window = currentWindow {
                    let windowScore = calculateWindowRelevanceScore(nutrient: info, window: window, currentTime: currentTime)
                    if windowScore > 0 {
                        score += windowScore
                        reasons.append("Key for \(window.purpose.displayName.lowercased())")
                    }
                }
                
                // 4. Time of day relevance
                let timeScore = calculateTimeRelevanceScore(nutrient: info, currentTime: currentTime)
                if timeScore > 0 {
                    score += timeScore
                }
            }
            
            if score > 0 {
                let primaryReason = reasons.first ?? "Monitor intake"
                scoredNutrients.append((nutrient: nutrientStatus, score: score, reason: primaryReason))
            }
        }
        
        // Sort by score and take top N
        return scoredNutrients
            .sorted { $0.score > $1.score }
            .prefix(maxCount)
            .map { PrioritizedNutrient(status: $0.nutrient, priorityScore: $0.score, priorityReason: $0.reason) }
    }
    
    private static func calculateGoalRelevanceScore(nutrient: MicronutrientInfo, goal: NutritionGoal) -> Double {
        var relevantPetals: Set<HealthImpactPetal> = []
        
        switch goal {
        case .muscleGain:
            relevantPetals = [.strength, .energy]
        case .weightLoss:
            relevantPetals = [.energy, .heart]
        case .performanceFocus:
            relevantPetals = [.energy, .focus]
        case .athleticPerformance:
            relevantPetals = [.energy, .heart, .antioxidant, .strength]
        case .betterSleep:
            relevantPetals = [.focus, .antioxidant]
        case .maintainWeight, .overallWellbeing:
            return 10 // All nutrients equally important
        }
        
        // Check if nutrient impacts relevant petals
        let matchingPetals = Set(nutrient.healthImpacts).intersection(relevantPetals)
        return Double(matchingPetals.count) * 15
    }
    
    private static func calculateWindowRelevanceScore(nutrient: MicronutrientInfo, window: MealWindow, currentTime: Date) -> Double {
        // Check if we're currently in this window
        let isActive = window.contains(timestamp: currentTime)
        let multiplier = isActive ? 2.0 : 1.0
        
        var score = 0.0
        
        switch window.purpose {
        case .preworkout, .postworkout:
            if nutrient.healthImpacts.contains(.energy) || nutrient.healthImpacts.contains(.strength) {
                score = 20
            }
        case .sustainedEnergy:
            if nutrient.name.contains("B") || nutrient.name == "Iron" {
                score = 20
            }
        case .recovery:
            if nutrient.name == "Magnesium" || nutrient.name == "Zinc" || nutrient.healthImpacts.contains(.strength) {
                score = 20
            }
        case .focusBoost:
            if nutrient.healthImpacts.contains(.focus) || nutrient.name.contains("B12") || nutrient.name == "Omega-3" {
                score = 20
            }
        case .metabolicBoost:
            if nutrient.healthImpacts.contains(.energy) {
                score = 15
            }
        case .sleepOptimization:
            if nutrient.name == "Magnesium" || nutrient.name == "Calcium" {
                score = 25
            }
        default:
            // Check for other relevant impacts
            if nutrient.healthImpacts.contains(.immune) {
                score = 15
            } else {
                score = 0
            }
        }
        
        return score * multiplier
    }
    
    private static func calculateTimeRelevanceScore(nutrient: MicronutrientInfo, currentTime: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: currentTime)
        
        // Morning (6 AM - 12 PM): Energy nutrients
        if hour >= 6 && hour < 12 {
            if nutrient.healthImpacts.contains(.energy) || nutrient.name.contains("B") {
                return 10
            }
        }
        
        // Evening (6 PM - 10 PM): Sleep-supporting nutrients
        if hour >= 18 && hour < 22 {
            if nutrient.name == "Magnesium" || nutrient.name == "Calcium" {
                return 15
            }
        }
        
        return 0
    }
}

struct MicronutrientStatusView: View {
    let status: InsightsEngine.MicronutrientStatus
    var userGoal: NutritionGoal? = nil
    var currentWindow: MealWindow? = nil
    
    @State private var expandedNutrients: Set<String> = []
    @State private var showAllNutrients = false
    @State private var selectedNutrient: InsightsEngine.MicronutrientStatus.NutrientStatus?
    @State private var expandedPriorityCards: Set<String> = []
    @State private var animateIn = false
    
    // Get prioritized nutrients
    private var prioritizedNutrients: [PrioritizedNutrient] {
        NutrientPrioritizationEngine.getPrioritizedNutrients(
            from: status,
            userGoal: userGoal,
            currentWindow: currentWindow
        )
    }
    
    // Convert to micronutrient data format for HexagonFlowerView
    private var micronutrientData: [(name: String, percentage: Double)] {
        status.nutrients.map { nutrientStatus in
            (name: nutrientStatus.nutrient.name, percentage: nutrientStatus.percentageOfRDA / 100)
        }
    }
    
    // Get overall score for center display
    private var overallScore: Int {
        let average = status.nutrients.reduce(0) { $0 + $1.percentageOfRDA } / Double(status.nutrients.count)
        return Int(average)
    }
    
    // Keep legacy properties for backward compatibility
    private var goodNutrients: [(status: InsightsEngine.MicronutrientStatus.NutrientStatus, info: MicronutrientInfo)] {
        status.nutrients.compactMap { nutrientStatus in
            guard let info = MicronutrientData.getNutrient(byName: nutrientStatus.nutrient.name),
                  !info.isAntiNutrient else { return nil }
            return (status: nutrientStatus, info: info)
        }
    }
    
    private var antiNutrients: [(name: String, consumed: Double, info: MicronutrientInfo)] {
        status.nutrients.compactMap { nutrientStatus in
            guard let info = MicronutrientData.getNutrient(byName: nutrientStatus.nutrient.name),
                  info.isAntiNutrient else { return nil }
            return (name: nutrientStatus.nutrient.name, consumed: nutrientStatus.consumed, info: info)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Nutrient Status")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Hexagon Flower Visualization
            HexagonFlowerView(
                micronutrients: micronutrientData,
                size: 220,
                showLabels: false,
                showPurposeText: false,
                userGoal: userGoal
            )
            .frame(height: 200)
            .padding(.top, 4)
            .opacity(animateIn ? 1 : 0)
            .scaleEffect(animateIn ? 1 : 0.8)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateIn)
            
            // Smart Priority Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Nutrients Needing Attention")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    if !prioritizedNutrients.isEmpty {
                        Text("\(prioritizedNutrients.count) priority")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                
                if prioritizedNutrients.isEmpty {
                    // All nutrients are adequate
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("All nutrients are at healthy levels!")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                } else {
                    // Priority nutrient cards
                    VStack(spacing: 12) {
                        ForEach(Array(prioritizedNutrients.enumerated()), id: \.element.status.nutrient.id) { index, prioritized in
                            PriorityNutrientCard(
                                prioritized: prioritized,
                                isExpanded: expandedPriorityCards.contains(prioritized.status.nutrient.id.uuidString),
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if expandedPriorityCards.contains(prioritized.status.nutrient.id.uuidString) {
                                            expandedPriorityCards.remove(prioritized.status.nutrient.id.uuidString)
                                        } else {
                                            expandedPriorityCards.insert(prioritized.status.nutrient.id.uuidString)
                                        }
                                    }
                                }
                            )
                            .opacity(animateIn ? 1 : 0)
                            .offset(y: animateIn ? 0 : 20)
                            .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: animateIn)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // View All Nutrients Button
                Button(action: {
                    showAllNutrients = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.grid.3x3")
                            .font(.system(size: 16))
                        
                        Text("View All Nutrients")
                            .font(.system(size: 15, weight: .medium))
                        
                        Spacer()
                        
                        Text("\(status.nutrients.count)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .foregroundColor(.white)
                    .padding(16)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 20)
        .background(Color.nutriSyncBackground)
        .cornerRadius(20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animateIn = true
            }
        }
        .sheet(isPresented: $showAllNutrients) {
            AllNutrientsView(
                status: status,
                selectedNutrient: $selectedNutrient
            )
            .presentationBackground(Color.nutriSyncBackground)
        }
    }
}

// MARK: - Deficiency Alert

struct DeficiencyAlertCard: View {
    let deficiencies: [InsightsEngine.MicronutrientStatus.NutrientStatus]
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 24))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Low Nutrients Detected")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(deficiencies.count) nutrients below recommended levels")
                    .font(.system(size: 14))
                    .foregroundColor(.nutriSyncTextSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Micronutrient Guidance Row

struct MicronutrientGuidanceRow: View {
    let nutrientStatus: InsightsEngine.MicronutrientStatus.NutrientStatus
    let nutrientInfo: MicronutrientInfo
    let guidanceLevel: NutrientGuidanceLevel
    let isExpanded: Bool
    let onTap: () -> Void
    
    // Get icon emoji based on nutrient name
    private var nutrientIcon: String {
        let icons: [String: String] = [
            "Iron": "💧",
            "Vitamin D": "☀️",
            "Calcium": "🦴",
            "B12": "⚡",
            "Folate": "🍃",
            "Zinc": "🛡️",
            "Vitamin C": "🍊",
            "Magnesium": "💪",
            "Vitamin A": "👁️",
            "Omega-3": "🐟",
            "Potassium": "🍌",
            "Vitamin E": "✨",
            "Sodium": "🧂",
            "Added Sugar": "🍬",
            "Saturated Fat": "🧈",
            "Trans Fat": "⚠️",
            "Cholesterol": "🥚",
            "Caffeine": "☕"
        ]
        return icons[nutrientStatus.nutrient.name] ?? "💊"
    }
    
    private var guidanceColor: Color {
        switch guidanceLevel {
        case .needsMore:
            return .orange
        case .adequate:
            return .green
        case .excessive:
            return .orange
        case .critical:
            return .red
        }
    }
    
    private var guidanceIcon: String {
        switch guidanceLevel {
        case .needsMore:
            return "arrow.up.circle.fill"
        case .adequate:
            return "checkmark.circle.fill"
        case .excessive:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var guidanceText: String {
        switch guidanceLevel {
        case .needsMore:
            return "Eat more"
        case .adequate:
            return "Good"
        case .excessive:
            return "High"
        case .critical:
            return "Too high"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 16) {
                // Icon
                Text(nutrientIcon)
                    .font(.system(size: 24))
                
                // Name and guidance
                VStack(alignment: .leading, spacing: 4) {
                    Text(nutrientStatus.nutrient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Image(systemName: guidanceIcon)
                            .font(.system(size: 12))
                        Text(guidanceText)
                            .font(.system(size: 13))
                    }
                    .foregroundColor(guidanceColor)
                }
                
                Spacer()
                
                // Amount and chevron
                HStack(spacing: 8) {
                    Text(String(format: "%.0f%@", nutrientStatus.consumed, nutrientStatus.nutrient.unit))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(16)
            .background(
                Group {
                    if isExpanded {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 16
                        )
                        .fill(guidanceColor.opacity(0.1))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(guidanceColor.opacity(0.1))
                    }
                }
            )
            .onTapGesture(perform: onTap)
            
            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Consumed vs Target/Limit
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Consumed")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(String(format: "%.1f", nutrientStatus.consumed))\(nutrientStatus.nutrient.unit)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(nutrientInfo.isAntiNutrient ? "Daily Limit" : "Daily Goal")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(String(format: "%.1f", nutrientStatus.nutrient.rda))\(nutrientStatus.nutrient.unit)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Guidance message
                    if guidanceLevel == .needsMore {
                        let foodSources = InsightsEngine.shared.getFoodsRichIn(nutrient: nutrientStatus.nutrient.name)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Good sources:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(foodSources, id: \.self) { food in
                                        Text(food)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(guidanceColor.opacity(0.2))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(guidanceColor.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    } else if guidanceLevel == .excessive || guidanceLevel == .critical {
                        Text(nutrientInfo.isAntiNutrient ? 
                            "Try to reduce intake of processed foods and choose whole foods instead." :
                            "You're consuming high amounts of this nutrient. Consider moderating intake.")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(guidanceColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 0
                    )
                    .fill(guidanceColor.opacity(0.05))
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(guidanceColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Micronutrient Row (OLD - keeping for reference)

struct MicronutrientRow: View {
    let nutrientStatus: InsightsEngine.MicronutrientStatus.NutrientStatus
    let isExpanded: Bool
    let onTap: () -> Void
    
    // Get icon emoji based on nutrient name
    private var nutrientIcon: String {
        let icons: [String: String] = [
            "Iron": "💧",
            "Vitamin D": "☀️",
            "Calcium": "🦴",
            "B12": "⚡",
            "Folate": "🍃",
            "Zinc": "🛡️",
            "Vitamin C": "🍊",
            "Magnesium": "💪",
            "Vitamin A": "👁️",
            "Omega-3": "🐟",
            "Potassium": "🍌",
            "Vitamin E": "✨"
        ]
        return icons[nutrientStatus.nutrient.name] ?? "💊"
    }
    
    // Get petal color based on health impact
    private var petalColor: Color {
        // Map nutrients to their primary health impact petal colors
        if let nutrientInfo = MicronutrientData.getNutrient(byName: nutrientStatus.nutrient.name) {
            return nutrientInfo.healthImpacts.first?.color ?? .gray
        }
        return .gray
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 16) {
                // Icon
                Text(nutrientIcon)
                    .font(.system(size: 24))
                
                // Name and percentage
                VStack(alignment: .leading, spacing: 4) {
                    Text(nutrientStatus.nutrient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(nutrientStatus.status.color)
                                .frame(width: geometry.size.width * min(1, nutrientStatus.percentageOfRDA / 100), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                
                Spacer()
                
                // Percentage and chevron
                HStack(spacing: 8) {
                    Text("\(Int(nutrientStatus.percentageOfRDA))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(nutrientStatus.status.color)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
            .padding(16)
            .background(
                Group {
                    if isExpanded {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 16,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 16
                        )
                        .fill(Color.white.opacity(0.03))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.03))
                    }
                }
            )
            .onTapGesture(perform: onTap)
            
            // Expanded detail
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Consumed vs RDA
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Consumed")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(String(format: "%.1f", nutrientStatus.consumed))\(nutrientStatus.nutrient.unit)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Daily Goal")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(String(format: "%.1f", nutrientStatus.nutrient.rda))\(nutrientStatus.nutrient.unit)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Food sources for deficient nutrients
                    if nutrientStatus.status == .deficient || nutrientStatus.status == .low {
                        let foodSources = InsightsEngine.shared.getFoodsRichIn(nutrient: nutrientStatus.nutrient.name)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Good sources:")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(foodSources, id: \.self) { food in
                                        Text(food)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(petalColor.opacity(0.2))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(petalColor.opacity(0.3), lineWidth: 1)
                                            )
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 16,
                        bottomTrailingRadius: 16,
                        topTrailingRadius: 0
                    )
                    .fill(Color.white.opacity(0.02))
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}


// MARK: - All Nutrients Grid

struct AllNutrientsGrid: View {
    let nutrients: [InsightsEngine.MicronutrientStatus.NutrientStatus]
    @Binding var selectedNutrient: InsightsEngine.MicronutrientStatus.NutrientStatus?
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(nutrients.sorted(by: { $0.percentageOfRDA < $1.percentageOfRDA }), id: \.nutrient.id) { nutrientStatus in
                    CompactNutrientCard(
                        status: nutrientStatus,
                        isSelected: selectedNutrient?.nutrient.id == nutrientStatus.nutrient.id,
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedNutrient = selectedNutrient?.nutrient.id == nutrientStatus.nutrient.id ? nil : nutrientStatus
                            }
                        }
                    )
                }
            }
        }
        .frame(maxHeight: 300)
    }
}

struct CompactNutrientCard: View {
    let status: InsightsEngine.MicronutrientStatus.NutrientStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Percentage with color coding
            Text("\(Int(status.percentageOfRDA))%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(status.status.color)
            
            // Nutrient abbreviation
            Text(abbreviatedName(status.nutrient.name))
                .font(.system(size: 11))
                .foregroundColor(.nutriSyncTextSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.status.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? status.status.color : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .onTapGesture(perform: onTap)
    }
    
    private func abbreviatedName(_ name: String) -> String {
        let abbreviations: [String: String] = [
            "Vitamin A": "Vit A",
            "Vitamin C": "Vit C",
            "Vitamin D": "Vit D",
            "Vitamin E": "Vit E",
            "Vitamin K": "Vit K",
            "B1 Thiamine": "B1",
            "B2 Riboflavin": "B2",
            "B3 Niacin": "B3",
            "B6": "B6",
            "B12": "B12",
            "Folate": "Folate",
            "Calcium": "Ca",
            "Iron": "Fe",
            "Magnesium": "Mg",
            "Zinc": "Zn",
            "Potassium": "K",
            "Omega-3": "Ω-3",
            "Fiber": "Fiber"
        ]
        return abbreviations[name] ?? name
    }
}

// MARK: - Nutrient Detail Card

struct NutrientDetailCard: View {
    let nutrientStatus: InsightsEngine.MicronutrientStatus.NutrientStatus
    
    private var foodSources: [String] {
        InsightsEngine.shared.getFoodsRichIn(nutrient: nutrientStatus.nutrient.name)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(nutrientStatus.nutrient.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: nutrientStatus.status.icon)
                    Text("\(Int(nutrientStatus.percentageOfRDA))% of RDA")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(nutrientStatus.status.color)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(nutrientStatus.status.color)
                        .frame(width: geometry.size.width * min(1, nutrientStatus.percentageOfRDA / 100), height: 8)
                }
            }
            .frame(height: 8)
            
            // Consumed vs RDA
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consumed")
                        .font(.system(size: 12))
                        .foregroundColor(.nutriSyncTextTertiary)
                    Text("\(String(format: "%.1f", nutrientStatus.consumed))\(nutrientStatus.nutrient.unit)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Daily Goal")
                        .font(.system(size: 12))
                        .foregroundColor(.nutriSyncTextTertiary)
                    Text("\(String(format: "%.1f", nutrientStatus.nutrient.rda))\(nutrientStatus.nutrient.unit)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.nutriSyncTextSecondary)
                }
            }
            
            // Food sources
            if nutrientStatus.status == .deficient || nutrientStatus.status == .low {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add these foods:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.nutriSyncTextSecondary)
                    
                    HStack(spacing: 8) {
                        ForEach(foodSources.prefix(3), id: \.self) { food in
                            Text(food)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(nutrientStatus.status.color.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// Extension to make InsightsEngine method accessible
extension InsightsEngine {
    func getFoodsRichIn(nutrient: String) -> [String] {
        let foodSources: [String: [String]] = [
            "Vitamin A": ["sweet potato", "carrots", "spinach"],
            "Vitamin C": ["oranges", "strawberries", "bell peppers"],
            "Vitamin D": ["salmon", "egg yolks", "fortified milk"],
            "Vitamin E": ["almonds", "sunflower seeds", "avocado"],
            "Vitamin K": ["kale", "broccoli", "brussels sprouts"],
            "B1 Thiamine": ["whole grains", "pork", "legumes"],
            "B2 Riboflavin": ["milk", "eggs", "almonds"],
            "B3 Niacin": ["chicken", "tuna", "peanuts"],
            "B6": ["chickpeas", "salmon", "potatoes"],
            "B12": ["beef", "eggs", "dairy"],
            "Folate": ["leafy greens", "beans", "citrus"],
            "Calcium": ["dairy", "tofu", "almonds"],
            "Iron": ["red meat", "spinach", "lentils"],
            "Magnesium": ["dark chocolate", "avocado", "nuts"],
            "Zinc": ["oysters", "beef", "pumpkin seeds"],
            "Potassium": ["bananas", "sweet potatoes", "beans"],
            "Omega-3": ["salmon", "walnuts", "chia seeds"],
            "Fiber": ["beans", "whole grains", "vegetables"]
        ]
        
        return foodSources[nutrient] ?? ["varied whole foods"]
    }
}
//
//  MicronutrientComponents.swift
//  NutriSync
//
//  Shared components for micronutrient views
//

import SwiftUI

// MARK: - Priority Nutrient Card

struct PriorityNutrientCard: View {
    let prioritized: PrioritizedNutrient
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var nutrientInfo: MicronutrientInfo? {
        MicronutrientData.getNutrient(byName: prioritized.status.nutrient.name)
    }
    
    private var guidanceLevel: NutrientGuidanceLevel {
        nutrientInfo?.getGuidanceLevel(consumed: prioritized.status.consumed) ?? .adequate
    }
    
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
        return icons[prioritized.status.nutrient.name] ?? "💊"
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 16) {
                // Icon
                Text(nutrientIcon)
                    .font(.system(size: 24))
                
                // Nutrient info
                VStack(alignment: .leading, spacing: 4) {
                    Text(prioritized.status.nutrient.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(prioritized.priorityReason)
                        .font(.system(size: 13))
                        .foregroundColor(guidanceColor)
                }
                
                Spacer()
                
                // Amount and chevron
                HStack(spacing: 8) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(prioritized.status.percentageOfRDA))%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(guidanceColor)
                        
                        Text("of target")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
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
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(guidanceColor)
                                .frame(width: geometry.size.width * min(1, prioritized.status.percentageOfRDA / 100), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    // Consumed vs Target
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Consumed")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(String(format: "%.1f", prioritized.status.consumed))\(prioritized.status.nutrient.unit)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(nutrientInfo?.isAntiNutrient == true ? "Daily Limit" : "Daily Goal")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(String(format: "%.1f", prioritized.status.nutrient.rda))\(prioritized.status.nutrient.unit)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Food sources or reduction tips
                    if guidanceLevel == .needsMore {
                        let foodSources = InsightsEngine.shared.getFoodsRichIn(nutrient: prioritized.status.nutrient.name)
                        
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
                        Text(nutrientInfo?.isAntiNutrient == true ? 
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

// MARK: - All Nutrients View

struct AllNutrientsView: View {
    let status: InsightsEngine.MicronutrientStatus
    @Binding var selectedNutrient: InsightsEngine.MicronutrientStatus.NutrientStatus?
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeficientOnly = false
    @State private var sortBy: NutrientSortOption = .percentage
    @State private var animateIn = false
    
    enum NutrientSortOption: String, CaseIterable {
        case percentage = "By %"
        case alphabetical = "A-Z"
        case category = "Type"
        
        var displayName: String {
            switch self {
            case .percentage: return "Percentage"
            case .alphabetical: return "Name"
            case .category: return "Category"
            }
        }
    }
    
    private var filteredAndSortedNutrients: [InsightsEngine.MicronutrientStatus.NutrientStatus] {
        var nutrients = status.nutrients
        
        // Filter
        if showDeficientOnly {
            nutrients = nutrients.filter { $0.percentageOfRDA < 80 }
        }
        
        // Sort
        switch sortBy {
        case .percentage:
            nutrients.sort { $0.percentageOfRDA < $1.percentageOfRDA }
        case .alphabetical:
            nutrients.sort { $0.nutrient.name < $1.nutrient.name }
        case .category:
            // Group by type (vitamins, minerals, anti-nutrients)
            nutrients.sort { n1, n2 in
                let info1 = MicronutrientData.getNutrient(byName: n1.nutrient.name)
                let info2 = MicronutrientData.getNutrient(byName: n2.nutrient.name)
                
                if info1?.isAntiNutrient != info2?.isAntiNutrient {
                    return info2?.isAntiNutrient ?? false
                }
                
                if info1?.type != info2?.type {
                    return (info1?.type.rawValue ?? 0) < (info2?.type.rawValue ?? 0)
                }
                
                return n1.nutrient.name < n2.nutrient.name
            }
        }
        
        return nutrients
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Nutrients")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Filters and Sort
            HStack(spacing: 12) {
                // Deficient only toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showDeficientOnly.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showDeficientOnly ? "checkmark.square.fill" : "square")
                            .font(.system(size: 14))
                        Text("Low only")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(showDeficientOnly ? .orange : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showDeficientOnly ? Color.orange.opacity(0.1) : Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(showDeficientOnly ? Color.orange.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                
                Spacer()
                
                // Sort options
                Menu {
                    ForEach(NutrientSortOption.allCases, id: \.self) { option in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                sortBy = option
                            }
                        }) {
                            HStack {
                                Text(option.displayName)
                                if sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Sort: \(sortBy.rawValue)")
                            .font(.system(size: 14))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Nutrient Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Array(filteredAndSortedNutrients.enumerated()), id: \.element.nutrient.id) { index, nutrientStatus in
                        CompactNutrientCardEnhanced(
                            status: nutrientStatus,
                            isSelected: selectedNutrient?.nutrient.id == nutrientStatus.nutrient.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedNutrient = selectedNutrient?.nutrient.id == nutrientStatus.nutrient.id ? nil : nutrientStatus
                                }
                            }
                        )
                        .opacity(animateIn ? 1 : 0)
                        .scaleEffect(animateIn ? 1 : 0.8)
                        .animation(.spring(response: 0.4).delay(Double(index % 9) * 0.05), value: animateIn)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            // Selected nutrient detail
            if let selected = selectedNutrient {
                NutrientDetailCard(nutrientStatus: selected)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.nutriSyncBackground)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateIn = true
            }
        }
    }
}

// MARK: - Enhanced Compact Nutrient Card

struct CompactNutrientCardEnhanced: View {
    let status: InsightsEngine.MicronutrientStatus.NutrientStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    private var nutrientInfo: MicronutrientInfo? {
        MicronutrientData.getNutrient(byName: status.nutrient.name)
    }
    
    private var isAntiNutrient: Bool {
        nutrientInfo?.isAntiNutrient ?? false
    }
    
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
        return icons[status.nutrient.name] ?? "💊"
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Text(nutrientIcon)
                .font(.system(size: 24))
            
            // Percentage with color coding
            Text("\(Int(status.percentageOfRDA))%")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(status.status.color)
            
            // Nutrient abbreviation
            Text(abbreviatedName(status.nutrient.name))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
            
            // Anti-nutrient indicator
            if isAntiNutrient {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(status.status.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? status.status.color : Color.white.opacity(0.08),
                            lineWidth: isSelected ? 2 : 1
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
            "Vitamin B1": "B1",
            "Vitamin B2": "B2",
            "Vitamin B3": "B3",
            "Vitamin B6": "B6",
            "Vitamin B12": "B12",
            "Folate": "Folate",
            "Calcium": "Ca",
            "Iron": "Fe",
            "Magnesium": "Mg",
            "Zinc": "Zn",
            "Potassium": "K",
            "Omega-3": "Ω-3",
            "Fiber": "Fiber",
            "Sodium": "Na",
            "Added Sugar": "Sugar",
            "Saturated Fat": "Sat Fat",
            "Trans Fat": "Trans",
            "Cholesterol": "Chol",
            "Caffeine": "Caffeine"
        ]
        return abbreviations[name] ?? name
    }
}

// Extension to add raw value to NutrientType
extension NutrientType: Comparable {
    var rawValue: Int {
        switch self {
        case .vitamin: return 0
        case .mineral: return 1
        case .other: return 2
        case .antiNutrient: return 3
        }
    }
    
    static func < (lhs: NutrientType, rhs: NutrientType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
//
//  MicronutrientStatusView.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  Displays micronutrient status with deficiency alerts

import SwiftUI

struct MicronutrientStatusView: View {
    let status: InsightsEngine.MicronutrientStatus
    @State private var expandedNutrients: Set<String> = []
    
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
    
    // Get top nutrients for display below hexagon
    private var displayNutrients: [InsightsEngine.MicronutrientStatus.NutrientStatus] {
        // Prioritize deficient nutrients, then show others
        let deficient = status.nutrients.filter { $0.status == .deficient || $0.status == .low }
        let adequate = status.nutrients.filter { $0.status == .adequate || $0.status == .high }
        
        let combined = deficient + adequate
        return Array(combined.prefix(6))
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
                showPurposeText: false
            )
            .frame(height: 200)
            .padding(.top, 4)
            
            // Nutrient Cards Grid
            VStack(spacing: 16) {
                ForEach(Array(displayNutrients.enumerated()), id: \.element.nutrient.id) { index, nutrientStatus in
                    MicronutrientRow(
                        nutrientStatus: nutrientStatus,
                        isExpanded: expandedNutrients.contains(nutrientStatus.nutrient.id.uuidString),
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedNutrients.contains(nutrientStatus.nutrient.id.uuidString) {
                                    expandedNutrients.remove(nutrientStatus.nutrient.id.uuidString)
                                } else {
                                    expandedNutrients.insert(nutrientStatus.nutrient.id.uuidString)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(Color.phylloBackground)
        .cornerRadius(20)
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
                    .foregroundColor(.phylloTextSecondary)
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

// MARK: - Micronutrient Row

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
                .foregroundColor(.phylloTextSecondary)
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
                        .foregroundColor(.phylloTextTertiary)
                    Text("\(String(format: "%.1f", nutrientStatus.consumed))\(nutrientStatus.nutrient.unit)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Daily Goal")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    Text("\(String(format: "%.1f", nutrientStatus.nutrient.rda))\(nutrientStatus.nutrient.unit)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.phylloTextSecondary)
                }
            }
            
            // Food sources
            if nutrientStatus.status == .deficient || nutrientStatus.status == .low {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add these foods:")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.phylloTextSecondary)
                    
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
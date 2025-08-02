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
    @State private var selectedNutrient: InsightsEngine.MicronutrientStatus.NutrientStatus?
    @State private var showAllNutrients = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Label("Micronutrient Status", systemImage: "leaf.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showAllNutrients.toggle() }) {
                    Text(showAllNutrients ? "Show Less" : "View All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.phylloAccent)
                }
            }
            
            // Top Deficiencies Alert
            if !status.topDeficiencies.isEmpty {
                DeficiencyAlertCard(deficiencies: status.topDeficiencies)
            }
            
            // Summary Grid
            if !showAllNutrients {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    // Show top deficiencies and top supplied
                    ForEach(status.topDeficiencies.prefix(2), id: \.nutrient.id) { nutrientStatus in
                        MicronutrientCard(
                            status: nutrientStatus,
                            isSelected: selectedNutrient?.nutrient.id == nutrientStatus.nutrient.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedNutrient = selectedNutrient?.nutrient.id == nutrientStatus.nutrient.id ? nil : nutrientStatus
                                }
                            }
                        )
                    }
                    
                    ForEach(status.wellSupplied.prefix(2), id: \.nutrient.id) { nutrientStatus in
                        MicronutrientCard(
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
            } else {
                // Show all nutrients
                AllNutrientsGrid(
                    nutrients: status.nutrients,
                    selectedNutrient: $selectedNutrient
                )
            }
            
            // Selected Nutrient Detail
            if let selected = selectedNutrient {
                NutrientDetailCard(nutrientStatus: selected)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
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

// MARK: - Micronutrient Card

struct MicronutrientCard: View {
    let status: InsightsEngine.MicronutrientStatus.NutrientStatus
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon and percentage
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: min(1, status.percentageOfRDA / 100))
                    .stroke(status.status.color, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(status.percentageOfRDA))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(status.status.color)
            }
            
            // Nutrient name
            Text(status.nutrient.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Status indicator
            HStack(spacing: 4) {
                Image(systemName: status.status.icon)
                    .font(.system(size: 10))
                Text(statusLabel(for: status.status))
                    .font(.system(size: 10))
            }
            .foregroundColor(status.status.color)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? status.status.color : Color.white.opacity(0.08),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .onTapGesture(perform: onTap)
    }
    
    private func statusLabel(for status: InsightsEngine.MicronutrientStatus.NutrientStatus.Status) -> String {
        switch status {
        case .deficient: return "Deficient"
        case .low: return "Low"
        case .adequate: return "Good"
        case .high: return "High"
        }
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
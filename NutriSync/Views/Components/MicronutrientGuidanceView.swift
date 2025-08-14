//
//  MicronutrientGuidanceView.swift
//  NutriSync
//
//  Guidance-based micronutrient display
//

import SwiftUI

struct MicronutrientGuidanceView: View {
    let name: String
    let consumed: Double
    let nutrientInfo: MicronutrientInfo
    let showAmount: Bool = true
    
    private var guidanceLevel: NutrientGuidanceLevel {
        nutrientInfo.getGuidanceLevel(consumed: consumed)
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
        HStack(spacing: 12) {
            // Icon with color
            Image(systemName: guidanceIcon)
                .font(.system(size: 20))
                .foregroundColor(guidanceColor)
            
            // Nutrient name and guidance
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(guidanceText)
                    .font(.system(size: 12))
                    .foregroundColor(guidanceColor)
            }
            
            Spacer()
            
            // Amount if enabled
            if showAmount {
                Text(String(format: "%.1f%@", consumed, nutrientInfo.unit))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(guidanceColor.opacity(0.1))
        )
    }
}

// Compact version for petal view
struct MicronutrientGuidanceCompact: View {
    let name: String
    let consumed: Double
    let nutrientInfo: MicronutrientInfo
    
    private var guidanceLevel: NutrientGuidanceLevel {
        nutrientInfo.getGuidanceLevel(consumed: consumed)
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
    
    var body: some View {
        VStack(spacing: 6) {
            // Icon
            Image(systemName: guidanceIcon)
                .font(.system(size: 24))
                .foregroundColor(guidanceColor)
            
            // Name
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
            
            // Amount
            Text(String(format: "%.0f%@", consumed, nutrientInfo.unit))
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(width: 65)
    }
}

// Anti-nutrient warning card
struct AntiNutrientWarningCard: View {
    let antiNutrients: [(name: String, consumed: Double, info: MicronutrientInfo)]
    
    private var criticalNutrients: [(name: String, consumed: Double, info: MicronutrientInfo)] {
        antiNutrients.filter { $0.info.getGuidanceLevel(consumed: $0.consumed) == .critical }
    }
    
    private var excessiveNutrients: [(name: String, consumed: Double, info: MicronutrientInfo)] {
        antiNutrients.filter { $0.info.getGuidanceLevel(consumed: $0.consumed) == .excessive }
    }
    
    var body: some View {
        if !criticalNutrients.isEmpty || !excessiveNutrients.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    
                    Text("Nutrition Warnings")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    // Critical warnings
                    ForEach(criticalNutrients, id: \.name) { nutrient in
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            
                            Text(nutrient.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%@ (limit: %.0f%@)", 
                                       nutrient.consumed, 
                                       nutrient.info.unit,
                                       nutrient.info.dailyLimit ?? 0,
                                       nutrient.info.unit))
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Excessive warnings
                    ForEach(excessiveNutrients, id: \.name) { nutrient in
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 6, height: 6)
                            
                            Text(nutrient.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%@ (limit: %.0f%@)", 
                                       nutrient.consumed, 
                                       nutrient.info.unit,
                                       nutrient.info.dailyLimit ?? 0,
                                       nutrient.info.unit))
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Good nutrient examples
            MicronutrientGuidanceView(
                name: "Vitamin C",
                consumed: 85,
                nutrientInfo: MicronutrientData.getNutrient(byName: "Vitamin C")!
            )
            
            MicronutrientGuidanceView(
                name: "Iron",
                consumed: 3,
                nutrientInfo: MicronutrientData.getNutrient(byName: "Iron")!
            )
            
            // Anti-nutrient examples
            MicronutrientGuidanceView(
                name: "Added Sugar",
                consumed: 45,
                nutrientInfo: MicronutrientData.getNutrient(byName: "Added Sugar")!
            )
            
            MicronutrientGuidanceView(
                name: "Sodium",
                consumed: 1800,
                nutrientInfo: MicronutrientData.getNutrient(byName: "Sodium")!
            )
            
            // Warning card
            AntiNutrientWarningCard(
                antiNutrients: [
                    (name: "Added Sugar", consumed: 45, info: MicronutrientData.getNutrient(byName: "Added Sugar")!),
                    (name: "Trans Fat", consumed: 3, info: MicronutrientData.getNutrient(byName: "Trans Fat")!)
                ]
            )
        }
        .padding()
    }
}
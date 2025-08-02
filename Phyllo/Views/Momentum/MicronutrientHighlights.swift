//
//  MicronutrientHighlights.swift
//  Phyllo
//
//  Created on 2/2/25.
//
//  Compact micronutrient display showing top deficiencies or achievements

import SwiftUI

struct MicronutrientHighlights: View {
    let status: InsightsEngine.MicronutrientStatus
    let maxItems: Int
    let showTitle: Bool
    
    @State private var animateItems = false
    
    init(status: InsightsEngine.MicronutrientStatus, maxItems: Int = 3, showTitle: Bool = true) {
        self.status = status
        self.maxItems = maxItems
        self.showTitle = showTitle
    }
    
    private var topDeficiencies: [InsightsEngine.MicronutrientStatus.NutrientStatus] {
        status.topDeficiencies
            .prefix(maxItems)
            .map { $0 }
    }
    
    private var hasDeficiencies: Bool {
        !status.topDeficiencies.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if showTitle {
                HStack(spacing: 8) {
                    Image(systemName: hasDeficiencies ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(hasDeficiencies ? .orange : .green)
                    
                    Text(hasDeficiencies ? "Nutritional Gaps" : "Well Nourished")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            if hasDeficiencies {
                // Show deficiencies
                VStack(spacing: 12) {
                    ForEach(Array(topDeficiencies.enumerated()), id: \.1.nutrient.id) { index, item in
                        MicronutrientHighlightRow(
                            nutrientStatus: item,
                            isDeficient: true
                        )
                        .opacity(animateItems ? 1 : 0)
                        .offset(y: animateItems ? 0 : 10)
                        .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: animateItems)
                    }
                }
                
                // Quick tip
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("Focus on these nutrients in your next meals")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextSecondary)
                }
                .padding(.top, 8)
            } else {
                // Show achievements
                VStack(spacing: 12) {
                    ForEach(Array(status.wellSupplied.prefix(maxItems).enumerated()), id: \.1.nutrient.id) { index, item in
                        MicronutrientHighlightRow(
                            nutrientStatus: item,
                            isDeficient: false
                        )
                        .opacity(animateItems ? 1 : 0)
                        .offset(y: animateItems ? 0 : 10)
                        .animation(.spring(response: 0.5).delay(Double(index) * 0.1), value: animateItems)
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("Great job meeting your nutritional needs!")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextSecondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateItems = true
            }
        }
    }
}

struct MicronutrientHighlightRow: View {
    let nutrientStatus: InsightsEngine.MicronutrientStatus.NutrientStatus
    let isDeficient: Bool
    
    private var nutrient: MicronutrientData {
        nutrientStatus.nutrient
    }
    
    private var percentRDA: Double {
        nutrientStatus.percentageOfRDA
    }
    
    private var statusColor: Color {
        nutrientStatus.status.color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(statusColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: min(percentRDA / 100, 1.0))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(percentRDA))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(nutrient.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.1f", nutrientStatus.consumed)) / \(String(format: "%.1f", nutrient.rda)) \(nutrient.unit)")
                    .font(.system(size: 12))
                    .foregroundColor(.phylloTextTertiary)
            }
            
            Spacer()
            
            // Status icon
            Image(systemName: isDeficient ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(statusColor)
        }
    }
}

// MARK: - Micronutrient Comparison

struct MicronutrientComparison: View {
    let startStatus: InsightsEngine.MicronutrientStatus
    let currentStatus: InsightsEngine.MicronutrientStatus
    
    private var improvementCount: Int {
        let startDefCount = startStatus.topDeficiencies.count
        let currentDefCount = currentStatus.topDeficiencies.count
        return max(0, startDefCount - currentDefCount)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Nutritional Progress")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 24) {
                // Start
                VStack(spacing: 8) {
                    Text("Start")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    
                    VStack(spacing: 4) {
                        Text("\(startStatus.topDeficiencies.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                        
                        Text("deficiencies")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(.phylloTextTertiary)
                
                // Current
                VStack(spacing: 8) {
                    Text("Now")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                    
                    VStack(spacing: 4) {
                        Text("\(currentStatus.topDeficiencies.count)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(currentStatus.topDeficiencies.isEmpty ? .green : .orange)
                        
                        Text("deficiencies")
                            .font(.system(size: 12))
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
            
            if improvementCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("Fixed \(improvementCount) nutritional gap\(improvementCount == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
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

#Preview("MicronutrientHighlights") {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 32) {
            // With deficiencies
            MicronutrientHighlights(
                status: InsightsEngine.MicronutrientStatus(
                    nutrients: [],
                    topDeficiencies: [
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Vitamin D", unit: "mcg", rda: 20.0),
                            consumed: 2.5,
                            percentageOfRDA: 12.5,
                            status: .deficient
                        ),
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Iron", unit: "mg", rda: 18.0),
                            consumed: 6.0,
                            percentageOfRDA: 33.3,
                            status: .deficient
                        ),
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Vitamin B12", unit: "mcg", rda: 2.4),
                            consumed: 1.2,
                            percentageOfRDA: 50.0,
                            status: .low
                        )
                    ],
                    wellSupplied: []
                )
            )
            
            // Well nourished
            MicronutrientHighlights(
                status: InsightsEngine.MicronutrientStatus(
                    nutrients: [],
                    topDeficiencies: [],
                    wellSupplied: [
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Vitamin C", unit: "mg", rda: 90.0),
                            consumed: 120.0,
                            percentageOfRDA: 133.3,
                            status: .high
                        ),
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Calcium", unit: "mg", rda: 1000.0),
                            consumed: 1200.0,
                            percentageOfRDA: 120.0,
                            status: .adequate
                        ),
                        InsightsEngine.MicronutrientStatus.NutrientStatus(
                            nutrient: MicronutrientData(name: "Vitamin A", unit: "mcg", rda: 900.0),
                            consumed: 950.0,
                            percentageOfRDA: 105.6,
                            status: .adequate
                        )
                    ]
                )
            )
        }
        .padding()
    }
}
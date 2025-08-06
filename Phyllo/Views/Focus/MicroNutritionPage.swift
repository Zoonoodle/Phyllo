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
    
    // Get micronutrient data - TODO: Implement real micronutrient tracking
    private var micronutrientData: [MicronutrientConsumption] {
        // For now, return empty data as real micronutrient tracking needs to be implemented
        // This was previously using mock data from MockDataManager
        []
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
                HexagonFlowerView(micronutrients: micronutrientData.map { ($0.info.name, $0.percentage) })
            }
            .frame(height: 180) // Match the height of calorie ring
            
            // Micronutrient bars
            HStack(spacing: 20) {
                ForEach(micronutrientData, id: \.info.name) { nutrient in
                    MicronutrientBar(micronutrient: nutrient)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 40) // Match macro page top padding
        .padding(.bottom, 34) // Match macro page bottom padding
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

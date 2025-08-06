//
//  WindowPurposeCard.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowPurposeCard: View {
    let window: MealWindow
    
    // Purpose-specific descriptions and tips
    private var purposeInfo: (description: String, tips: [String]) {
        switch window.purpose {
        case .sustainedEnergy:
            return (
                "This window is designed to maintain stable energy levels through balanced nutrition.",
                [
                    "Balance protein & carbs for steady energy",
                    "Avoid heavy fats that slow digestion",
                    "Stay hydrated throughout the window",
                    "Choose complex carbs over simple sugars"
                ]
            )
        case .focusBoost:
            return (
                "Optimized for mental clarity and cognitive performance.",
                [
                    "Include omega-3 rich foods",
                    "Moderate caffeine for alertness",
                    "Avoid sugar crashes",
                    "Consider brain-boosting berries"
                ]
            )
        case .recovery:
            return (
                "Supports your body's natural recovery and repair processes.",
                [
                    "Prioritize anti-inflammatory foods",
                    "Include vitamin C for tissue repair",
                    "Stay well hydrated",
                    "Consider tart cherry juice for recovery"
                ]
            )
        case .preworkout:
            return (
                "Fuel your workout with easily digestible energy.",
                [
                    "Eat 30-60 minutes before exercise",
                    "Focus on quick-digesting carbs",
                    "Keep fat intake minimal",
                    "Include some caffeine if tolerated"
                ]
            )
        case .postworkout:
            return (
                "Maximize muscle recovery and glycogen replenishment.",
                [
                    "Consume within 30 minutes post-workout",
                    "Aim for 3:1 carb to protein ratio",
                    "Include electrolytes",
                    "Don't forget leucine-rich proteins"
                ]
            )
        case .metabolicBoost:
            return (
                "Kickstart your metabolism and fat-burning potential.",
                [
                    "Include thermogenic foods",
                    "Green tea for metabolism boost",
                    "Spicy foods can help",
                    "Keep portions moderate"
                ]
            )
        case .sleepOptimization:
            return (
                "Prepare your body for restful, restorative sleep.",
                [
                    "Include magnesium-rich foods",
                    "Avoid caffeine and stimulants",
                    "Try foods with tryptophan",
                    "Keep it light - no heavy meals"
                ]
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Window Purpose")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            // Purpose card
            VStack(alignment: .leading, spacing: 20) {
                // Title with icon
                HStack(spacing: 12) {
                    Image(systemName: window.purpose.icon)
                        .font(.system(size: 24))
                        .foregroundColor(window.purpose.color)
                    
                    Text(window.purpose.rawValue)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Description
                Text(purposeInfo.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
                
                // Tips section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Optimization Tips")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(purposeInfo.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(window.purpose.color)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                
                                Text(tip)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.phylloElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.phylloBorder, lineWidth: 1)
                    )
            )
        }
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        WindowPurposeCard(window: MealWindow.mockWindows(for: .performanceFocus)[0])
            .padding()
    }
}
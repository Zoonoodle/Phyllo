//
//  MealFrequencyView.swift
//  NutriSync
//
//  Meal frequency preference based on circadian science
//

import SwiftUI

struct MealFrequencyView: View {
    @State private var selectedFrequency: MealFrequency?
    
    enum MealFrequency: String, CaseIterable {
        case twoToThree = "2-3 meals"
        case fourToFive = "4-5 meals"
        case sixPlus = "6+ meals"
        
        var title: String {
            switch self {
            case .twoToThree: return "2-3 Meals"
            case .fourToFive: return "4-5 Meals"
            case .sixPlus: return "6+ Meals"
            }
        }
        
        var description: String {
            switch self {
            case .twoToThree:
                return "Recommended • Longer fasting periods between meals improve metabolic health"
            case .fourToFive:
                return "Moderate frequency • Balanced approach for active individuals"
            case .sixPlus:
                return "High frequency • May increase inflammation and metabolic stress"
            }
        }
        
        var icon: String {
            switch self {
            case .twoToThree: return "star.fill"
            case .fourToFive: return "circle.fill"
            case .sixPlus: return "exclamationmark.triangle.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .twoToThree: return .nutriSyncAccent
            case .fourToFive: return .white.opacity(0.7)
            case .sixPlus: return .orange
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationHeader(
                    currentStep: 2,
                    totalSteps: 4,
                    onBack: {},
                    onClose: {}
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("How many meals do you prefer daily?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // Science-based explanation
                        Text("Research shows that eating 2-3 meals per day with adequate fasting periods can improve metabolic health, reduce inflammation, and enhance circadian rhythms.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                        
                        // Options
                        VStack(spacing: 16) {
                            ForEach(MealFrequency.allCases, id: \.self) { frequency in
                                MealFrequencyOption(
                                    frequency: frequency,
                                    isSelected: selectedFrequency == frequency,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedFrequency = frequency
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Info card
                        HStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 24))
                                .foregroundColor(.nutriSyncAccent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time-Restricted Eating")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Fewer meals create natural fasting periods that activate autophagy and improve insulin sensitivity.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineSpacing(2)
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Continue button
                PrimaryButton(
                    title: "Continue",
                    isEnabled: selectedFrequency != nil
                ) {
                    // Handle continue
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Meal Frequency Option
struct MealFrequencyOption: View {
    let frequency: MealFrequencyView.MealFrequency
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(frequency.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: frequency.icon)
                            .font(.system(size: 14))
                            .foregroundColor(frequency.iconColor)
                    }
                    
                    Text(frequency.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
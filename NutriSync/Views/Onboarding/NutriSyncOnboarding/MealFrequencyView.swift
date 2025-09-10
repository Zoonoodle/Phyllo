//
//  MealFrequencyView.swift
//  NutriSync
//
//  Meal frequency preference based on circadian science
//

import SwiftUI

struct MealFrequencyView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
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
                // Progress bar
                ProgressBar(totalSteps: 31, currentStep: 21)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                
                VStack(spacing: 0) {
                    // Title
                    Text("How many meals do you prefer daily?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                    // Subtitle
                    Text("Research shows that eating 2-3 meals per day with adequate fasting periods can improve metabolic health, reduce inflammation, and enhance circadian rhythms.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                        
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
                    .padding(.horizontal, 20)
                        
                    Spacer()
                
                // Navigation
                HStack {
                    Button {
                        coordinator.previousScreen()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button {
                        // Save data to coordinator before proceeding
                        if let frequency = selectedFrequency {
                            switch frequency {
                            case .twoToThree:
                                coordinator.mealFrequency = "3"
                            case .fourToFive:
                                coordinator.mealFrequency = "4"
                            case .sixPlus:
                                coordinator.mealFrequency = "6"
                            }
                        }
                        coordinator.nextScreen()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedFrequency != nil ? Color.nutriSyncBackground : Color.white.opacity(0.3))
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(selectedFrequency != nil ? Color.white : Color.white.opacity(0.1))
                        .cornerRadius(22)
                    }
                    .disabled(selectedFrequency == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
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
            .frame(maxWidth: .infinity)
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
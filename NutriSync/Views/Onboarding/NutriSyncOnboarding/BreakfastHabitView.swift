//
//  BreakfastHabitView.swift
//  NutriSync
//
//  Breakfast habit assessment with circadian rhythm benefits
//

import SwiftUI

struct BreakfastHabitView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedOption: BreakfastOption?
    
    enum BreakfastOption: String, CaseIterable {
        case always = "always"
        case sometimes = "sometimes"
        case rarely = "rarely"
        case fasting = "fasting"
        
        var title: String {
            switch self {
            case .always: return "I always eat breakfast"
            case .sometimes: return "I sometimes eat breakfast"
            case .rarely: return "I rarely eat breakfast"
            case .fasting: return "I practice morning fasting"
            }
        }
        
        var description: String {
            switch self {
            case .always:
                return "Great for kickstarting metabolism and providing morning energy"
            case .sometimes:
                return "Flexible approach based on daily needs"
            case .rarely:
                return "May extend overnight fasting benefits"
            case .fasting:
                return "Intentional fasting can improve insulin sensitivity"
            }
        }
        
        var timeRange: String {
            switch self {
            case .always: return "Within 2 hours of waking"
            case .sometimes: return "Varies by day"
            case .rarely: return "Usually skip"
            case .fasting: return "First meal after noon"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(totalSteps: 31, currentStep: 3)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                
                // Title
                Text("Do you usually eat breakfast?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("Your breakfast habits affect your circadian rhythm and metabolic rate. We'll optimize your meal windows based on your preference.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(BreakfastOption.allCases, id: \.self) { option in
                        BreakfastOptionCard(
                            option: option,
                            isSelected: selectedOption == option,
                            onTap: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedOption = option
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
                        if let selected = selectedOption {
                            coordinator.breakfastHabit = selected.rawValue
                        }
                        
                        coordinator.nextScreen()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Next")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(Color.nutriSyncBackground)
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(selectedOption != nil ? Color.white : Color.white.opacity(0.3))
                        .cornerRadius(22)
                    }
                    .disabled(selectedOption == nil)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
            }
            .frame(width: geometry.size.width)
            .frame(minHeight: geometry.size.height)
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Breakfast Option Card
struct BreakfastOptionCard: View {
    let option: BreakfastHabitView.BreakfastOption
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
                    Text(option.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(option.timeRange)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text(option.description)
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

// MARK: - Info Card Component
struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}
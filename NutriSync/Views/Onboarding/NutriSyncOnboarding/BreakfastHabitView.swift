//
//  BreakfastHabitView.swift
//  NutriSync
//
//  Breakfast habit assessment with circadian rhythm benefits
//

import SwiftUI

struct BreakfastHabitView: View {
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
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                NavigationHeader(
                    currentStep: 3,
                    totalSteps: 4,
                    onBack: {},
                    onClose: {}
                )
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Do you usually eat breakfast?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                        
                        // Explanation
                        Text("Your breakfast habits affect your circadian rhythm and metabolic rate. We'll optimize your meal windows based on your preference.")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                            .padding(.horizontal, 24)
                        
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
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Science info cards
                        VStack(spacing: 16) {
                            // Morning eating benefits
                            InfoCard(
                                icon: "sun.max.fill",
                                iconColor: .orange,
                                title: "Morning Eating Benefits",
                                description: "Eating breakfast can synchronize peripheral clocks, boost cortisol response, and improve glucose metabolism throughout the day."
                            )
                            
                            // Fasting benefits
                            InfoCard(
                                icon: "clock.badge.checkmark.fill",
                                iconColor: .nutriSyncAccent,
                                title: "Extended Fasting Benefits",
                                description: "Extending your overnight fast can enhance autophagy, improve insulin sensitivity, and support metabolic flexibility."
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Continue button
                PrimaryButton(
                    title: "Continue",
                    isEnabled: selectedOption != nil
                ) {
                    // Handle continue
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
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
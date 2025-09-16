//
//  MaintenanceStrategyView.swift
//  NutriSync
//
//  Maintenance Strategy Screen for Weight Maintenance Goal
//

import SwiftUI

struct MaintenanceStrategyView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedStrategy = "Energy stability"
    
    let strategies = [
        ("Energy stability", "bolt.circle.fill", "Maintain consistent energy throughout the day", Color.yellow),
        ("Performance optimization", "figure.run.circle.fill", "Optimize nutrition for physical performance", Color.orange),
        ("Better sleep quality", "moon.circle.fill", "Improve sleep through timed nutrition", Color.purple),
        ("Overall health", "heart.circle.fill", "Focus on general health and wellbeing", Color.red)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    OnboardingSectionProgressBar()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Title
                    Text("Maintenance Strategy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Subtitle
                    Text("Let's optimize your eating schedule to maintain your current weight")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // Strategy options
                    VStack(spacing: 16) {
                        ForEach(strategies, id: \.0) { strategy, icon, description, color in
                            StrategyOption(
                                title: strategy,
                                icon: icon,
                                description: description,
                                color: color,
                                isSelected: selectedStrategy == strategy
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedStrategy = strategy
                                }
                            }
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
                        }
                        
                        Spacer()
                        
                        Button {
                            // Save strategy to coordinator
                            coordinator.maintenanceStrategy = selectedStrategy
                            coordinator.nextScreen()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(22)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.black)
    }
}

struct StrategyOption: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? color : .white.opacity(0.4))
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MaintenanceStrategyView()
        .environment(NutriSyncOnboardingViewModel())
}
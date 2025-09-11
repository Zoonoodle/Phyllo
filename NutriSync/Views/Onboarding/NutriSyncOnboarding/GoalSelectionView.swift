//
//  GoalSelectionView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 9 - Dark Theme
//

import SwiftUI

struct GoalSelectionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedGoal = "Lose Weight"
    
    let goals = [
        ("Lose Weight", "arrow.down.circle.fill", "Reduce body weight sustainably", Color.red),
        ("Maintain Weight", "equal.circle.fill", "Keep your current weight steady", Color.blue),
        ("Gain Weight", "arrow.up.circle.fill", "Build muscle or increase weight", Color.green)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(totalSteps: 24, currentStep: 9)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Title
                    Text("What is your goal?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Subtitle
                    Text("Select your current goal.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // Goal options
                    VStack(spacing: 16) {
                        ForEach(goals, id: \.0) { goal, icon, description, color in
                            GoalOption(
                                title: goal,
                                icon: icon,
                                description: description,
                                color: color,
                                isSelected: selectedGoal == goal
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedGoal = goal
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
                            // Save goal to coordinator
                            coordinator.goal = selectedGoal
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
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

struct GoalOption: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Enhanced icon with gradient background
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.3),
                            color.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 48, height: 48)
                    .cornerRadius(12)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.08 : 0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GoalSelectionView()
    }
}
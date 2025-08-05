//
//  GoalsSelectionView.swift
//  Phyllo
//
//  Goal selection screen for onboarding
//

import SwiftUI

struct GoalsSelectionView: View {
    @Binding var primaryGoal: NutritionGoal?
    @Binding var secondaryGoals: [NutritionGoal]
    @State private var showSecondaryGoals = false
    
    let allGoals: [NutritionGoal] = [
        .weightLoss(targetPounds: 10, timeline: 12),
        .muscleGain(targetPounds: 5, timeline: 12),
        .maintainWeight,
        .performanceFocus,
        .betterSleep,
        .overallWellbeing,
        .athleticPerformance(sport: "General")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's your primary goal?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We'll customize your nutrition plan to help you achieve it")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Primary Goals
                VStack(spacing: 12) {
                    ForEach(allGoals, id: \.id) { goal in
                        GoalCard(
                            goal: goal,
                            isSelected: primaryGoal?.id == goal.id,
                            isPrimary: true
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                primaryGoal = goal
                                // If this goal was in secondary, remove it
                                secondaryGoals.removeAll { $0.id == goal.id }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Secondary Goals Section
                if primaryGoal != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Add secondary goals")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("(Optional)")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Spacer()
                            
                            Image(systemName: showSecondaryGoals ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSecondaryGoals.toggle()
                            }
                        }
                        
                        if showSecondaryGoals {
                            VStack(spacing: 12) {
                                ForEach(allGoals.filter { $0.id != primaryGoal?.id }, id: \.id) { goal in
                                    GoalCard(
                                        goal: goal,
                                        isSelected: secondaryGoals.contains { $0.id == goal.id },
                                        isPrimary: false
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            if let index = secondaryGoals.firstIndex(where: { $0.id == goal.id }) {
                                                secondaryGoals.remove(at: index)
                                            } else if secondaryGoals.count < 2 {
                                                secondaryGoals.append(goal)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            if secondaryGoals.count >= 2 {
                                Text("Maximum 2 secondary goals")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
                }
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct GoalCard: View {
    let goal: NutritionGoal
    let isSelected: Bool
    let isPrimary: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? goal.color.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: goal.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? goal.color : .white.opacity(0.5))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    
                    Text(goalDescription(for: goal))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? goal.color : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(goal.color)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.05 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? goal.color.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func goalDescription(for goal: NutritionGoal) -> String {
        switch goal {
        case .weightLoss(let pounds, _):
            return "Lose \(Int(pounds)) pounds sustainably"
        case .muscleGain(let pounds, _):
            return "Build \(Int(pounds)) pounds of muscle"
        case .maintainWeight:
            return "Stay at your current weight"
        case .performanceFocus:
            return "Optimize mental clarity & energy"
        case .betterSleep:
            return "Improve sleep quality naturally"
        case .overallWellbeing:
            return "Feel your best every day"
        case .athleticPerformance:
            return "Fuel your athletic performance"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var primaryGoal: NutritionGoal?
        @State private var secondaryGoals: [NutritionGoal] = []
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                GoalsSelectionView(
                    primaryGoal: $primaryGoal,
                    secondaryGoals: $secondaryGoals
                )
            }
        }
    }
    
    return PreviewWrapper()
}
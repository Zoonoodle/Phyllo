//
//  PhylloScoreDetailView.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct PhylloScoreDetailView: View {
    @StateObject private var mockData = MockDataManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animatedScore: Double = 0
    @State private var showingBreakdown = false
    
    private var phylloScore: Int {
        calculatePhylloScore()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Original PhylloScoreCard content
                        VStack(spacing: 24) {
                            // Score Display
                            ZStack {
                                // Background gradient
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.phylloAccent.opacity(0.15),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 100
                                        )
                                    )
                                    .frame(width: 250, height: 250)
                                
                                // Progress Ring
                                ZStack {
                                    // Background ring
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                                        .frame(width: 200, height: 200)
                                    
                                    // Progress ring
                                    Circle()
                                        .trim(from: 0, to: animatedScore / 100)
                                        .stroke(
                                            LinearGradient(
                                                colors: scoreGradientColors,
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                        )
                                        .frame(width: 200, height: 200)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animatedScore)
                                    
                                    // Score Text
                                    VStack(spacing: 4) {
                                        Text("\(Int(animatedScore))")
                                            .font(.system(size: 56, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("PhylloScore")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.phylloTextSecondary)
                                    }
                                }
                            }
                            .padding(.top, 20)
                            
                            // Goal Context
                            VStack(spacing: 8) {
                                Text("Personalized for")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextTertiary)
                                
                                Text(mockData.primaryGoal.displayName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.phylloAccent)
                            }
                            
                            // Score Breakdown
                            VStack(spacing: 16) {
                                ScoreBreakdownItem(
                                    title: "Goal Adherence",
                                    percentage: 85,
                                    description: "Following your \(mockData.primaryGoal.displayName) plan",
                                    weight: "40%"
                                )
                                
                                ScoreBreakdownItem(
                                    title: "Timing Consistency",
                                    percentage: 72,
                                    description: "Eating within your optimal windows",
                                    weight: "20%"
                                )
                                
                                ScoreBreakdownItem(
                                    title: "Macro Balance",
                                    percentage: 90,
                                    description: "Hitting your macro targets",
                                    weight: "20%"
                                )
                                
                                ScoreBreakdownItem(
                                    title: "Micronutrients",
                                    percentage: 65,
                                    description: "Vitamin and mineral coverage",
                                    weight: "20%"
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("PhylloScore")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.phylloAccent)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animatedScore = Double(phylloScore)
            }
        }
    }
    
    private var scoreGradientColors: [Color] {
        if animatedScore < 40 {
            return [Color.red, Color.orange]
        } else if animatedScore < 70 {
            return [Color.orange, Color.yellow]
        } else {
            return [Color.yellow, Color.phylloAccent]
        }
    }
    
    private func calculatePhylloScore() -> Int {
        // Same calculation as in PhylloScoreCard
        let baseScore: Double
        
        switch mockData.primaryGoal {
        case .weightLoss:
            let calorieAdherence = min(100, (1 - abs(mockData.totalCalories - 1800) / 1800) * 100)
            let timingScore = mockData.mealsLoggedToday.isEmpty ? 0.0 : 85.0
            baseScore = (calorieAdherence * 0.6 + timingScore * 0.4)
            
        case .muscleGain:
            let proteinAdherence = min(100, (mockData.totalProtein / 150) * 100)
            let mealFrequency = min(100, (Double(mockData.mealsLoggedToday.count) / 6) * 100)
            baseScore = (proteinAdherence * 0.7 + mealFrequency * 0.3)
            
        case .performanceFocus:
            let timingScore = 75.0
            let macroBalance = calculateMacroBalance()
            baseScore = (timingScore * 0.6 + macroBalance * 0.4)
            
        case .maintainWeight:
            let calorieScore = min(100, (1 - abs(mockData.totalCalories - 2000) / 2000) * 100)
            let proteinScore = min(100, (mockData.totalProtein / 100) * 100)
            let timingScore = 70.0
            baseScore = (calorieScore * 0.33 + proteinScore * 0.33 + timingScore * 0.34)
            
        case .betterSleep, .overallWellbeing, .athleticPerformance:
            let calorieScore = min(100, (1 - abs(mockData.totalCalories - 2200) / 2200) * 100)
            let proteinScore = min(100, (mockData.totalProtein / 120) * 100)
            let timingScore = 72.0
            baseScore = (calorieScore * 0.33 + proteinScore * 0.33 + timingScore * 0.34)
        }
        
        let streakBonus = min(10, mockData.currentStreak / 2)
        return Int(min(100, baseScore + Double(streakBonus)))
    }
    
    private func calculateMacroBalance() -> Double {
        let totalMacros = mockData.totalProtein + mockData.totalCarbs + mockData.totalFat
        guard totalMacros > 0 else { return 0 }
        
        let proteinRatio = mockData.totalProtein / totalMacros
        let carbRatio = mockData.totalCarbs / totalMacros
        let fatRatio = mockData.totalFat / totalMacros
        
        let proteinScore = 1 - abs(proteinRatio - 0.3)
        let carbScore = 1 - abs(carbRatio - 0.4)
        let fatScore = 1 - abs(fatRatio - 0.3)
        
        return (proteinScore + carbScore + fatScore) / 3 * 100
    }
}

#Preview {
    PhylloScoreDetailView()
        .preferredColorScheme(.dark)
}
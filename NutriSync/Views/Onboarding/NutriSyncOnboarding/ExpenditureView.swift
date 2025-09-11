//
//  ExpenditureView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 5 - Dark Theme
//

import SwiftUI

struct ExpenditureView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var expenditure: Int = 0
    @State private var showAdjustment = false
    @State private var selectedActivityLevel: TDEECalculator.ActivityLevel = .moderatelyActive
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressBar(totalSteps: 23, currentStep: 5)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    
                    // Title
                    Text("We estimated your initial expenditure.")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    
                    if !showAdjustment {
                        // Activity level selection
                        VStack(spacing: 12) {
                            Text("Select your activity level:")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.bottom, 8)
                            
                            ForEach(TDEECalculator.ActivityLevel.allCases, id: \.self) { level in
                                Button {
                                    selectedActivityLevel = level
                                    calculateTDEE()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(level.rawValue)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(level.description)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedActivityLevel == level ?
                                        Color.nutriSyncAccent.opacity(0.2) :
                                        Color.white.opacity(0.05)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                selectedActivityLevel == level ?
                                                Color.nutriSyncAccent :
                                                Color.white.opacity(0.1),
                                                lineWidth: 1
                                            )
                                    )
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    
                    // Calorie display
                    VStack(spacing: 8) {
                        Text("\(expenditure) kcal")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.white)
                        
                        if showAdjustment {
                            // Manual adjustment buttons
                            HStack(spacing: 40) {
                                Button {
                                    expenditure = max(1200, expenditure - 50)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Button {
                                    expenditure = min(5000, expenditure + 50)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(.top, 20)
                            
                            Text("Adjust your daily expenditure")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.bottom, 40)
                    
                    // Question
                    Text("Does this look right to you?")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding(.bottom, 12)
                    
                    // Description
                    Text("Expenditure is the number of calories you would need to consume to maintain your current weight.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        if !showAdjustment {
                            Button {
                                // User disagrees - show adjustment controls
                                showAdjustment = true
                            } label: {
                                HStack {
                                    Text("No, let me adjust")
                                        .font(.system(size: 18, weight: .medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(25)
                            }
                            
                            Button {
                                // User agrees with the estimate
                                coordinator.tdee = Double(expenditure)
                                coordinator.nextScreen()
                            } label: {
                                HStack {
                                    Text("Yes, looks good")
                                        .font(.system(size: 18, weight: .medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(25)
                            }
                            
                            Button {
                                // User is not sure - proceed with estimate
                                coordinator.tdee = Double(expenditure)
                                coordinator.nextScreen()
                            } label: {
                                HStack {
                                    Text("Not Sure, continue")
                                        .font(.system(size: 18, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(Color.nutriSyncBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                        } else {
                            // Save adjusted value
                            Button {
                                coordinator.tdee = Double(expenditure)
                                coordinator.nextScreen()
                            } label: {
                                HStack {
                                    Text("Save and Continue")
                                        .font(.system(size: 18, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(Color.nutriSyncBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(25)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    // Back button
                    HStack {
                        Button {
                            if showAdjustment {
                                showAdjustment = false
                            } else {
                                coordinator.previousScreen()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.leading, 20)
                        
                        Spacer()
                    }
                    .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            calculateTDEE()
        }
    }
    
    private func calculateTDEE() {
        // Get gender enum value
        let gender: TDEECalculator.Gender = coordinator.gender.lowercased() == "female" ? .female : .male
        
        // Calculate TDEE using the data from coordinator
        let tdee = TDEECalculator.calculate(
            weight: coordinator.weight,
            height: coordinator.height,
            age: coordinator.age,
            gender: gender,
            activityLevel: selectedActivityLevel
        )
        
        // Round to nearest 5
        expenditure = Int((tdee / 5).rounded()) * 5
        
        // Save activity level to coordinator
        coordinator.activityLevel = selectedActivityLevel.rawValue
    }
}

struct ExpenditureView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenditureView()
    }
}
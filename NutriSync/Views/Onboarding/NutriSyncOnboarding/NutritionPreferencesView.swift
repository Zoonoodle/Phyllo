//
//  NutritionPreferencesView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Nutrition Preferences
//

import SwiftUI

struct NutritionPreferencesView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var macroPreference = ""
    @State private var foodSensitivities = ""
    
    let macroOptions = ["Balanced", "Higher protein", "Higher carbs", "Higher fats"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 26)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Macro Preferences")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("How would you like to balance your macronutrients?")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    // Food sensitivities
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Food Sensitivities (Optional)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextField("e.g., lactose intolerant, nut allergy", text: $foodSensitivities)
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                    .padding(.bottom, 8)
                    
                    // Macro preference
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Macro Focus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            ForEach(macroOptions, id: \.self) { option in
                                OptionButton(
                                    title: option,
                                    isSelected: macroPreference == option,
                                    action: {
                                        macroPreference = option
                                    }
                                )
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
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    // Save data to coordinator before proceeding
                    coordinator.macroPreference = macroPreference
                    coordinator.foodSensitivities = foodSensitivities
                    
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(canContinue ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(canContinue ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(22)
                }
                .disabled(!canContinue)
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
        .onAppear {
            // Initialize state from coordinator
            macroPreference = coordinator.macroPreference
            foodSensitivities = coordinator.foodSensitivities
        }
    }
    
    private var canContinue: Bool {
        !macroPreference.isEmpty
    }
}

struct MultiSelectButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NutritionPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NutritionPreferencesView()
    }
}
//
//  DietaryRestrictionsView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Dietary Restrictions (Split from NutritionPreferencesView)
//

import SwiftUI

struct DietaryRestrictionsView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var dietaryRestrictions: Set<String> = []
    
    let restrictionOptions = ["Vegetarian", "Vegan", "Gluten-free", "Dairy-free", "Keto", "Paleo", "None"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 25)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 24) {
                // Title
                Text("Dietary Restrictions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                // Subtitle
                Text("Select any dietary restrictions you follow")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)
                
                // Dietary restrictions
                VStack(spacing: 12) {
                    ForEach(restrictionOptions, id: \.self) { option in
                        MultiSelectButton(
                            title: option,
                            isSelected: dietaryRestrictions.contains(option),
                            action: {
                                if option == "None" {
                                    if dietaryRestrictions.contains("None") {
                                        dietaryRestrictions.remove("None")
                                    } else {
                                        dietaryRestrictions = ["None"]
                                    }
                                } else {
                                    dietaryRestrictions.remove("None")
                                    if dietaryRestrictions.contains(option) {
                                        dietaryRestrictions.remove(option)
                                    } else {
                                        dietaryRestrictions.insert(option)
                                    }
                                }
                            }
                        )
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
                    // Save dietary restrictions to coordinator
                    coordinator.dietaryRestrictions = dietaryRestrictions
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(!dietaryRestrictions.isEmpty ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(!dietaryRestrictions.isEmpty ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(22)
                }
                .disabled(dietaryRestrictions.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

struct DietaryRestrictionsView_Previews: PreviewProvider {
    static var previews: some View {
        DietaryRestrictionsView()
    }
}
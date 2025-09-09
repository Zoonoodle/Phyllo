//
//  CalorieFloorView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 14 - Dark Theme
//

import SwiftUI

struct CalorieFloorView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedFloor = "Standard Floor"
    
    let floors = [
        ("Standard Floor", "star", "Your recommendations will never go below ~1200 Calories even if your TDEE adjusts over time."),
        ("Low Floor", "exclamationmark.circle", "Your recommendations will never go below ~800 Calories. Proceed with caution.")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 18)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("What calorie floor do you prefer?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            
            // Floor options
            VStack(spacing: 16) {
                ForEach(floors, id: \.0) { floor, icon, description in
                    CalorieFloorOption(
                        title: floor,
                        icon: icon,
                        description: description,
                        isSelected: selectedFloor == floor
                    ) {
                        selectedFloor = floor
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
                    // Save calorie floor to coordinator
                    let calorieValue = selectedFloor == "Standard Floor" ? 1200 : 800
                    coordinator.calorieFloor = calorieValue
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
                    .background(Color.white)
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

struct CalorieFloorOption: View {
    let title: String
    let icon: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .padding(.top, 20)
                
                // Text content
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct CalorieFloorView_Previews: PreviewProvider {
    static var previews: some View {
        CalorieFloorView()
    }
}
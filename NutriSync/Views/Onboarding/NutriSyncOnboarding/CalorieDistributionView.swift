//
//  CalorieDistributionView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 16 - Dark Theme
//

import SwiftUI

struct CalorieDistributionView: View {
    @State private var selectedDistribution = "Shift Calories"
    
    let distributions = [
        ("Shift Calories", "slider.horizontal.3", "Distribute Calories to increase Calorie targets on specific days."),
        ("Distribute Evenly", "equal.square", "Distribute Calories evenly across all days of the week.")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 19)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("How would you like to distribute Calories throughout the week?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Select your preference for calorie distribution throughout the week.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            
            // Distribution options
            VStack(spacing: 16) {
                ForEach(distributions, id: \.0) { distribution, icon, description in
                    CalorieDistributionOption(
                        title: distribution,
                        icon: icon,
                        description: description,
                        isSelected: selectedDistribution == distribution
                    ) {
                        selectedDistribution = distribution
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    // Back action
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
                    // Next action
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
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

struct CalorieDistributionOption: View {
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

struct CalorieDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        CalorieDistributionView()
    }
}
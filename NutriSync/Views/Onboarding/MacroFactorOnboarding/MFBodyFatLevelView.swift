//
//  MFBodyFatLevelView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 1 - Dark Theme
//

import SwiftUI

struct MFBodyFatLevelView: View {
    @State private var selectedBodyFat: String = "38-42%"
    
    let bodyFatRanges = [
        ("10-13%", "female_10_13"),
        ("14-17%", "female_14_17"),
        ("18-23%", "female_18_23"),
        ("24-28%", "female_24_28"),
        ("29-33%", "female_29_33"),
        ("34-37%", "female_34_37"),
        ("38-42%", "female_38_42"),
        ("43-49%", "female_43_49"),
        ("50% +", "female_50_plus")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 1)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("What is your body fat level?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Do not worry about being too precise. A visual assessment is sufficient.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            
            // Body fat grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(bodyFatRanges, id: \.0) { range, imageName in
                    BodyFatOption(
                        percentage: range,
                        imageName: imageName,
                        isSelected: selectedBodyFat == range
                    ) {
                        selectedBodyFat = range
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
        .background(Color.nutriSyncBackground)
    }
}

struct BodyFatOption: View {
    let percentage: String
    let imageName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    // Placeholder for body silhouette
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isSelected ? Color.nutriSyncBackground : .white.opacity(0.5))
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.nutriSyncBackground)
                    }
                }
                
                Text(percentage)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
        }
    }
}

struct MFProgressBar: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step == 1 {
                    Rectangle()
                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.2))
                        .frame(height: 3)
                } else {
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 3, height: 3)
                        Rectangle()
                            .fill(step <= currentStep ? Color.white : Color.white.opacity(0.2))
                            .frame(height: 3)
                    }
                }
            }
        }
        .frame(height: 3)
    }
}

struct MFBodyFatLevelView_Previews: PreviewProvider {
    static var previews: some View {
        MFBodyFatLevelView()
    }
}
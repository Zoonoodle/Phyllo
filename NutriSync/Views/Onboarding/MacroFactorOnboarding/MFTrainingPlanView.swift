//
//  MFTrainingPlanView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 15
//

import SwiftUI

struct MFTrainingPlanView: View {
    @State private var selectedTraining = "None or Relaxed Activity"
    
    let trainingOptions = [
        ("None or Relaxed Activity", "figure.stand"),
        ("Lifting", "dumbbell"),
        ("Cardio", "bicycle"),
        ("Cardio & Lifting", "checkmark")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 13)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("What training will you do during this program?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Choose the training you plan to do during this program, if any.")
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            
            // Training options
            VStack(spacing: 16) {
                ForEach(trainingOptions, id: \.0) { option, icon in
                    TrainingOption(
                        title: option,
                        icon: icon,
                        isSelected: selectedTraining == option
                    ) {
                        selectedTraining = option
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
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.systemGray6))
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
                    .foregroundColor(.gray)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.white)
    }
}

struct TrainingOption: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.black)
                    .frame(width: 24)
                
                // Title
                Text(title)
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color(UIColor.systemGray4), lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct MFTrainingPlanView_Previews: PreviewProvider {
    static var previews: some View {
        MFTrainingPlanView()
    }
}
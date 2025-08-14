//
//  MFCalorieFloorView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 14
//

import SwiftUI

struct MFCalorieFloorView: View {
    @State private var selectedFloor = "Standard Floor"
    
    let floors = [
        ("Standard Floor", "star", "Your recommendations will never go below ~1200 Calories even if your TDEE adjusts over time."),
        ("Low Floor", "exclamationmark.circle", "Your recommendations will never go below ~800 Calories. Proceed with caution.")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 12)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("What calorie floor do you prefer?")
                .font(.system(size: 28, weight: .bold))
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.black)
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.white)
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
                    .foregroundColor(.black)
                    .frame(width: 30, height: 30)
                    .padding(.top, 20)
                
                // Text content
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color(UIColor.systemGray4), lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
        }
    }
}

struct MFCalorieFloorView_Previews: PreviewProvider {
    static var previews: some View {
        MFCalorieFloorView()
    }
}
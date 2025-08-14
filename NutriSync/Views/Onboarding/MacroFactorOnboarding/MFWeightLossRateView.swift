//
//  MFWeightLossRateView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 11
//

import SwiftUI

struct MFWeightLossRateView: View {
    @State private var selectedRate: Double = 0.5 // Default to Standard
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 10)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("At what rate?")
                .font(.system(size: 28, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Set your desired rate of weight loss.")
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            
            // Rate section
            VStack(spacing: 32) {
                // Title with green text
                Text("Standard (Recommended)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.3))
                
                // Slider
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 4)
                        
                        // Active track
                        Rectangle()
                            .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                            .frame(width: sliderPosition, height: 4)
                        
                        // Thumb with checkmark
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.2, green: 0.7, blue: 0.3))
                                .frame(width: 32, height: 32)
                                .offset(x: sliderPosition - 16)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: sliderPosition - 16)
                        }
                    }
                    
                    // Tick marks
                    HStack {
                        ForEach(0..<21) { _ in
                            Rectangle()
                                .fill(Color(UIColor.systemGray4))
                                .frame(width: 1, height: 8)
                            
                            if true { // Add spacing
                                Spacer()
                            }
                        }
                        Rectangle()
                            .fill(Color(UIColor.systemGray4))
                            .frame(width: 1, height: 8)
                    }
                }
                .padding(.horizontal, 40)
                
                // Rate details
                VStack(spacing: 16) {
                    Text("−0.82 lbs (0.5 % BW) / Week")
                        .font(.system(size: 18))
                    
                    Text("−3.28 lbs (2.0 % BW) / Month")
                        .font(.system(size: 18))
                    
                    Spacer().frame(height: 16)
                    
                    Text("~ 1400 kcal estimated daily calorie target")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                    
                    Text("Approximate end date: 14 Sept 2025")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                }
            }
            
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
                    // Done action
                } label: {
                    HStack(spacing: 6) {
                        Text("Done with goal")
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
    
    private var sliderPosition: CGFloat {
        // Calculate position based on selected rate
        let screenWidth = UIScreen.main.bounds.width
        let sliderWidth = screenWidth - 120 // Account for padding
        return sliderWidth * 0.4 // Position at 40% for "Standard"
    }
}

struct MFWeightLossRateView_Previews: PreviewProvider {
    static var previews: some View {
        MFWeightLossRateView()
    }
}
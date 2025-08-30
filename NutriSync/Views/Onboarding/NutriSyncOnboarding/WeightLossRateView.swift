//
//  WeightLossRateView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 11 - Dark Theme
//

import SwiftUI

struct WeightLossRateView: View {
    @State private var selectedRate: Double = 0.5 // Default to Standard
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 10)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("At what rate?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("Set your desired rate of weight loss.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            
            // Rate section
            VStack(spacing: 32) {
                // Title without green text
                Text("Standard (Recommended)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                // Slider
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 4)
                        
                        // Active track
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: sliderPosition, height: 4)
                        
                        // Thumb with checkmark
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .offset(x: sliderPosition - 16)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.nutriSyncBackground)
                                .offset(x: sliderPosition - 16)
                        }
                    }
                    
                    // Tick marks
                    HStack {
                        ForEach(0..<21) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 1, height: 8)
                            
                            if true { // Add spacing
                                Spacer()
                            }
                        }
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 1, height: 8)
                    }
                }
                .padding(.horizontal, 40)
                
                // Rate details
                VStack(spacing: 16) {
                    Text("−0.82 lbs (0.5 % BW) / Week")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    Text("−3.28 lbs (2.0 % BW) / Month")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    Spacer().frame(height: 16)
                    
                    Text("~ 1400 kcal estimated daily calorie target")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Approximate end date: 14 Sept 2025")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
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
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
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
    
    private var sliderPosition: CGFloat {
        // Calculate position based on selected rate
        let screenWidth = UIScreen.main.bounds.width
        let sliderWidth = screenWidth - 120 // Account for padding
        return sliderWidth * 0.4 // Position at 40% for "Standard"
    }
}

struct WeightLossRateView_Previews: PreviewProvider {
    static var previews: some View {
        WeightLossRateView()
    }
}
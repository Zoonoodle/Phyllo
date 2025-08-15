//
//  MFNotToWorryView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 6 - Dark Theme
//

import SwiftUI

struct MFNotToWorryView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 6)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Not to worry!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("MacroFactor will monitor and fine-tune your estimated expenditure over time. This is just a starting point.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    // Week 1
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 1")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("MacroFactor will use an expenditure estimate of 1805 kcal to create your first program.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Week 2
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 2")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("After you log eight consecutive days of nutrition and weight data, our algorithm will start calibrating this estimate based on how your weight is responding to your caloric intake.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Week 3 and beyond
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 3 and beyond")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Our algorithm will get your expenditure estimate dialed in without any need for activity tracking. Energy expenditure tends to change over time, but MacroFactor will continue to adjust and refine your expenditure estimate to keep you on track with your goal.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 20)
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
                }
                
                Spacer()
                
                Button {
                    // Next action
                } label: {
                    HStack(spacing: 6) {
                        Text("Done with basics")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(hex: "0A0A0A"))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color(hex: "0A0A0A"))
    }
}

struct MFNotToWorryView_Previews: PreviewProvider {
    static var previews: some View {
        MFNotToWorryView()
    }
}
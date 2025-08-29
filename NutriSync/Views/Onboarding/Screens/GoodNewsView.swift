//
//  GoodNewsView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct GoodNewsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateElements = false
    @State private var numberValue = 0
    
    private var daysGained: Int {
        // Calculate based on improvement potential
        let energyDeficit = 10 - viewModel.userData.currentEnergyLevel
        let improvementPotential = Double(energyDeficit) * 0.85 // 85% improvement
        return Int(improvementPotential * 365 / 24)
    }
    
    var body: some View {
        OnboardingScreenBase(
            viewModel: viewModel,
            showBack: true,
            nextTitle: "Show Me How"
        ) {
            VStack(spacing: 0) {
                // Progress indicator animation
                if animateElements {
                    HStack(spacing: 12) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .scaleEffect(animateElements ? 1 : 0)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.1),
                                    value: animateElements
                                )
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                } else {
                    Spacer()
                        .frame(height: 108)
                }
            
            // Title
            VStack(spacing: 8) {
                Text("The good news is NutriSync")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
                
                Text("can help you gain back")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            
            // Animated number (Opal-style big impact)
            VStack(spacing: 8) {
                Text("\(numberValue)+")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "00D26A"))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 1.5, dampingFraction: 0.7), value: numberValue)
                
                Text("days")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(Color(hex: "00D26A"))
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(1.2), value: animateElements)
            }
            .padding(.bottom, 32)
            
            // Description
            VStack(spacing: 8) {
                Text("of peak energy and focus per year")
                    .font(.title3)
                    .foregroundColor(.white)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                
                Text("Based on your profile and our meal timing optimization")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(1.5), value: animateElements)
            }
            
                Spacer()
            }
            .onAppear {
                animateElements = true
                
                // Animate the number counting up
                withAnimation(.easeOut(duration: 1.8).delay(0.6)) {
                    numberValue = max(85, daysGained) // Minimum 85 days
                }
            }
        }
    }
}

// MARK: - Preview
struct GoodNewsView_Previews: PreviewProvider {
    static var previews: some View {
        GoodNewsView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
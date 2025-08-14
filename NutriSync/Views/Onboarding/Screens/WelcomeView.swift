//
//  WelcomeView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animateElements = false
    
    var body: some View {
        OnboardingScreenBase(
            viewModel: viewModel,
            showBack: true,
            nextTitle: "Get Started"
        ) {
            VStack(spacing: 0) {
                Spacer()
                
                // Logo with animation
                VStack(spacing: 24) {
                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(Color(hex: "00D26A"))
                        .scaleEffect(animateElements ? 1 : 0.8)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: animateElements)
                    
                    Text("NutriSync")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateElements)
                }
                .padding(.bottom, 48)
                
                // Tagline
                VStack(spacing: 16) {
                    Text("Transform Your Energy Through\nSmart Nutrition Timing")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateElements)
                    
                    Text("Join thousands optimizing their daily performance")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: animateElements)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Sign in link
                Button {
                    // Handle sign in
                } label: {
                    Text("Already have an account?")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 16)
                }
                .opacity(animateElements ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: animateElements)
            }
            .onAppear {
                animateElements = true
            }
        }
    }
}

// MARK: - Preview
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
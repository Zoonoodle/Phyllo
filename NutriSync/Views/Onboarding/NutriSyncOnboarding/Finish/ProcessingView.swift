//
//  ProcessingView.swift
//  NutriSync
//
//  Processing animation screen for onboarding completion
//

import SwiftUI

struct ProcessingView: View {
    @Binding var message: String
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Circular progress indicator with NutriSync lime green
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    // Animated gradient circle (inspired by MacroFactor)
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.nutriSyncAccent,
                                    Color.nutriSyncAccent.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Inner pulse effect
                    Circle()
                        .fill(Color.nutriSyncAccent.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Message text
                Text(message)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .animation(.easeInOut(duration: 0.3), value: message)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ProcessingView(message: .constant("Creating your personalized schedule..."))
}
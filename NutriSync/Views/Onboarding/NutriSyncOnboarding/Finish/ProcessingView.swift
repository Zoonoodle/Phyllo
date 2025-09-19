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
                
                // Large circular progress indicator - clean outline only
                ZStack {
                    // Background circle (subtle)
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 3)
                        .frame(width: 220, height: 220)
                    
                    // Animated gradient circle outline
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.nutriSyncAccent,
                                    Color.nutriSyncAccent.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 5)
                                .repeatForever(autoreverses: false),
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
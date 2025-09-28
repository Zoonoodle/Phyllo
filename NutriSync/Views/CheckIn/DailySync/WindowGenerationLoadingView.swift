//
//  WindowGenerationLoadingView.swift
//  NutriSync
//
//  Loading animation for window generation after Daily Sync
//

import SwiftUI

struct WindowGenerationLoadingView: View {
    @State private var isAnimating = false
    @State private var currentMessage = 0
    
    let messages = [
        "Generating your personalized schedule...",
        "Analyzing your preferences...",
        "Optimizing meal timing...",
        "Calculating nutrition distribution...",
        "Finalizing your windows..."
    ]
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 60) {
                Spacer()
                
                // Large circular progress indicator - matches onboarding style
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
                            Animation.linear(duration: 2.5)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Center icon
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(.nutriSyncAccent)
                            .opacity(isAnimating ? 1 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("AI POWERED")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1.5)
                    }
                }
                
                // Rotating messages
                VStack(spacing: 8) {
                    Text(messages[currentMessage])
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut(duration: 0.5), value: currentMessage)
                    
                    // Progress dots
                    HStack(spacing: 6) {
                        ForEach(0..<messages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentMessage ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut, value: currentMessage)
                        }
                    }
                    .padding(.top, 12)
                }
                
                Spacer()
                
                // Subtle loading hint
                Text("This may take a few seconds...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
            
            // Rotate through messages
            Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { timer in
                withAnimation {
                    currentMessage = (currentMessage + 1) % messages.count
                }
            }
        }
    }
}

// MARK: - Preview
struct WindowGenerationLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        WindowGenerationLoadingView()
            .preferredColorScheme(.dark)
    }
}
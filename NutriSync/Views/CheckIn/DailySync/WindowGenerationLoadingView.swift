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
    @State private var currentFactIndex = 0

    // Progress messages - shown sequentially
    let messages = [
        "Analyzing your daily context...",
        "Optimizing meal timing...",
        "Calculating macro distribution...",
        "Finalizing your windows..."
    ]

    // Meal timing science facts - shown as educational tips
    let scienceFacts = [
        "Protein timing around workouts can boost muscle synthesis by 25-30%",
        "Eating within 3 hours of bedtime can reduce sleep quality by up to 30%",
        "Your metabolism is 10-15% higher in the morning hours",
        "Spacing meals 4-5 hours apart optimizes insulin sensitivity",
        "Pre-workout carbs increase exercise performance by 12-15%",
        "Post-workout meals have a 2-hour optimal absorption window",
        "Circadian-aligned eating can improve metabolic health by 20%",
        "Consistent meal timing regulates hunger hormones naturally",
        "Strategic fasting windows can enhance fat oxidation by 40%"
    ]
    
    var body: some View {
        ZStack {
            // Full screen background
            Color.nutriSyncBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
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

                    // Center logo - using appLogo from asset catalog
                    Image("appLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .opacity(isAnimating ? 1 : 0.3)
                        .scaleEffect(isAnimating ? 1.0 : 0.95)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .padding(.top, 40)

                Spacer()
                    .frame(height: 80)

                // Progress message and dots
                VStack(spacing: 16) {
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
                }

                Spacer()

                // Science fact card at bottom (replacing "This may take a few seconds")
                VStack(spacing: 8) {
                    Text("DID YOU KNOW?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.nutriSyncAccent)
                        .tracking(1.2)

                    Text(scienceFacts[currentFactIndex])
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                        .animation(.easeInOut(duration: 0.5), value: currentFactIndex)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }

            // Rotate through progress messages
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentMessage = (currentMessage + 1) % messages.count
                }
            }

            // Rotate through science facts (every 4 seconds for longer read time)
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentFactIndex = (currentFactIndex + 1) % scienceFacts.count
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
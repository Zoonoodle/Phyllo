//
//  TrialWelcomeView.swift
//  NutriSync
//
//  Welcome screen for users starting their free trial - NOT a paywall
//

import SwiftUI

struct TrialWelcomeView: View {
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header with celebration
                    headerSection

                    // What you get section
                    trialBenefitsSection

                    // Get started button
                    startButton

                    // Subscribe later hint
                    subscribeHint

                    Spacer(minLength: 40)
                }
            }
        }
        .onAppear {
            // Trigger confetti animation
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showConfetti = true
            }

            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Celebration icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color.nutriSyncAccent.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Party icon
                Text("🎉")
                    .font(.system(size: 72))
                    .scaleEffect(showConfetti ? 1.0 : 0.5)
                    .opacity(showConfetti ? 1.0 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
            }
            .padding(.top, 60)

            // Welcome text
            VStack(spacing: 12) {
                Text("Welcome to NutriSync!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Your 24-hour free trial is now active")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.nutriSyncAccent)
            }

            // Trial explanation
            Text("Experience the full power of AI-powered nutrition tracking. No payment required to get started.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Benefits Section

    private var trialBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your trial includes:")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 32)

            VStack(spacing: 16) {
                TrialBenefitRow(
                    icon: "camera.viewfinder",
                    title: "4 Free Meal Scans",
                    description: "Snap photos and get instant AI nutrition analysis",
                    highlight: true
                )

                TrialBenefitRow(
                    icon: "calendar.badge.clock",
                    title: "1 Daily Sync",
                    description: "Generate your personalized meal schedule",
                    highlight: true
                )

                TrialBenefitRow(
                    icon: "sparkles",
                    title: "Full Feature Access",
                    description: "All premium features unlocked for 24 hours",
                    highlight: false
                )

                TrialBenefitRow(
                    icon: "creditcard.trianglebadge.exclamationmark",
                    title: "No Payment Required",
                    description: "Your trial is completely free - no card needed",
                    highlight: false
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 40)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button(action: {
            onDismiss?()
            dismiss()
        }) {
            HStack(spacing: 12) {
                Text("Start My Free Trial")
                    .font(.system(size: 18, weight: .bold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(Color.nutriSyncAccent)
            .cornerRadius(16)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Subscribe Hint

    private var subscribeHint: some View {
        VStack(spacing: 8) {
            Text("Love it? Subscribe anytime for unlimited access")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text("Trial ends in 24 hours")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.4))
        }
        .padding(.top, 24)
    }
}

// MARK: - Benefit Row

struct TrialBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    let highlight: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(highlight ? Color.nutriSyncAccent.opacity(0.15) : Color.white.opacity(0.05))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(highlight ? .nutriSyncAccent : .white.opacity(0.7))
            }

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Checkmark for highlighted items
            if highlight {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.nutriSyncAccent)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            highlight ? Color.nutriSyncAccent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview {
    TrialWelcomeView(onDismiss: { print("Dismissed") })
        .preferredColorScheme(.dark)
}

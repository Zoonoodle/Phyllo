//
//  NoWindowsForScanView.swift
//  NutriSync
//
//  Created on 10/29/25.
//

import SwiftUI

struct NoWindowsForScanView: View {
    @State private var showContent = false
    @State private var animateText = false
    @State private var animateIcon = false
    var onStartDailySync: () -> Void

    var body: some View {
        ZStack {
            // Dark background matching scan tab
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 80)

                // Camera icon with animation
                ZStack {
                    // Outer glow circle
                    Circle()
                        .fill(Color.nutriSyncAccent.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                        .opacity(animateIcon ? 1.0 : 0)

                    // Inner circle
                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                        .opacity(animateIcon ? 1.0 : 0)

                    // Camera icon
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.nutriSyncAccent)
                        .scaleEffect(animateIcon ? 1.0 : 0.8)
                        .opacity(animateIcon ? 1.0 : 0)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateIcon)

                Spacer()
                    .frame(height: 48)

                // Main message
                VStack(spacing: 16) {
                    Text("Ready to scan?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animateText ? 1.0 : 0)
                        .offset(y: animateText ? 0 : 20)

                    Text("First, let's set up your personalized meal schedule with a quick daily check-in.")
                        .font(.system(size: 16))
                        .foregroundColor(.nutriSyncTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                        .opacity(animateText ? 1.0 : 0)
                        .offset(y: animateText ? 0 : 20)
                }
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animateText)

                Spacer()

                // Bottom section with button
                VStack(spacing: 24) {
                    // Info text
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)

                        Text("Takes less than 15 seconds")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.nutriSyncTextTertiary)
                    }
                    .opacity(animateText ? 1.0 : 0)

                    // Start button
                    Button(action: {
                        onStartDailySync()
                    }) {
                        HStack(spacing: 12) {
                            Text("Start Daily Check-In")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nutriSyncAccent)
                        .cornerRadius(16)
                    }
                    .opacity(animateText ? 1.0 : 0)
                    .scaleEffect(animateText ? 1.0 : 0.95)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateText)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
                animateText = true
                animateIcon = true
            }
        }
    }
}

#Preview {
    NoWindowsForScanView(onStartDailySync: {
        print("Start daily sync")
    })
    .preferredColorScheme(.dark)
}

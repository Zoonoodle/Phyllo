//
//  MorningCheckInNudge.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct MorningCheckInNudge: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @State private var checkInButtonFrame: CGRect = .zero
    @State private var showSpotlight = true
    @State private var animateContent = false
    
    let onCheckIn: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Spotlight overlay
            SpotlightOverlay(
                spotlightFrame: checkInButtonFrame.isEmpty ? CGRect(x: UIScreen.main.bounds.width/2 - 150, y: 200, width: 300, height: 180) : checkInButtonFrame,
                cornerRadius: 20,
                dimOpacity: 0.85,
                isShowing: $showSpotlight
            ) {
                onDismiss()
            }
            
            // Nudge card positioned above the spotlight
            if showSpotlight {
                VStack(spacing: 0) {
                    // Position nudge above the check-in card
                    Spacer()
                        .frame(height: max(50, checkInButtonFrame.minY - 250))
                    
                    VStack(spacing: 16) {
                        // Icon
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                            .scaleEffect(animateContent ? 1 : 0.5)
                            .opacity(animateContent ? 1 : 0)
                        
                        VStack(spacing: 8) {
                            Text("Start Your Day Right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Complete your morning check-in to generate today's personalized meal schedule")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : 20)
                        
                        // Arrow pointing down
                        Image(systemName: "arrow.down")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                            .opacity(animateContent ? 0.8 : 0)
                            .offset(y: animateContent ? 0 : -10)
                            .padding(.top, 8)
                    }
                    .padding(24)
                    .frame(maxWidth: 320)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    )
                    .scaleEffect(animateContent ? 1 : 0.9)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Get the frame of the morning check-in card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                findMorningCheckInFrame()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                    animateContent = true
                }
            }
        }
    }
    
    private func findMorningCheckInFrame() {
        // This would normally get the actual frame from the Focus view
        // For now, using estimated position
        let screenWidth = UIScreen.main.bounds.width
        checkInButtonFrame = CGRect(
            x: 20,
            y: 150,
            width: screenWidth - 40,
            height: 180
        )
    }
}

// Preview
struct MorningCheckInNudge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            // Simulate Focus view with morning check-in card
            VStack {
                // Placeholder for morning check-in card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.nutriSyncAccent)
                            Text("Complete Morning Check-In")
                                .foregroundColor(.white)
                        }
                    )
                    .padding()
                Spacer()
            }
            
            MorningCheckInNudge(
                onCheckIn: {
                },
                onDismiss: {
                }
            )
        }
    }
}
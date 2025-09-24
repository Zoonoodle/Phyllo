//
//  DailySyncNudge.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct DailySyncNudge: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @State private var syncButtonFrame: CGRect = .zero
    @State private var showSpotlight = true
    @State private var animateContent = false
    
    let onSync: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Spotlight overlay
            SpotlightOverlay(
                spotlightFrame: syncButtonFrame.isEmpty ? CGRect(x: UIScreen.main.bounds.width/2 - 150, y: 200, width: 300, height: 180) : syncButtonFrame,
                cornerRadius: 20,
                dimOpacity: 0.85,
                isShowing: $showSpotlight
            ) {
                onDismiss()
            }
            
            // Nudge card positioned above the spotlight
            if showSpotlight {
                VStack(spacing: 0) {
                    // Position nudge above the sync card
                    Spacer()
                        .frame(height: max(50, syncButtonFrame.minY - 250))
                    
                    VStack(spacing: 16) {
                        // Icon - changes based on time of day
                        Image(systemName: getTimeBasedIcon())
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(.nutriSyncAccent)
                            .scaleEffect(animateContent ? 1 : 0.5)
                            .opacity(animateContent ? 1 : 0)
                        
                        VStack(spacing: 8) {
                            Text(getTimeBasedTitle())
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Sync your nutrition plan for \(getTimeBasedMessage())")
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
            // Get the frame of the daily sync card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                findDailySyncFrame()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                    animateContent = true
                }
            }
        }
    }
    
    private func findDailySyncFrame() {
        // This would normally get the actual frame from the Focus view
        // For now, using estimated position
        let screenWidth = UIScreen.main.bounds.width
        syncButtonFrame = CGRect(
            x: 20,
            y: 150,
            width: screenWidth - 40,
            height: 180
        )
    }
    
    private func getTimeBasedIcon() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12:
            return "sun.max.fill"
        case 12..<17:
            return "sun.haze.fill"
        case 17..<21:
            return "moon.stars.fill"
        default:
            return "moon.zzz.fill"
        }
    }
    
    private func getTimeBasedTitle() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12:
            return "Start Your Day Right"
        case 12..<17:
            return "Adjust Your Afternoon"
        case 17..<21:
            return "Optimize Your Evening"
        default:
            return "Night Shift Mode"
        }
    }
    
    private func getTimeBasedMessage() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 4..<12:
            return "today's personalized meal schedule"
        case 12..<17:
            return "your remaining meals today"
        case 17..<21:
            return "tonight and tomorrow's prep"
        default:
            return "your overnight nutrition needs"
        }
    }
}

// Preview
struct DailySyncNudge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            // Simulate Focus view with daily sync card
            VStack {
                // Placeholder for daily sync card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 40))
                                .foregroundColor(.nutriSyncAccent)
                            Text("Daily Nutrition Sync")
                                .foregroundColor(.white)
                        }
                    )
                    .padding()
                Spacer()
            }
            
            DailySyncNudge(
                onSync: {},
                onDismiss: {}
            )
        }
    }
}
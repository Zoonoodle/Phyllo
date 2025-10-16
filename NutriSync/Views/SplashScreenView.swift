//
//  SplashScreenView.swift
//  NutriSync
//
//  Animated splash screen with glowing logo
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showSplash = true
    @State private var glowIntensity: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.9

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()

            if showSplash {
                // Full logo with glow effect
                Image("appLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .shadow(color: Color.nutriSyncAccent.opacity(glowIntensity), radius: 40, x: 0, y: 0)
                    .shadow(color: Color.nutriSyncAccent.opacity(glowIntensity * 0.6), radius: 20, x: 0, y: 0)
                    .shadow(color: Color.nutriSyncAccent.opacity(glowIntensity * 0.4), radius: 10, x: 0, y: 0)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Phase 1: Fade in and scale up slightly (0.5s)
        withAnimation(.easeOut(duration: 0.5)) {
            scale = 1.0
            opacity = 1.0
        }

        // Phase 2: Glow pulses (start at 0.3s, duration 1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.6)) {
                glowIntensity = 0.4
            }

            // Glow fades slightly but stays visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    glowIntensity = 0.2
                }
            }
        }

        // Phase 3: Fade out everything (starts at 1.8s, duration 0.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 0
                glowIntensity = 0
            }

            // Phase 4: Complete and transition (total 2.2s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                showSplash = false
                onComplete()
            }
        }
    }
}

// MARK: - Preview
struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(onComplete: {
            print("Splash complete")
        })
    }
}

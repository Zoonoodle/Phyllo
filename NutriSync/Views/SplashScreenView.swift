//
//  SplashScreenView.swift
//  NutriSync
//
//  Animated splash screen with logo pieces spreading apart
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showSplash = true
    @State private var leftPieceOffset: CGFloat = 0
    @State private var rightPieceOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.2
    @State private var opacity: Double = 1.0

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()

            if showSplash {
                // Logo pieces
                HStack(spacing: 0) {
                    // Left piece (white "N")
                    Image("appLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .mask(
                            Rectangle()
                                .frame(width: 100, height: 200)
                                .offset(x: -50) // Mask left half
                        )
                        .offset(x: leftPieceOffset)
                        .scaleEffect(scale)
                        .opacity(opacity)

                    // Right piece (green accent)
                    Image("appLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .mask(
                            Rectangle()
                                .frame(width: 100, height: 200)
                                .offset(x: 50) // Mask right half
                        )
                        .offset(x: rightPieceOffset)
                        .scaleEffect(scale)
                        .opacity(opacity)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        // Phase 1: Initial pause (0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Phase 2: Spread apart and enlarge (0.8s)
            withAnimation(.easeInOut(duration: 0.8)) {
                leftPieceOffset = -60  // Move left piece to the left
                rightPieceOffset = 60   // Move right piece to the right
                scale = 1.5             // Enlarge
            }

            // Phase 3: Fade out (0.4s) - starts at 0.6s
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }

                // Phase 4: Complete and transition (total 1.4s)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showSplash = false
                    onComplete()
                }
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

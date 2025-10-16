//
//  SplashScreenView.swift
//  NutriSync
//
//  Animated splash screen with logo pieces spreading apart
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showSplash = true
    @State private var leftPieceOffsetX: CGFloat = 0
    @State private var leftPieceOffsetY: CGFloat = 0
    @State private var rightPieceOffsetX: CGFloat = 0
    @State private var rightPieceOffsetY: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()

            if showSplash {
                // Logo pieces stacked together
                ZStack {
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
                        .offset(x: leftPieceOffsetX, y: leftPieceOffsetY)
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
                        .offset(x: rightPieceOffsetX, y: rightPieceOffsetY)
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
        // Phase 1: Show logo in default state (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            // Phase 2: Separate diagonally and scale up (0.8s)
            withAnimation(.easeOut(duration: 0.8)) {
                // Left piece goes up-left
                leftPieceOffsetX = -80
                leftPieceOffsetY = -80

                // Right piece goes down-right
                rightPieceOffsetX = 80
                rightPieceOffsetY = 80

                // Scale up both pieces
                scale = 1.4
            }

            // Phase 3: Fade out (0.4s) - starts at 0.6s into separation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }

                // Phase 4: Complete and transition (total 2.6s)
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

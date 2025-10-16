//
//  SplashScreenView.swift
//  NutriSync
//
//  Animated splash screen with logo pieces spreading apart
//

import SwiftUI

struct SplashScreenView: View {
    @State private var showSplash = true
    @State private var whitePieceOffsetX: CGFloat = 0
    @State private var whitePieceOffsetY: CGFloat = 0
    @State private var greenPieceOffsetX: CGFloat = 0
    @State private var greenPieceOffsetY: CGFloat = 0
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
                    // White piece (upper-left ">")
                    Image("appLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .mask(
                            DiagonalMask(isUpperLeft: true)
                        )
                        .offset(x: whitePieceOffsetX, y: whitePieceOffsetY)
                        .scaleEffect(scale)
                        .opacity(opacity)

                    // Green piece (lower-right "<")
                    Image("appLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .mask(
                            DiagonalMask(isUpperLeft: false)
                        )
                        .offset(x: greenPieceOffsetX, y: greenPieceOffsetY)
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
                // White piece goes up-left
                whitePieceOffsetX = -80
                whitePieceOffsetY = -80

                // Green piece goes down-right
                greenPieceOffsetX = 80
                greenPieceOffsetY = 80

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

// MARK: - Diagonal Mask Shape
struct DiagonalMask: Shape {
    let isUpperLeft: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()

        if isUpperLeft {
            // Upper-left triangle for white piece
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        } else {
            // Lower-right triangle for green piece
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }

        return path
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

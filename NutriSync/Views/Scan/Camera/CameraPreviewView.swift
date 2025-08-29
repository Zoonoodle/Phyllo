//
//  CameraPreviewView.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct CameraPreviewView: View {
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Mock camera background with gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Vignette effect
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.3),
                            Color.black.opacity(0.5)
                        ],
                        center: .center,
                        startRadius: 150,
                        endRadius: 400
                    )
                )
            
            // Mock food preview area
            VStack {
                Spacer()
                
                // Food detection area
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 280, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white.opacity(0.3))
                            
                            Text("Point at your meal")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    )
                    .scaleEffect(pulseAnimation ? 1.02 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Spacer()
                Spacer()
            }
            
            // Simulated focus points
            ForEach(0..<3) { _ in
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .position(
                        x: CGFloat.random(in: 100...300),
                        y: CGFloat.random(in: 300...500)
                    )
                    .blur(radius: 2)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
}

#Preview {
    CameraPreviewView()
        .preferredColorScheme(.dark)
}
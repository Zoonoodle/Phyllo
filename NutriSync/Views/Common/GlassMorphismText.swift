//
//  GlassMorphismText.swift
//  NutriSync
//
//  Created by Claude on 2025-10-16.
//

import SwiftUI

struct GlassMorphismText: View {
    let text: String
    let color: Color
    let size: GlassTextSize
    let isPulsing: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.08

    enum GlassTextSize {
        case small  // For inline/compact views
        case medium // For cards
        case large  // For prominent displays

        var fontSize: CGFloat {
            switch self {
            case .small: return 13
            case .medium: return 16
            case .large: return 20
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }

        var blurRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
    }

    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: .medium, design: .rounded))
            .foregroundColor(color)
            .padding(size.padding)
            .background(
                ZStack {
                    // Frosted glass background with stronger effect
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(isPulsing ? pulseOpacity : 0.08))
                        )
                        .scaleEffect(isPulsing ? pulseScale : 1.0)

                    // Gradient border with color tint
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.4),
                                    color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )

                    // Inner glow for depth
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .blendMode(.plusLighter)
                }
            )
            .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 4)
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 2)
            .onAppear {
                if isPulsing {
                    startPulseAnimation()
                }
            }
    }

    private func startPulseAnimation() {
        // Breathing effect: subtle scale and opacity pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.02
            pulseOpacity = 0.12
        }
    }
}

// Preview
struct GlassMorphismText_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()

            VStack(spacing: 30) {
                // Small size
                GlassMorphismText(
                    text: "calculating",
                    color: .nutriSyncAccent,
                    size: .small,
                    isPulsing: false
                )

                // Medium size with pulse
                GlassMorphismText(
                    text: "analyzing portions...",
                    color: .blue,
                    size: .medium,
                    isPulsing: true
                )

                // Large size
                GlassMorphismText(
                    text: "searching nutrition info...",
                    color: .orange,
                    size: .large,
                    isPulsing: false
                )

                // Different colors with window purposes
                VStack(spacing: 16) {
                    GlassMorphismText(text: "pre-workout energy", color: .orange, size: .medium, isPulsing: false)
                    GlassMorphismText(text: "post-workout recovery", color: .blue, size: .medium, isPulsing: false)
                    GlassMorphismText(text: "sustained energy", color: .nutriSyncAccent, size: .medium, isPulsing: false)
                    GlassMorphismText(text: "metabolic boost", color: .red, size: .medium, isPulsing: false)
                    GlassMorphismText(text: "sleep optimization", color: .indigo, size: .medium, isPulsing: false)
                    GlassMorphismText(text: "recovery mode", color: .purple, size: .medium, isPulsing: false)
                    GlassMorphismText(text: "focus boost", color: .cyan, size: .medium, isPulsing: false)
                }
            }
            .padding()
        }
    }
}

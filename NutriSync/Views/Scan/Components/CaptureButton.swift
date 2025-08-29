//
//  CaptureButton.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct CaptureButton: View {
    let mode: ScanTabView.ScanMode
    @Binding var isAnimating: Bool
    let onCapture: () -> Void
    
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onCapture()
        }) {
            ZStack {
                // Pulse ring
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.5)
                    .animation(
                        Animation.easeOut(duration: 1.0)
                            .repeatForever(autoreverses: false),
                        value: pulseAnimation
                    )
                
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.5),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.white.opacity(0.2), radius: 10)
                
                // Inner circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 70, height: 70)
                    .scaleEffect(isPressed ? 0.85 : (isAnimating ? 0.9 : 1.0))
                    .shadow(color: Color.black.opacity(0.3), radius: 5, y: 2)
                
                // Mode icon
                Image(systemName: mode.icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.black)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                
                // Green accent ring when recording
                if mode == .voice && isAnimating {
                    Circle()
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 75, height: 75)
                        .opacity(0.8)
                }
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .onAppear {
            pulseAnimation = true
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 40) {
            CaptureButton(
                mode: .photo,
                isAnimating: .constant(false),
                onCapture: {}
            )
            
            CaptureButton(
                mode: .voice,
                isAnimating: .constant(true),
                onCapture: {}
            )
            
            CaptureButton(
                mode: .barcode,
                isAnimating: .constant(false),
                onCapture: {}
            )
        }
    }
    .preferredColorScheme(.dark)
}
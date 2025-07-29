//
//  VoiceInputView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isListening = true
    @State private var isPaused = false
    @State private var waveformAnimation = false
    @State private var circleScale: CGFloat = 1.0
    @State private var audioLevels: [CGFloat] = Array(repeating: 0.5, count: 5)
    
    // Mock captured image - in real app, this would be passed in
    let capturedImage: String = "photo.fill"
    
    // Timer for simulating audio levels
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background with captured photo
            backgroundLayer
            
            // Dark overlay for better visibility
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Top info icon
                HStack {
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Central listening indicator
                listeningIndicator
                
                Spacer()
                
                // Bottom controls
                bottomControls
                    .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            updateAudioLevels()
        }
    }
    
    // MARK: - Components
    
    private var backgroundLayer: some View {
        // In real app, this would be the actual captured image
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color.gray.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Image(systemName: capturedImage)
                .font(.system(size: 200))
                .foregroundColor(.white.opacity(0.1))
                .blur(radius: 20)
        }
        .ignoresSafeArea()
    }
    
    private var listeningIndicator: some View {
        VStack(spacing: 40) {
            // Main circle with waveform
            ZStack {
                // Outer pulse circle
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 280, height: 280)
                    .scaleEffect(circleScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            circleScale = 1.15
                        }
                    }
                
                // Main white circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                
                // Waveform inside circle
                if isListening && !isPaused {
                    HStack(spacing: 8) {
                        ForEach(0..<5) { index in
                            Capsule()
                                .fill(Color.black)
                                .frame(width: 6, height: audioLevels[index] * 60)
                                .animation(.spring(response: 0.3), value: audioLevels[index])
                        }
                    }
                } else if isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.black)
                }
            }
            
            // Status text
            Text(isPaused ? "Paused" : "Listening")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var bottomControls: some View {
        HStack(spacing: 120) {
            // Pause/Resume button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isPaused.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            // Voice level indicator (middle)
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(Color.white.opacity(isListening && !isPaused ? 0.8 : 0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            // Cancel button
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateAudioLevels() {
        guard isListening && !isPaused else { return }
        
        // Simulate audio levels
        for i in 0..<audioLevels.count {
            audioLevels[i] = CGFloat.random(in: 0.3...1.0)
        }
    }
}

#Preview {
    VoiceInputView()
        .preferredColorScheme(.dark)
}
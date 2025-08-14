//
//  MealAnalysisLoadingView.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct MealAnalysisLoadingView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.3
    @State private var progressValue: CGFloat = 0
    @State private var currentStatus = "Analyzing your meal..."
    @StateObject private var captureService = MealCaptureService.shared
    
    let statuses = [
        "Analyzing your meal...",
        "Identifying ingredients...",
        "Calculating nutrition...",
        "Finalizing results..."
    ]
    
    let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.3),
                                Color.green.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotation))
                
                // Inner pulsing circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)
                
                // Center icon
                Image(systemName: "brain")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
                
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.1
                    opacity = 1.0
                }
            }
            
            // Status text
            VStack(spacing: 12) {
                Text(currentStatus)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .animation(.easeInOut, value: currentStatus)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        // Progress
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressValue, height: 6)
                            .animation(.spring(response: 0.5), value: progressValue)
                    }
                }
                .frame(height: 6)
                .frame(maxWidth: 200)
            }
            
            // Processing details
            HStack(spacing: 24) {
                ProcessingDetail(icon: "camera.fill", text: "Image captured")
                ProcessingDetail(icon: "mic.fill", text: "Voice recorded")
                ProcessingDetail(icon: "sparkle", text: "AI analyzing")
            }
            .opacity(0.5)
        }
        .padding(40)
        .onReceive(timer) { _ in
            updateStatus()
        }
        .onAppear {
            // Use real progress if available, otherwise animate
            if captureService.analysisProgress > 0 {
                progressValue = CGFloat(captureService.analysisProgress)
            } else {
                // Fallback animation
                withAnimation(.linear(duration: 10)) {
                    progressValue = 0.9
                }
            }
        }
        .onChange(of: captureService.analysisProgress) { _, newValue in
            withAnimation(.spring(response: 0.5)) {
                progressValue = CGFloat(newValue)
            }
            
            // Update status based on progress
            if newValue < 0.25 {
                currentStatus = statuses[0]
            } else if newValue < 0.5 {
                currentStatus = statuses[1]
            } else if newValue < 0.75 {
                currentStatus = statuses[2]
            } else {
                currentStatus = statuses[3]
            }
        }
    }
    
    private func updateStatus() {
        if let currentIndex = statuses.firstIndex(of: currentStatus),
           currentIndex < statuses.count - 1 {
            currentStatus = statuses[currentIndex + 1]
        }
    }
}

struct ProcessingDetail: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.6))
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// Compact version for use in schedule/meal windows
struct PendingMealEntryView: View {
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]
    let mealDescription: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail with loading animation
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)
                
                // Animated dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .opacity(dotOpacity[index])
                    }
                }
            }
            .onAppear {
                animateDots()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(mealDescription)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Image(systemName: "brain")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text("Analyzing nutrition...")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(0.8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func animateDots() {
        for index in 0..<3 {
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(Double(index) * 0.2)) {
                dotOpacity[index] = 1.0
            }
        }
    }
}

#Preview("Full Loading View") {
    ZStack {
        Color.black
        MealAnalysisLoadingView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Pending Meal Entry") {
    ZStack {
        Color.black
        VStack {
            PendingMealEntryView(mealDescription: "Morning coffee with oat milk")
                .padding()
            
            PendingMealEntryView(mealDescription: "Grilled chicken salad with avocado")
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}
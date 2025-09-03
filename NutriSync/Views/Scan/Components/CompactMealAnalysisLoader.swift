//
//  CompactMealAnalysisLoader.swift
//  NutriSync
//
//  Created by Claude on 2025-09-03.
//

import SwiftUI

enum MealAnalysisLoaderSize {
    case inline  // 50x50 for window banners
    case card    // 80x80 for cards and detail views
    
    var dimension: CGFloat {
        switch self {
        case .inline: return 50
        case .card: return 80
        }
    }
}

struct CompactMealAnalysisLoader: View {
    @State private var progress: Double = 0.0
    @State private var currentMessageIndex: Int = 0
    @State private var messageTimer: Timer?
    @State private var progressTimer: Timer?
    @State private var isComplete: Bool = false
    
    let size: MealAnalysisLoaderSize
    let windowColor: Color
    let onComplete: (() -> Void)?
    
    // Status messages that rotate every 2.5 seconds
    private let statusMessages = [
        "Identifying ingredients...",
        "Calculating nutrition...",
        "Analyzing portions...",
        "Finalizing analysis..."
    ]
    
    // Simulated progress milestones with timing
    private let progressMilestones: [(progress: Double, duration: Double, messageIndex: Int)] = [
        (0.10, 0.3, 0),  // 0-10% in 0.3s - "Identifying ingredients..."
        (0.30, 0.7, 1),  // 10-30% in 0.7s - "Calculating nutrition..."
        (0.60, 1.0, 2),  // 30-60% in 1.0s - "Analyzing portions..."
        (0.85, 0.8, 3),  // 60-85% in 0.8s - "Finalizing analysis..."
        (0.99, 0.5, 3),  // 85-99% in 0.5s - Still "Finalizing analysis..."
    ]
    
    init(size: MealAnalysisLoaderSize = .inline,
         windowColor: Color = .green,
         onComplete: (() -> Void)? = nil) {
        self.size = size
        self.windowColor = windowColor
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: size == .inline ? 8 : 12) {
            // Progress ring
            MealAnalysisProgressRing(
                progress: progress,
                size: size.dimension,
                color: windowColor
            )
            
            // Status message
            Text(statusMessages[currentMessageIndex])
                .font(size == .inline ? TimelineTypography.macroLabel : TimelineTypography.statusLabel)
                .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // Start progress animation
        animateProgress()
        
        // Start message rotation
        startMessageRotation()
    }
    
    private func stopAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
        messageTimer?.invalidate()
        messageTimer = nil
    }
    
    private func animateProgress() {
        var milestoneIndex = 0
        
        func animateToNextMilestone() {
            guard milestoneIndex < progressMilestones.count else {
                // Hold at 99% until analysis completes
                return
            }
            
            let milestone = progressMilestones[milestoneIndex]
            
            // Update message when reaching certain milestones
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMessageIndex = milestone.messageIndex
            }
            
            // Animate progress to milestone
            withAnimation(.linear(duration: milestone.duration)) {
                progress = milestone.progress
            }
            
            // Schedule next milestone
            milestoneIndex += 1
            progressTimer = Timer.scheduledTimer(withTimeInterval: milestone.duration, repeats: false) { _ in
                animateToNextMilestone()
            }
        }
        
        // Start animation
        animateToNextMilestone()
    }
    
    private func startMessageRotation() {
        // Rotate messages every 2.5 seconds as backup
        // (primary message changes are driven by progress milestones)
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Only rotate if we're not at the final message
                if currentMessageIndex < statusMessages.count - 1 && progress < 0.85 {
                    currentMessageIndex = (currentMessageIndex + 1) % statusMessages.count
                }
            }
        }
    }
    
    // Call this method when the actual analysis completes
    func completeAnalysis() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            progress = 1.0
            isComplete = true
        }
        
        // Stop animations
        stopAnimation()
        
        // Call completion handler after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete?()
        }
    }
}

// Preview
struct CompactMealAnalysisLoader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 60) {
            // Inline version (window banner)
            CompactMealAnalysisLoader(
                size: .inline,
                windowColor: .green
            )
            
            // Card version (detail view)
            CompactMealAnalysisLoader(
                size: .card,
                windowColor: .blue
            )
        }
        .padding()
        .background(Color(hex: "0a0a0a"))
    }
}
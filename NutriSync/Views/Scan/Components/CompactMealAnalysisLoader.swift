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
    @ObservedObject private var agent = MealAnalysisAgent.shared
    
    let size: MealAnalysisLoaderSize
    let windowColor: Color
    let onComplete: (() -> Void)?
    
    // Default status messages that rotate every 2.5 seconds
    private let defaultMessages = [
        "Identifying ingredients...",
        "Calculating nutrition...",
        "Analyzing portions...",
        "Finalizing analysis..."
    ]
    
    // Dynamic messages based on actual analysis state
    private var currentStatusMessage: String {
        // Use agent's actual progress if available
        if !agent.toolProgress.isEmpty && agent.isUsingTools {
            return agent.toolProgress
        }
        
        // Use tool-specific message if available
        if let tool = agent.currentTool {
            return tool.displayName
        }
        
        // Fall back to rotating default messages
        return defaultMessages[currentMessageIndex]
    }
    
    // Simulated progress milestones with timing (8-9 seconds to 99%)
    private let progressMilestones: [(progress: Double, duration: Double)] = [
        (0.10, 0.8),   // 0-10% in 0.8s
        (0.25, 1.2),   // 10-25% in 1.2s  
        (0.40, 1.5),   // 25-40% in 1.5s
        (0.55, 1.5),   // 40-55% in 1.5s
        (0.70, 1.5),   // 55-70% in 1.5s
        (0.85, 1.3),   // 70-85% in 1.3s
        (0.99, 1.2),   // 85-99% in 1.2s
        // Total: 9 seconds to reach 99%
    ]
    
    init(size: MealAnalysisLoaderSize = .inline,
         windowColor: Color = .green,
         onComplete: (() -> Void)? = nil) {
        self.size = size
        self.windowColor = windowColor
        self.onComplete = onComplete
    }
    
    var body: some View {
        Group {
            if size == .inline {
                // Inline mode: just the ring, no text below
                MealAnalysisProgressRing(
                    progress: progress,
                    size: size.dimension,
                    color: windowColor
                )
            } else {
                // Card mode: ring with status message below
                VStack(spacing: 12) {
                    MealAnalysisProgressRing(
                        progress: progress,
                        size: size.dimension,
                        color: windowColor
                    )
                    
                    // Dynamic status message
                    Text(currentStatusMessage)
                        .font(TimelineTypography.statusLabel)
                        .foregroundColor(.white.opacity(TimelineOpacity.secondary))
                        .animation(.easeInOut(duration: 0.3), value: currentStatusMessage)
                }
            }
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
                // Keep message rotation going
                return
            }
            
            let milestone = progressMilestones[milestoneIndex]
            
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
        // Rotate messages every 2.5 seconds
        // Continue rotating even at 99% to show activity
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Always rotate through all messages, even at 99%
                currentMessageIndex = (currentMessageIndex + 1) % defaultMessages.count
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
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
    @State private var currentMessageIndex: Int = 0
    @State private var messageTimer: Timer?
    @ObservedObject private var agent = MealAnalysisAgent.shared

    let size: MealAnalysisLoaderSize
    let windowColor: Color
    let onComplete: (() -> Void)?
    
    // Default status messages that rotate every 2.5 seconds
    private let defaultMessages = [
        "identifying ingredients",
        "calculating nutrition",
        "analyzing portions",
        "searching nutrition info",
        "finalizing analysis"
    ]
    
    // Dynamic messages based on actual analysis state
    private var currentStatusMessage: String {
        // Use agent's actual progress if available
        if !agent.toolProgress.isEmpty && agent.isUsingTools {
            // Convert to lowercase to match glass text style
            return agent.toolProgress.lowercased()
        }

        // Use tool-specific message if available
        if let tool = agent.currentTool {
            return tool.displayName.lowercased()
        }

        // Fall back to rotating default messages
        return defaultMessages[currentMessageIndex]
    }
    
    init(size: MealAnalysisLoaderSize = .inline,
         windowColor: Color = .green,
         onComplete: (() -> Void)? = nil) {
        self.size = size
        self.windowColor = windowColor
        self.onComplete = onComplete
    }
    
    var body: some View {
        GlassMorphismText(
            text: currentStatusMessage,
            color: windowColor,
            size: size == .inline ? .small : .medium
        )
        .id(currentStatusMessage) // Force view update on message change
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStatusMessage)
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
    }
    
    private func startAnimation() {
        // Start message rotation only
        startMessageRotation()
    }
    
    private func stopAnimation() {
        messageTimer?.invalidate()
        messageTimer = nil
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
        // Stop animations
        stopAnimation()

        // Call completion handler
        onComplete?()
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
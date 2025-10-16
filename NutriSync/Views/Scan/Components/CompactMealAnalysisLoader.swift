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
    @State private var timeoutTimer: Timer?
    @State private var isCompleted: Bool = false
    @State private var isTimedOut: Bool = false
    @ObservedObject private var agent = MealAnalysisAgent.shared

    let size: MealAnalysisLoaderSize
    let windowColor: Color
    let showStageIndicators: Bool
    let onComplete: (() -> Void)?
    let mealId: UUID?
    
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
        // Show timeout message if timed out
        if isTimedOut {
            return "analysis taking longer than expected..."
        }

        // Show completion message if completed
        if isCompleted {
            return "complete!"
        }

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
         showStageIndicators: Bool = false,
         mealId: UUID? = nil,
         onComplete: (() -> Void)? = nil) {
        self.size = size
        self.windowColor = windowColor
        self.showStageIndicators = showStageIndicators
        self.mealId = mealId
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Stage indicators (only shown if enabled)
            if showStageIndicators {
                AnalysisStageIndicator(
                    tool: agent.currentTool,
                    color: windowColor,
                    isCompleted: isCompleted
                )
            }

            // Main content
            Group {
                if isCompleted {
                    // Completion state with checkmark
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: size == .inline ? 14 : 18))
                        Text("complete!")
                            .font(.system(size: size == .inline ? 13 : 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.green)
                    .padding(size == .inline ?
                        EdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14) :
                        EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.green.opacity(0.15))
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Normal analyzing state
                    GlassMorphismText(
                        text: currentStatusMessage,
                        color: windowColor,
                        size: size == .inline ? .small : .medium,
                        isPulsing: !isCompleted && !isTimedOut  // Pulse while analyzing
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            // Animate text changes without forcing view rebuild
            .animation(.easeInOut(duration: 0.3), value: currentStatusMessage)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isCompleted)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealAnalysisCompleted)) { notification in
            // Check if this notification is for this specific meal
            if let completedMealId = notification.object as? UUID,
               let mealId = mealId,
               completedMealId == mealId {
                completeAnalysis()
            } else if mealId == nil {
                // If no mealId specified, react to any completion
                completeAnalysis()
            }
        }
    }
    
    private func startAnimation() {
        // Start message rotation
        startMessageRotation()

        // Start timeout timer (45 seconds)
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 45.0, repeats: false) { [self] _ in
            // Timeout occurred
            isTimedOut = true
            // Stop message rotation but keep showing the loader
            messageTimer?.invalidate()
            messageTimer = nil
        }
    }
    
    private func stopAnimation() {
        messageTimer?.invalidate()
        messageTimer = nil
        timeoutTimer?.invalidate()
        timeoutTimer = nil
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
        // Set completion state
        isCompleted = true

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
//
//  FirstTimeTooltips.swift
//  NutriSync
//
//  Created on 9/23/25.
//

import SwiftUI

/// Simple tooltip overlays for first-time features
struct FirstTimeTooltips: View {
    @AppStorage("hasSeenTooltips") private var hasSeenTooltips = false
    @State private var currentTip = 0
    @State private var showingTooltip = true
    
    let tooltips = [
        TooltipContent(
            icon: "hand.tap.fill",
            title: "Tap to Log",
            message: "Tap any meal window to log what you ate",
            targetArea: .mealWindow
        ),
        TooltipContent(
            icon: "camera.fill",
            title: "Quick Scan",
            message: "Use the Scan tab to analyze meals with your camera",
            targetArea: .scanTab
        ),
        TooltipContent(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Progress",
            message: "View your nutrition insights in the Momentum tab",
            targetArea: .momentumTab
        )
    ]
    
    var body: some View {
        if !hasSeenTooltips && showingTooltip && currentTip < tooltips.count {
            TooltipView(
                content: tooltips[currentTip],
                onNext: {
                    if currentTip < tooltips.count - 1 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentTip += 1
                        }
                    } else {
                        dismissTooltips()
                    }
                },
                onSkip: {
                    dismissTooltips()
                }
            )
        }
    }
    
    private func dismissTooltips() {
        withAnimation(.easeOut(duration: 0.3)) {
            showingTooltip = false
        }
        hasSeenTooltips = true
    }
}

/// Individual tooltip view
struct TooltipView: View {
    let content: TooltipContent
    let onNext: () -> Void
    let onSkip: () -> Void
    
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.9
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: content.icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.nutriSyncAccent)
                .symbolEffect(.bounce, value: opacity)
            
            // Title
            Text(content.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.white)
            
            // Message
            Text(content.message)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Buttons
            HStack(spacing: 16) {
                Button {
                    onSkip()
                } label: {
                    Text("Skip All")
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                
                Button {
                    onNext()
                } label: {
                    HStack {
                        Text("Next")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.nutriSyncAccent)
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .padding(.horizontal, 40)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                opacity = 1
                scale = 1
            }
        }
    }
}

/// Tooltip content model
struct TooltipContent {
    let icon: String
    let title: String
    let message: String
    let targetArea: TargetArea
    
    enum TargetArea {
        case mealWindow
        case scanTab
        case momentumTab
        case checkIn
    }
}

/// Inline tooltip for specific UI elements
struct InlineTooltip: ViewModifier {
    let message: String
    let show: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if show {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(Color.nutriSyncAccent)
                        }
                        .offset(y: -40)
                        .transition(.scale.combined(with: .opacity))
                }
            }
    }
}

extension View {
    func tooltip(_ message: String, show: Bool) -> some View {
        modifier(InlineTooltip(message: message, show: show))
    }
}

// MARK: - Preview

#Preview("Tooltip Sequence") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FirstTimeTooltips()
    }
}

#Preview("Single Tooltip") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TooltipView(
            content: TooltipContent(
                icon: "hand.tap.fill",
                title: "Tap to Log",
                message: "Tap any meal window to log what you ate",
                targetArea: .mealWindow
            ),
            onNext: { print("Next") },
            onSkip: { print("Skip") }
        )
    }
}

#Preview("Inline Tooltip") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        Button {
            print("Tapped")
        } label: {
            Text("Sample Button")
                .foregroundStyle(Color.white)
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .tooltip("Tap here to continue", show: true)
    }
}
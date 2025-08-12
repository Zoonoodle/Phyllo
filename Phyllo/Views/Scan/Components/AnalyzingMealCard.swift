//
//  AnalyzingMealCard.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct AnalyzingMealCard: View {
    let timestamp: Date
    @ObservedObject private var agent = MealAnalysisAgent.shared
    @State private var dotsAnimation = false
    @State private var currentMessageIndex = 0
    @State private var messageTimer: Timer?
    
    let messages = [
        "Analyzing your meal...",
        "Detecting ingredients...",
        "Calculating nutrition...",
        "Processing image...",
        "Finalizing results..."
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            // Loading indicator placeholder (where emoji would be)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 50, height: 50)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.phylloAccent)
                            .frame(width: 8, height: 8)
                            .scaleEffect(dotsAnimation ? 1.0 : 0.5)
                            .opacity(dotsAnimation ? 1.0 : 0.3)
                            .animation(
                                Animation.easeInOut(duration: 0.8)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: dotsAnimation
                            )
                    }
                }
            }
            
            // Meal info (loading state)
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.currentTool?.displayName ?? messages[currentMessageIndex])
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .animation(.easeInOut(duration: 0.3), value: agent.currentTool)
                    .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                
                HStack(spacing: 8) {
                    Text("Analyzing")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text(timeString(from: timestamp))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Tool progress indicator
                if agent.isUsingTools, agent.currentTool != nil {
                    HStack(spacing: 6) {
                        Image(systemName: agent.currentTool?.iconName ?? "sparkle")
                            .font(.system(size: 11))
                            .foregroundColor(.phylloAccent)
                        
                        Text(agent.toolProgress)
                            .font(.system(size: 12))
                            .foregroundColor(.phylloAccent.opacity(0.8))
                            .lineLimit(1)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    // Shimmer placeholder for macro data
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 12)
                        .shimmer()
                }
            }
            
            Spacer()
            
            // Loading spinner instead of chevron
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.3)))
                .scaleEffect(0.8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.phylloAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            dotsAnimation = true
            startMessageRotation()
        }
        .onDisappear {
            messageTimer?.invalidate()
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func startMessageRotation() {
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

// Timeline version with smaller design
struct AnalyzingMealRow: View {
    let timestamp: Date
    @ObservedObject private var agent = MealAnalysisAgent.shared
    @State private var dotsAnimation = false
    @State private var currentMessageIndex = 0
    @State private var messageTimer: Timer?
    
    let messages = [
        "Analyzing meal...",
        "Processing...",
        "Calculating...",
        "Almost done..."
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            // Time
            Text(timeFormatter.string(from: timestamp))
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 35)
            
            // Loading dots instead of emoji
            HStack(spacing: 3) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.phylloAccent)
                        .frame(width: 6, height: 6)
                        .scaleEffect(dotsAnimation ? 1.0 : 0.5)
                        .opacity(dotsAnimation ? 1.0 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: dotsAnimation
                        )
                }
            }
            .frame(width: 20)
            
            // Meal info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if agent.isUsingTools, agent.currentTool != nil {
                        Image(systemName: agent.currentTool?.iconName ?? "sparkle")
                            .font(.system(size: 10))
                            .foregroundColor(.phylloAccent)
                    }
                    
                    Text(agent.currentTool?.displayName ?? messages[currentMessageIndex])
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .animation(.easeInOut(duration: 0.3), value: agent.currentTool)
                        .animation(.easeInOut(duration: 0.3), value: currentMessageIndex)
                }
                
                // Shimmer for macros
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 11)
                    .shimmer()
            }
            
            Spacer()
            
            // Loading spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.3)))
                .scaleEffect(0.6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.phylloBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.phylloAccent.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            dotsAnimation = true
            startMessageRotation()
        }
        .onDisappear {
            messageTimer?.invalidate()
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter
    }
    
    private func startMessageRotation() {
        messageTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

// Shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.1),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

#Preview("Window Card") {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            AnalyzingMealCard(timestamp: Date())
                .padding()
        }
    }
}

#Preview("Timeline Row") {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack(spacing: 20) {
            AnalyzingMealRow(timestamp: Date())
                .padding()
            
            // Preview of final state
            let mockMeal = LoggedMeal(
                name: "Chicken Salad",
                calories: 450,
                protein: 35,
                carbs: 20,
                fat: 25,
                timestamp: Date()
            )
            MealRow(meal: mockMeal)
                .padding()
        }
    }
}
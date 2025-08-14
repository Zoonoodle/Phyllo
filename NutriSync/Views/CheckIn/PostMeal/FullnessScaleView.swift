//
//  FullnessScaleView.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct FullnessScaleView: View {
    @Binding var selectedLevel: PostMealCheckIn.FullnessLevel?
    let onContinue: () -> Void
    
    @State private var animateStomach = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How full do you feel?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Understanding your satiety helps us portion meals perfectly for your goals.")
                    .font(.system(size: 15))
                    .foregroundColor(.nutriSyncTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Fullness visualization
            VStack(spacing: 32) {
                // Stomach visualization
                StomachVisualization(selectedLevel: selectedLevel)
                    .frame(width: 180, height: 180)
                
                // Fullness scale
                HStack(spacing: 0) {
                    ForEach(PostMealCheckIn.FullnessLevel.allCases, id: \.self) { level in
                        FullnessIndicator(
                            level: level,
                            isSelected: selectedLevel == level,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedLevel = level
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                
                // Selected level description
                if let selected = selectedLevel {
                    Text(selected.label)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            
            Spacer()
            
            // Continue button
            HStack {
                Spacer()
                CheckInButton("", style: .minimal) {
                    onContinue()
                }
                .disabled(selectedLevel == nil)
                .opacity(selectedLevel == nil ? 0.3 : 1.0)
                .scaleEffect(selectedLevel == nil ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedLevel)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
}

// MARK: - Stomach Visualization
struct StomachVisualization: View {
    let selectedLevel: PostMealCheckIn.FullnessLevel?
    
    @State private var animateFill = false
    
    private var fillPercentage: CGFloat {
        guard let level = selectedLevel else { return 0 }
        switch level {
        case .stillHungry: return 0.2
        case .satisfied: return 0.5
        case .full: return 0.7
        case .tooFull: return 0.85
        case .stuffed: return 1.0
        }
    }
    
    private var fillColor: Color {
        guard let level = selectedLevel else { return Color.white.opacity(0.1) }
        switch level {
        case .stillHungry: return Color.blue.opacity(0.3)
        case .satisfied: return Color.nutriSyncAccent.opacity(0.5)
        case .full: return Color.nutriSyncAccent.opacity(0.7)
        case .tooFull: return Color.orange.opacity(0.7)
        case .stuffed: return Color.red.opacity(0.7)
        }
    }
    
    var body: some View {
        ZStack {
            // Stomach outline
            StomachShape()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            
            // Fill
            StomachShape()
                .fill(Color.white.opacity(0.05))
            
            // Food fill
            StomachShape()
                .fill(fillColor)
                .mask(
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .frame(height: 180 * fillPercentage)
                    }
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: fillPercentage)
        }
    }
}

// MARK: - Stomach Shape
struct StomachShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Simple stomach-like shape
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + 20))
        
        // Left curve
        path.addCurve(
            to: CGPoint(x: rect.minX + 20, y: rect.midY),
            control1: CGPoint(x: rect.minX + 10, y: rect.minY + 40),
            control2: CGPoint(x: rect.minX + 10, y: rect.midY - 20)
        )
        
        // Bottom curve
        path.addCurve(
            to: CGPoint(x: rect.maxX - 20, y: rect.midY + 20),
            control1: CGPoint(x: rect.minX + 20, y: rect.maxY - 40),
            control2: CGPoint(x: rect.maxX - 40, y: rect.maxY - 30)
        )
        
        // Right curve
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + 20),
            control1: CGPoint(x: rect.maxX - 10, y: rect.midY - 10),
            control2: CGPoint(x: rect.maxX - 30, y: rect.minY + 40)
        )
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Fullness Indicator
struct FullnessIndicator: View {
    let level: PostMealCheckIn.FullnessLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var animatePress = false
    
    var body: some View {
        Button(action: {
            animatePress = true
            onSelect()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.prepare()
            impact.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatePress = false
            }
        }) {
            VStack(spacing: 8) {
                // Icon
                Image(systemName: level.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                // Indicator dot
                Circle()
                    .fill(isSelected ? Color.nutriSyncAccent : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .scaleEffect(animatePress ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: animatePress)
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        FullnessScaleView(
            selectedLevel: .constant(nil),
            onContinue: {}
        )
    }
}
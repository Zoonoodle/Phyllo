//
//  EnergyLevelView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct EnergyLevelView: View {
    @Binding var selectedLevel: PostMealCheckIn.EnergyLevel?
    let onContinue: () -> Void
    
    @State private var animateScale = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How's your energy level?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("This helps us optimize your meal timing and composition for sustained energy.")
                    .font(.system(size: 15))
                    .foregroundColor(.phylloTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Energy scale
            VStack(spacing: 24) {
                // Visual energy indicator
                EnergyVisualIndicator(selectedLevel: selectedLevel)
                    .frame(height: 120)
                    .padding(.horizontal, 40)
                
                // Energy level options
                VStack(spacing: 12) {
                    ForEach(PostMealCheckIn.EnergyLevel.allCases, id: \.self) { level in
                        EnergyLevelButton(
                            level: level,
                            isSelected: selectedLevel == level,
                            onSelect: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedLevel = level
                                }
                            }
                        )
                    }
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

// MARK: - Energy Visual Indicator
struct EnergyVisualIndicator: View {
    let selectedLevel: PostMealCheckIn.EnergyLevel?
    
    @State private var animateWaves = false
    
    private var waveAmplitude: CGFloat {
        guard let level = selectedLevel else { return 5 }
        return CGFloat(level.rawValue) * 3
    }
    
    private var waveFrequency: CGFloat {
        guard let level = selectedLevel else { return 0.02 }
        return 0.01 + (CGFloat(level.rawValue) * 0.005)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                
                // Energy waves
                if selectedLevel != nil {
                    ForEach(0..<3) { index in
                        WaveShape(
                            amplitude: waveAmplitude - CGFloat(index) * 2,
                            frequency: waveFrequency,
                            phase: animateWaves ? CGFloat(index) * 0.5 : 0
                        )
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: selectedLevel?.color ?? "FFFFFF").opacity(0.3 - Double(index) * 0.1),
                                    Color(hex: selectedLevel?.color ?? "FFFFFF").opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .animation(
                            .linear(duration: 2.0 + Double(index) * 0.5)
                            .repeatForever(autoreverses: false),
                            value: animateWaves
                        )
                    }
                }
            }
        }
        .onAppear {
            animateWaves = true
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var amplitude: CGFloat = 10
    var frequency: CGFloat = 0.02
    var phase: CGFloat = 0
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midHeight = rect.height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / rect.width
            let y = midHeight + amplitude * sin(relativeX * .pi * 6 + phase * .pi * 2)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Energy Level Button
struct EnergyLevelButton: View {
    let level: PostMealCheckIn.EnergyLevel
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var animatePress = false
    
    var body: some View {
        Button(action: {
            animatePress = true
            onSelect()
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animatePress = false
            }
        }) {
            HStack(spacing: 16) {
                // Color indicator
                Circle()
                    .fill(Color(hex: level.color))
                    .frame(width: 12, height: 12)
                
                // Label
                Text(level.label)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .phylloTextSecondary)
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.phylloAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.phylloAccent : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .scaleEffect(animatePress ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: animatePress)
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        EnergyLevelView(
            selectedLevel: .constant(nil),
            onContinue: {}
        )
    }
}
//
//  TargetWeightView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 10 - Dark Theme
//

import SwiftUI

struct TargetWeightView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var targetWeight: Double = 130
    @State private var currentWeight: Double = 163
    @State private var selectedUnit = "lbs"
    
    // These are not used anymore since the slider is infinite
    let minWeight: Double = 50
    let maxWeight: Double = 250
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 9)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("What is your target weight?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            
            // Weight display
            VStack(spacing: 8) {
                Text("\(Int(targetWeight)) \(selectedUnit)")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Weight ruler slider
                WeightRulerSlider(
                    value: $targetWeight,
                    minValue: minWeight,
                    maxValue: maxWeight,
                    currentWeight: currentWeight
                )
                .frame(height: 50)
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    coordinator.previousScreen()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    // Save target weight to coordinator (convert to kg if needed)
                    let weightInKg = selectedUnit == "lbs" ? targetWeight * 0.453592 : targetWeight
                    coordinator.targetWeight = weightInKg
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.nutriSyncBackground)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.nutriSyncBackground)
    }
}

struct WeightRulerSlider: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let currentWeight: Double
    
    @State private var baseOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var lastHapticValue: Int = 0
    
    private let tickSpacing: CGFloat = 10 // Increased spacing for less sensitivity
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Clipping mask
                Rectangle()
                    .fill(Color.nutriSyncBackground)
                    .mask(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.1),
                                .init(color: .black, location: 0.9),
                                .init(color: .clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                // Ruler content
                HStack(spacing: 0) {
                    ForEach(50..<250, id: \.self) { weight in
                        VStack(spacing: 4) {
                            // Labels for major ticks (every 10 lbs)
                            if weight % 10 == 0 {
                                Text("\(weight)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(height: 16)
                            } else {
                                Color.clear
                                    .frame(height: 16)
                            }
                            
                            // Tick marks
                            Rectangle()
                                .fill(Color.white.opacity(weight % 10 == 0 ? 0.5 : 0.2))
                                .frame(width: 0.5, height: weight % 10 == 0 ? 20 : (weight % 5 == 0 ? 15 : 10))
                            
                            Spacer()
                        }
                        .frame(width: tickSpacing)
                    }
                }
                .offset(x: geometry.size.width / 2 - CGFloat(value) * tickSpacing + baseOffset + dragOffset)
                
                // Green overlay for selected range
                if value < 130 {
                    Color.nutriSyncGreen.opacity(0.3)
                        .frame(width: CGFloat(130 - value) * tickSpacing)
                        .frame(height: 30)
                        .position(x: geometry.size.width / 2 - CGFloat(130 - value) * tickSpacing / 2, y: geometry.size.height / 2 + 10)
                        .allowsHitTesting(false)
                } else if value > 130 {
                    Color.nutriSyncGreen.opacity(0.3)
                        .frame(width: CGFloat(value - 130) * tickSpacing)
                        .frame(height: 30)
                        .position(x: geometry.size.width / 2 + CGFloat(value - 130) * tickSpacing / 2, y: geometry.size.height / 2 + 10)
                        .allowsHitTesting(false)
                }
                
                // Stationary center indicator
                Rectangle()
                    .fill(Color.nutriSyncGreen)
                    .frame(width: 2, height: 40)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 10)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onAppear {
                impactFeedback.prepare()
                lastHapticValue = Int(value)
            }
            .gesture(
                DragGesture()
                    .updating($dragOffset) { dragValue, state, _ in
                        // Apply damping to make it less sensitive
                        state = dragValue.translation.width * 0.5
                    }
                    .onChanged { dragValue in
                        // Calculate new value with damping
                        let dampedTranslation = dragValue.translation.width * 0.5
                        let newValue = value - (dampedTranslation / tickSpacing)
                        let clampedValue = max(50, min(249, round(newValue)))
                        
                        // Haptic feedback for each weight change
                        if Int(clampedValue) != Int(self.value) {
                            impactFeedback.impactOccurred()
                            self.value = clampedValue
                            lastHapticValue = Int(clampedValue)
                        }
                    }
                    .onEnded { dragValue in
                        // Calculate final value with damping
                        let dampedTranslation = dragValue.translation.width * 0.5
                        let newValue = value - (dampedTranslation / tickSpacing)
                        let finalValue = max(50, min(249, round(newValue)))
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.value = finalValue
                            // Update base offset to maintain position
                            baseOffset = 0
                        }
                    }
            )
        }
    }
}

struct TargetWeightView_Previews: PreviewProvider {
    static var previews: some View {
        TargetWeightView()
    }
}
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
    @State private var textInput: String = "130"
    @State private var selectedUnit = "lbs"
    
    var minWeight: Double {
        selectedUnit == "lbs" ? 50 : 23  // 50 lbs = ~23 kg
    }
    
    var maxWeight: Double {
        selectedUnit == "lbs" ? 400 : 180  // 400 lbs = ~180 kg
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 24, currentStep: 10)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            VStack(spacing: 8) {
                Text("What is your target weight?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Drag to select your goal weight")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            
            // Weight display with unit toggle
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Text("\(Int(targetWeight))")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Unit toggle button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedUnit == "lbs" {
                                selectedUnit = "kg"
                                // Convert current value to kg
                                targetWeight = round(targetWeight * 0.453592)
                                currentWeight = round(currentWeight * 0.453592)
                                textInput = String(Int(targetWeight))
                            } else {
                                selectedUnit = "lbs"
                                // Convert current value to lbs
                                targetWeight = round(targetWeight / 0.453592)
                                currentWeight = round(currentWeight / 0.453592)
                                textInput = String(Int(targetWeight))
                            }
                        }
                    } label: {
                        Text(selectedUnit)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 24)
                
                // Weight ruler slider
                WeightRulerSlider(
                    value: $targetWeight,
                    minValue: minWeight,
                    maxValue: maxWeight,
                    currentWeight: currentWeight,
                    unit: selectedUnit
                )
                .frame(height: 80)
                .padding(.horizontal, 20)
                .onChange(of: targetWeight) { oldValue, newValue in
                    textInput = String(Int(newValue))
                }
                
                // Text input field
                HStack {
                    TextField("Enter weight", text: $textInput)
                        .keyboardType(.numberPad)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .onChange(of: textInput) { oldValue, newValue in
                            if let weight = Double(newValue) {
                                targetWeight = max(minWeight, min(maxWeight, weight))
                            }
                        }
                    
                    Text(selectedUnit)
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
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
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Use coordinator's weight as current weight
            currentWeight = coordinator.weight * 2.20462 // Convert kg to lbs
            // Set initial target weight to current weight - 10 lbs for weight loss
            targetWeight = currentWeight - 10
            textInput = String(Int(targetWeight))
        }
    }
}

struct WeightRulerSlider: View {
    @Binding var value: Double
    let minValue: Double
    let maxValue: Double
    let currentWeight: Double
    let unit: String
    
    @State private var baseOffset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var lastHapticValue: Int = 0
    
    private var tickSpacing: CGFloat {
        unit == "lbs" ? 8 : 12  // Different spacing for kg vs lbs
    }
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
                    ForEach(Int(minValue)...Int(maxValue), id: \.self) { weight in
                        VStack(spacing: 4) {
                            // Labels for major ticks
                            let interval = unit == "lbs" ? 10 : 5
                            if weight % interval == 0 {
                                Text("\(weight)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(height: 16)
                            } else {
                                Color.clear
                                    .frame(height: 16)
                            }
                            
                            // Tick marks
                            let majorInterval = unit == "lbs" ? 10 : 5
                            let minorInterval = unit == "lbs" ? 5 : 1
                            Rectangle()
                                .fill(Color.white.opacity(weight % majorInterval == 0 ? 0.5 : (weight % minorInterval == 0 ? 0.3 : 0.2)))
                                .frame(width: 0.5, height: weight % majorInterval == 0 ? 20 : (weight % minorInterval == 0 ? 15 : 10))
                            
                            Spacer()
                        }
                        .frame(width: tickSpacing)
                    }
                }
                .offset(x: geometry.size.width / 2 - CGFloat(value - minValue) * tickSpacing + baseOffset + dragOffset)
                
                // Green overlay for selected range from current weight
                let referenceWeight = unit == "lbs" ? currentWeight : currentWeight * 0.453592  // Use actual current weight
                if value < referenceWeight {
                    Color.nutriSyncGreen.opacity(0.3)
                        .frame(width: CGFloat(referenceWeight - value) * tickSpacing)
                        .frame(height: 30)
                        .position(x: geometry.size.width / 2 - CGFloat(referenceWeight - value) * tickSpacing / 2, y: geometry.size.height / 2 + 10)
                        .allowsHitTesting(false)
                } else if value > referenceWeight {
                    Color.nutriSyncGreen.opacity(0.3)
                        .frame(width: CGFloat(value - referenceWeight) * tickSpacing)
                        .frame(height: 30)
                        .position(x: geometry.size.width / 2 + CGFloat(value - referenceWeight) * tickSpacing / 2, y: geometry.size.height / 2 + 10)
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
                        // Direct translation without damping for better responsiveness
                        state = dragValue.translation.width
                    }
                    .onChanged { dragValue in
                        // Calculate new value without damping
                        let newValue = value - (dragValue.translation.width / tickSpacing)
                        let clampedValue = max(minValue, min(maxValue, round(newValue)))
                        
                        // Haptic feedback for each weight change
                        if Int(clampedValue) != Int(self.value) {
                            impactFeedback.impactOccurred()
                            self.value = clampedValue
                            lastHapticValue = Int(clampedValue)
                        }
                    }
                    .onEnded { dragValue in
                        // Calculate final value - snap to whole numbers
                        let newValue = value - (dragValue.translation.width / tickSpacing)
                        let finalValue = max(minValue, min(maxValue, round(newValue)))
                        
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
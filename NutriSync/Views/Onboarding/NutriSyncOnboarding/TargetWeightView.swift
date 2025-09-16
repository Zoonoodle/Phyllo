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
            OnboardingSectionProgressBar()
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
                
                // Modern weight slider
                ModernWeightSlider(
                    selectedWeight: $targetWeight,
                    minimumWeight: minWeight,
                    maximumWeight: maxWeight,
                    referenceWeight: currentWeight,
                    weightUnit: selectedUnit
                )
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

struct ModernWeightSlider: View {
    @Binding var selectedWeight: Double
    let minimumWeight: Double
    let maximumWeight: Double
    let referenceWeight: Double
    let weightUnit: String
    
    @State private var isDragging = false
    @State private var sliderProgress: Double = 0.5
    @State private var pulseAnimation = false
    
    private let vibrationGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    var body: some View {
        VStack(spacing: 24) {
            // Visual weight difference indicator
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Current")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(Int(referenceWeight))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Animated arrow showing direction
                Image(systemName: selectedWeight < referenceWeight ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.nutriSyncGreen)
                    .rotationEffect(.degrees(pulseAnimation ? 5 : -5))
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                
                VStack(spacing: 4) {
                    Text("Target")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(Int(selectedWeight))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.nutriSyncGreen)
                }
            }
            .padding(.horizontal, 40)
            
            // New circular slider design
            ZStack {
                // Background track
                Capsule()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 60)
                
                // Progress fill
                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.nutriSyncGreen.opacity(0.3),
                                    Color.nutriSyncGreen.opacity(0.8)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * sliderProgress, height: 60)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: sliderProgress)
                    
                    // Draggable thumb with glow effect
                    Circle()
                        .fill(Color.nutriSyncGreen)
                        .frame(width: isDragging ? 70 : 50, height: isDragging ? 70 : 50)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color.nutriSyncGreen.opacity(isDragging ? 0.8 : 0.4), radius: isDragging ? 20 : 10)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .position(x: geo.size.width * sliderProgress, y: 30)
                        .gesture(
                            DragGesture()
                                .onChanged { drag in
                                    if !isDragging {
                                        isDragging = true
                                        selectionGenerator.selectionChanged()
                                    }
                                    
                                    let newProgress = min(max(0, drag.location.x / geo.size.width), 1)
                                    sliderProgress = newProgress
                                    
                                    let newWeight = minimumWeight + (maximumWeight - minimumWeight) * newProgress
                                    let roundedWeight = round(newWeight)
                                    
                                    if Int(roundedWeight) != Int(selectedWeight) {
                                        vibrationGenerator.impactOccurred()
                                        selectedWeight = roundedWeight
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                        isDragging = false
                                    }
                                    selectionGenerator.selectionChanged()
                                }
                        )
                }
                .frame(height: 60)
                
                // Weight labels at ends
                HStack {
                    Text("\(Int(minimumWeight))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Spacer()
                    
                    Text("\(Int(maximumWeight))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 12)
            }
            
            // Quick preset buttons
            HStack(spacing: 12) {
                ForEach(generatePresetWeights(), id: \.self) { presetWeight in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedWeight = presetWeight
                            sliderProgress = (presetWeight - minimumWeight) / (maximumWeight - minimumWeight)
                            selectionGenerator.selectionChanged()
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(Int(presetWeight))")
                                .font(.system(size: 14, weight: .semibold))
                            Text(weightUnit)
                                .font(.system(size: 10))
                                .opacity(0.6)
                        }
                        .foregroundColor(selectedWeight == presetWeight ? Color.nutriSyncBackground : .white)
                        .frame(width: 60, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedWeight == presetWeight ? Color.nutriSyncGreen : Color.white.opacity(0.1))
                        )
                    }
                }
            }
            .padding(.top, 8)
        }
        .onAppear {
            vibrationGenerator.prepare()
            selectionGenerator.prepare()
            sliderProgress = (selectedWeight - minimumWeight) / (maximumWeight - minimumWeight)
            pulseAnimation = true
        }
    }
    
    private func generatePresetWeights() -> [Double] {
        let difference = abs(referenceWeight - selectedWeight)
        if weightUnit == "lbs" {
            return [
                referenceWeight - 30,
                referenceWeight - 15,
                referenceWeight,
                referenceWeight + 15,
                referenceWeight + 30
            ].filter { $0 >= minimumWeight && $0 <= maximumWeight }
        } else {
            return [
                referenceWeight - 15,
                referenceWeight - 7,
                referenceWeight,
                referenceWeight + 7,
                referenceWeight + 15
            ].filter { $0 >= minimumWeight && $0 <= maximumWeight }
        }
    }
}

struct TargetWeightView_Previews: PreviewProvider {
    static var previews: some View {
        TargetWeightView()
    }
}
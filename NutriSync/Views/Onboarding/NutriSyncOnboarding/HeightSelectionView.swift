//
//  HeightSelectionView.swift
//  NutriSync
//
//  Height selection screen for onboarding
//

import SwiftUI

struct HeightSelectionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedUnit = "ft/in"
    @State private var heightFeet = 5
    @State private var heightInches = 10
    @State private var heightCm = 178
    @State private var isInitialized = false
    
    let feetRange = Array(3...8)
    let inchesRange = Array(0...11)
    let cmRange = Array(100...250)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("What is your height?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                
                // Unit Toggle
                HStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedUnit = "ft/in"
                    }
                } label: {
                    Text("Feet and Inches")
                        .font(.system(size: 16, weight: selectedUnit == "ft/in" ? .semibold : .regular))
                        .foregroundColor(selectedUnit == "ft/in" ? .nutriSyncBackground : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedUnit == "ft/in" ? Color.white : Color.clear)
                        .cornerRadius(8)
                }
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedUnit = "cm"
                    }
                } label: {
                    Text("Centimeters")
                        .font(.system(size: 16, weight: selectedUnit == "cm" ? .semibold : .regular))
                        .foregroundColor(selectedUnit == "cm" ? .nutriSyncBackground : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedUnit == "cm" ? Color.white : Color.clear)
                        .cornerRadius(8)
                }
                }
                .padding(3)
                .background(Color.white.opacity(0.1))
                .cornerRadius(11)
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
                
                // Height Picker
                if selectedUnit == "ft/in" {
                    HStack(spacing: 10) {
                        // Feet picker
                        Picker("Feet", selection: $heightFeet) {
                            ForEach(feetRange, id: \.self) { feet in
                                Text("\(feet) ft")
                                    .foregroundColor(.white)
                                    .tag(feet)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                        
                        // Inches picker
                        Picker("Inches", selection: $heightInches) {
                            ForEach(inchesRange, id: \.self) { inches in
                                Text("\(inches) in")
                                    .foregroundColor(.white)
                                    .tag(inches)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                    }
                    .frame(height: 180)
                    .onChange(of: heightFeet) { _ in saveDataToCoordinator() }
                    .onChange(of: heightInches) { _ in saveDataToCoordinator() }
                } else {
                    Picker("Height", selection: $heightCm) {
                        ForEach(cmRange, id: \.self) { cm in
                            Text("\(cm) cm")
                                .foregroundColor(.white)
                                .tag(cm)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 180)
                    .onChange(of: heightCm) { _ in saveDataToCoordinator() }
                }
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Load height from coordinator (stored in cm)
        if coordinator.height > 0 {
            heightCm = Int(coordinator.height)
            
            // Convert to feet and inches
            let totalInches = coordinator.height / 2.54
            heightFeet = Int(totalInches / 12)
            heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        }
    }
    
    private func saveDataToCoordinator() {
        if selectedUnit == "ft/in" {
            // Convert feet and inches to cm
            let totalInches = Double(heightFeet * 12 + heightInches)
            coordinator.height = totalInches * 2.54
        } else {
            // Direct cm value
            coordinator.height = Double(heightCm)
        }
    }
}

struct HeightSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            HeightSelectionView()
        }
    }
}
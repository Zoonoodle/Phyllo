//
//  WeightView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 2 - Dark Theme
//

import SwiftUI

struct WeightView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var weight: String = "165"
    @State private var selectedUnit = "lbs"
    let units = ["lbs", "kg"]
    
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
            Text("What is your weight?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Subtitle
            Text("It is best to measure your weight at the same time each day, ideally in the morning.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            
            // Current Weight section
            VStack(alignment: .leading, spacing: 12) {
                Text("Current Weight")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    // Weight input
                    TextField("", text: $weight)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    
                    // Unit picker
                    Menu {
                        ForEach(units, id: \.self) { unit in
                            Button(unit) {
                                selectedUnit = unit
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedUnit)
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding()
                        .frame(width: 100)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            
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
                }
                
                Spacer()
                
                Button {
                    // Save weight to coordinator
                    if let weightValue = Double(weight) {
                        // Convert to kg if needed (coordinator expects kg)
                        let weightInKg = selectedUnit == "lbs" ? weightValue * 0.453592 : weightValue
                        coordinator.weight = weightInKg
                    }
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
        .onTapGesture {
            hideKeyboard()
        }
    }
}

// Helper to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Content-only version for carousel
struct WeightContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var weight: String = "165"
    @State private var selectedUnit = "lbs"
    let units = ["lbs", "kg"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("What is your weight?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("It is best to measure your weight at the same time each day, ideally in the morning.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                
                // Current Weight section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Weight")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        // Weight input
                        TextField("", text: $weight)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        
                        // Unit picker
                        Menu {
                            ForEach(units, id: \.self) { unit in
                                Button(unit) {
                                    selectedUnit = unit
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedUnit)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .frame(width: 100)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onDisappear {
            // Save weight to coordinator when navigating away
            if let weightValue = Double(weight) {
                // Convert to kg if needed (coordinator expects kg)
                let weightInKg = selectedUnit == "lbs" ? weightValue * 0.453592 : weightValue
                coordinator.weight = weightInKg
            }
        }
    }
}

struct WeightView_Previews: PreviewProvider {
    static var previews: some View {
        WeightView()
    }
}
//
//  WeightView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 2 - Dark Theme
//

import SwiftUI

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
    @State private var isInitialized = false
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
        .onAppear {
            loadDataFromCoordinator()
        }
        .onChange(of: weight) { _ in saveDataToCoordinator() }
        .onChange(of: selectedUnit) { _ in saveDataToCoordinator() }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Load existing weight from coordinator if it exists
        if coordinator.weight > 0 {
            // Convert from kg to display unit
            let weightInLbs = coordinator.weight * 2.20462
            weight = String(Int(weightInLbs))
            selectedUnit = "lbs"
        }
    }
    
    private func saveDataToCoordinator() {
        if let weightValue = Double(weight) {
            // Convert to kg if needed (coordinator expects kg)
            let weightInKg = selectedUnit == "lbs" ? weightValue * 0.453592 : weightValue
            coordinator.weight = weightInKg
            print("[WeightView] Saved weight: \(weightInKg) kg (\(weightValue) \(selectedUnit))")
        }
    }
}

struct WeightView_Previews: PreviewProvider {
    static var previews: some View {
        WeightContentView()
    }
}
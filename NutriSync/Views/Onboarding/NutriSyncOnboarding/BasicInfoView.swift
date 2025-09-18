//
//  BasicInfoView.swift
//  NutriSync
//
//  Basic information (Height, Gender, Age) - Dark Theme
//

import SwiftUI

// Content-only version for carousel
struct BasicInfoContentView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    @State private var heightFeet: String = "5"
    @State private var heightInches: String = "10"
    @State private var heightCm: String = "178"
    @State private var heightUnit = "ft/in"
    @State private var selectedGender = "Male"
    @State private var birthDate = Date(timeIntervalSince1970: 788918400) // Jan 1, 1995
    @State private var isInitialized = false
    
    let heightUnits = ["ft/in", "cm"]
    let genders = ["Male", "Female", "Other"]
    
    // Calculate age from birthDate
    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("Basic Information")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Subtitle
                Text("We need some basic information to personalize your experience.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                
                VStack(spacing: 24) {
                    // Height section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Height")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            if heightUnit == "ft/in" {
                                // Feet input
                                TextField("", text: $heightFeet)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .frame(width: 80)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Text("ft")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                // Inches input
                                TextField("", text: $heightInches)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .frame(width: 80)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Text("in")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.6))
                            } else {
                                // Centimeters input
                                TextField("", text: $heightCm)
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            // Unit picker
                            Menu {
                                ForEach(heightUnits, id: \.self) { unit in
                                    Button(unit) {
                                        heightUnit = unit
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(heightUnit)
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
                    
                    // Gender section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gender")
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            ForEach(genders, id: \.self) { gender in
                                Button {
                                    selectedGender = gender
                                    coordinator.gender = selectedGender
                                } label: {
                                    Text(gender)
                                        .font(.system(size: 17))
                                        .foregroundColor(selectedGender == gender ? Color.nutriSyncBackground : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            selectedGender == gender ?
                                            Color.nutriSyncAccent :  // Lime green accent when selected
                                            Color.white.opacity(0.1)
                                        )
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Age section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Age")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(age) years old")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Date picker with custom styling
                        DatePicker("", selection: $birthDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .colorScheme(.dark)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .environment(\.colorScheme, .dark)
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
        .onChange(of: heightFeet) { _ in saveDataToCoordinator() }
        .onChange(of: heightInches) { _ in saveDataToCoordinator() }
        .onChange(of: heightCm) { _ in saveDataToCoordinator() }
        .onChange(of: heightUnit) { _ in saveDataToCoordinator() }
        .onChange(of: selectedGender) { _ in saveDataToCoordinator() }
        .onChange(of: birthDate) { _ in saveDataToCoordinator() }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Load existing values from coordinator if they exist
        if coordinator.height > 0 {
            let feet = Int(coordinator.height / 30.48)
            let inches = Int((coordinator.height.truncatingRemainder(dividingBy: 30.48)) / 2.54)
            heightFeet = String(feet)
            heightInches = String(inches)
            heightCm = String(Int(coordinator.height))
        }
        
        if !coordinator.gender.isEmpty {
            selectedGender = coordinator.gender
        }
        
        if coordinator.age > 0 {
            // Calculate birth date from age
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            let birthYear = currentYear - coordinator.age
            var components = DateComponents()
            components.year = birthYear
            components.month = 1
            components.day = 1
            if let date = calendar.date(from: components) {
                birthDate = date
            }
        }
    }
    
    private func saveDataToCoordinator() {
        // Convert height to cm and save
        if heightUnit == "ft/in" {
            let feet = Double(heightFeet) ?? 5
            let inches = Double(heightInches) ?? 10
            let totalInches = (feet * 12) + inches
            let cm = totalInches * 2.54
            coordinator.height = cm
        } else {
            let cm = Double(heightCm) ?? 178
            coordinator.height = cm
        }
        
        // Save gender
        coordinator.gender = selectedGender
        
        // Save age
        coordinator.age = age
        print("[BasicInfoView] Saving: Gender=\(selectedGender), Age=\(age)")
    }
}

struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoContentView()
    }
}
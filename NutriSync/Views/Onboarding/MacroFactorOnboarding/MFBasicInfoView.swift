//
//  MFBasicInfoView.swift
//  NutriSync
//
//  Basic information (Height, Gender, Age) - Dark Theme
//

import SwiftUI

struct MFBasicInfoView: View {
    @State private var heightFeet: String = "5"
    @State private var heightInches: String = "10"
    @State private var heightCm: String = "178"
    @State private var heightUnit = "ft/in"
    @State private var selectedGender = "Male"
    @State private var birthDate = Date(timeIntervalSince1970: 788918400) // Jan 1, 1995
    
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
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 2)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
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
                            } label: {
                                Text(gender)
                                    .font(.system(size: 17))
                                    .foregroundColor(selectedGender == gender ? Color.nutriSyncBackground : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        selectedGender == gender ?
                                        Color.white :
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
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    // Back action
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Button {
                    // Next action
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
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct MFBasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        MFBasicInfoView()
    }
}
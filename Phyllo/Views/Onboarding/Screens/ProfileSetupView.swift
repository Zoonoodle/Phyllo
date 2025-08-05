//
//  ProfileSetupView.swift
//  Phyllo
//
//  Basic profile setup for onboarding
//

import SwiftUI

struct ProfileSetupView: View {
    @Binding var data: OnboardingData
    @FocusState private var focusedField: ProfileField?
    
    enum ProfileField: Hashable {
        case name, email, age, height, weight, targetWeight
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tell us about yourself")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("This helps us personalize your nutrition plan")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 24) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("Your name", text: $data.name)
                            .textFieldStyle(OnboardingTextFieldStyle())
                            .focused($focusedField, equals: .name)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .email }
                    }
                    
                    // Email
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        TextField("your@email.com", text: $data.email)
                            .textFieldStyle(OnboardingTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .age }
                    }
                    
                    // Age & Gender Row
                    HStack(spacing: 16) {
                        // Age
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Age", value: $data.age, format: .number)
                                .textFieldStyle(OnboardingTextFieldStyle())
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .age)
                                .frame(width: 100)
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Menu {
                                ForEach(Gender.allCases, id: \.self) { gender in
                                    Button(gender.rawValue) {
                                        data.gender = gender
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(data.gender?.rawValue ?? "Select")
                                        .foregroundColor(data.gender != nil ? .white : .white.opacity(0.5))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Height & Weight Row
                    HStack(spacing: 16) {
                        // Height
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Height")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HeightPicker(height: $data.height)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Current Weight
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Weight")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                TextField("Weight", value: $data.currentWeight, format: .number.precision(.fractionLength(1)))
                                    .textFieldStyle(OnboardingTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .weight)
                                
                                Text("lbs")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.trailing, 8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Target Weight (if weight loss/gain goal)
                    if let goal = data.primaryGoal,
                       case .weightLoss = goal,
                       case .muscleGain = goal {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Weight")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack {
                                TextField("Target", value: $data.targetWeight, format: .number.precision(.fractionLength(1)))
                                    .textFieldStyle(OnboardingTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .targetWeight)
                                
                                Text("lbs")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                    
                    // BMI Display (if we have height and weight)
                    if let bmi = data.bmi {
                        BMIDisplay(bmi: bmi)
                    }
                }
                .padding(.horizontal)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture {
            focusedField = nil
        }
    }
}

// MARK: - Height Picker

struct HeightPicker: View {
    @Binding var height: Double?
    @State private var feet: Int = 5
    @State private var inches: Int = 8
    
    var body: some View {
        HStack(spacing: 8) {
            // Feet
            Menu {
                ForEach(3...7, id: \.self) { ft in
                    Button("\(ft) ft") {
                        feet = ft
                        updateHeight()
                    }
                }
            } label: {
                HStack {
                    Text("\(feet) ft")
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            
            // Inches
            Menu {
                ForEach(0...11, id: \.self) { inch in
                    Button("\(inch) in") {
                        inches = inch
                        updateHeight()
                    }
                }
            } label: {
                HStack {
                    Text("\(inches) in")
                        .foregroundColor(.white)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
        .onAppear {
            if let height = height {
                feet = Int(height) / 12
                inches = Int(height) % 12
            }
        }
    }
    
    private func updateHeight() {
        height = Double(feet * 12 + inches)
    }
}

// MARK: - BMI Display

struct BMIDisplay: View {
    let bmi: Double
    
    var category: (String, Color) {
        switch bmi {
        case ..<18.5:
            return ("Underweight", .blue)
        case 18.5..<25:
            return ("Normal", .green)
        case 25..<30:
            return ("Overweight", .orange)
        default:
            return ("Obese", .red)
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            Text("BMI: \(bmi, specifier: "%.1f")")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text("(\(category.0))")
                .font(.system(size: 14))
                .foregroundColor(category.1)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

// MARK: - Text Field Style

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 17))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var data = OnboardingData()
        
        var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                ProfileSetupView(data: $data)
            }
            .onAppear {
                data.primaryGoal = .weightLoss(targetPounds: 10, timeline: 12)
            }
        }
    }
    
    return PreviewWrapper()
}
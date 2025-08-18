//
//  HeightPickerView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI

struct HeightPickerView: View {
    @Binding var currentPage: Int
    @State private var isMetric = false
    @State private var selectedFeet = 5 // Default 5 feet
    @State private var selectedInches = 6 // Default 6 inches
    @State private var selectedCentimeters = 168 // Default 168 cm (about 5'6")
    
    private let feet = Array(3...7)
    private let inches = Array(0...11)
    private let centimeters = Array(100...250)
    
    private let pickerHeight: CGFloat = 200
    private let itemHeight: CGFloat = 50
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<10) { index in
                        Capsule()
                            .fill(index <= 4 ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Title
                VStack(spacing: 12) {
                    Text("What is your height?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your height will be used to inform some of your dietary targets.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Unit toggle
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isMetric = false
                        }
                    }) {
                        Text("Feet and Inches")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isMetric ? .white.opacity(0.6) : .white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if !isMetric {
                                        Color.white.opacity(0.1)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.white)
                                                    .frame(height: 3)
                                                    .offset(y: 20),
                                                alignment: .bottom
                                            )
                                    }
                                }
                            )
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isMetric = true
                        }
                    }) {
                        Text("Centimeters")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isMetric ? .white : .white.opacity(0.6))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if isMetric {
                                        Color.white.opacity(0.1)
                                            .overlay(
                                                Rectangle()
                                                    .fill(Color.white)
                                                    .frame(height: 3)
                                                    .offset(y: 20),
                                                alignment: .bottom
                                            )
                                    }
                                }
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                Spacer()
                
                // Height pickers
                if isMetric {
                    // Centimeter picker
                    VStack(spacing: 8) {
                        VerticalWheelPicker(
                            items: centimeters.map { "\($0) cm" },
                            selectedIndex: Binding(
                                get: { selectedCentimeters - 100 },
                                set: { selectedCentimeters = $0 + 100 }
                            ),
                            itemHeight: itemHeight,
                            pickerHeight: pickerHeight
                        )
                        .frame(width: 200)
                    }
                } else {
                    // Feet and inches pickers
                    HStack(spacing: 40) {
                        // Feet picker
                        VStack(spacing: 8) {
                            VerticalWheelPicker(
                                items: feet.map { "\($0) ft" },
                                selectedIndex: Binding(
                                    get: { selectedFeet - 3 },
                                    set: { selectedFeet = $0 + 3 }
                                ),
                                itemHeight: itemHeight,
                                pickerHeight: pickerHeight
                            )
                            .frame(width: 100)
                        }
                        
                        // Inches picker
                        VStack(spacing: 8) {
                            VerticalWheelPicker(
                                items: inches.map { "\($0) in" },
                                selectedIndex: $selectedInches,
                                itemHeight: itemHeight,
                                pickerHeight: pickerHeight
                            )
                            .frame(width: 100)
                        }
                    }
                }
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Save height
                        if isMetric {
                            UserDefaults.standard.set(selectedCentimeters, forKey: "userHeightCm")
                        } else {
                            let totalInches = selectedFeet * 12 + selectedInches
                            let cm = Int(Double(totalInches) * 2.54)
                            UserDefaults.standard.set(cm, forKey: "userHeightCm")
                        }
                        
                        withAnimation(.spring(response: 0.3)) {
                            currentPage += 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(30)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Convert saved cm to feet/inches for initial display
            if let savedCm = UserDefaults.standard.object(forKey: "userHeightCm") as? Int {
                selectedCentimeters = savedCm
                let totalInches = Int(Double(savedCm) / 2.54)
                selectedFeet = totalInches / 12
                selectedInches = totalInches % 12
            }
        }
    }
}

#Preview {
    HeightPickerView(currentPage: .constant(5))
}
//
//  MFTargetWeightView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 10
//

import SwiftUI

struct MFTargetWeightView: View {
    @State private var targetWeight: String = "164"
    @State private var currentWeight: String = "163"
    @State private var selectedUnit = "lbs"
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 9)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            
            // Title
            Text("What weight would you like to get to?")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            
            // Weight inputs
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(currentWeight) \(selectedUnit)")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
                
                VStack(spacing: 16) {
                    TextField("", text: $targetWeight)
                        .font(.system(size: 32, weight: .medium))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                    
                    Text(selectedUnit)
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                
                // Unit picker button
                Button {
                    // Toggle unit
                    selectedUnit = selectedUnit == "lbs" ? "kg" : "lbs"
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    // Back action
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(Circle())
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
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.black)
                    .cornerRadius(22)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.white)
        .onTapGesture {
            hideKeyboard()
        }
    }
}

struct MFTargetWeightView_Previews: PreviewProvider {
    static var previews: some View {
        MFTargetWeightView()
    }
}
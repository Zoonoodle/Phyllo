//
//  BodyMetricsView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct BodyMetricsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var useImperial = true
    @State private var heightFeet = 5
    @State private var heightInches = 7
    @State private var weightLbs = 165
    
    var body: some View {
        OnboardingScreenBase(
            viewModel: viewModel,
            showBack: true,
            nextTitle: "Next"
        ) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Your measurements")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("We'll use this to calculate your nutrition needs")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        .padding(.horizontal, 24)
                        
                        // Unit toggle
                        Picker("Units", selection: $useImperial) {
                            Text("Imperial").tag(true)
                            Text("Metric").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 80)
                        .colorScheme(.dark)
                        
                        VStack(spacing: 24) {
                            // Height
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What's your height?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if useImperial {
                                    HStack(spacing: 12) {
                                        MetricInputField(
                                            value: $heightFeet,
                                            label: "ft",
                                            range: 3...8
                                        )
                                        
                                        MetricInputField(
                                            value: $heightInches,
                                            label: "in",
                                            range: 0...11
                                        )
                                    }
                                } else {
                                    MetricInputField(
                                        value: Binding(
                                            get: { Int(viewModel.userData.height) },
                                            set: { viewModel.userData.height = Double($0) }
                                        ),
                                        label: "cm",
                                        range: 100...250
                                    )
                                }
                            }
                            
                            // Weight
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What's your current weight?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                if useImperial {
                                    MetricInputField(
                                        value: $weightLbs,
                                        label: "lbs",
                                        range: 50...500
                                    )
                                } else {
                                    MetricInputField(
                                        value: Binding(
                                            get: { Int(viewModel.userData.weight) },
                                            set: { viewModel.userData.weight = Double($0) }
                                        ),
                                        label: "kg",
                                        range: 30...300
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Helpful tip
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.footnote)
                                .foregroundColor(Color(hex: "00D26A"))
                            
                            Text("It's best to measure your weight at the same time each day, ideally in the morning")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .onChange(of: useImperial) { _ in
                convertUnits()
            }
            .onDisappear {
                saveMetrics()
            }
        }
    }
    
    private func convertUnits() {
        if useImperial {
            // Convert from metric to imperial
            let totalInches = viewModel.userData.height / 2.54
            heightFeet = Int(totalInches / 12)
            heightInches = Int(totalInches.truncatingRemainder(dividingBy: 12))
            weightLbs = Int(viewModel.userData.weight * 2.205)
        } else {
            // Convert from imperial to metric
            let totalInches = Double(heightFeet * 12 + heightInches)
            viewModel.userData.height = totalInches * 2.54
            viewModel.userData.weight = Double(weightLbs) / 2.205
        }
    }
    
    private func saveMetrics() {
        if useImperial {
            let totalInches = Double(heightFeet * 12 + heightInches)
            viewModel.userData.height = totalInches * 2.54
            viewModel.userData.weight = Double(weightLbs) / 2.205
        }
    }
}

struct MetricInputField: View {
    @Binding var value: Int
    let label: String
    let range: ClosedRange<Int>
    
    var body: some View {
        HStack {
            TextField("", value: $value, format: .number)
                .keyboardType(.numberPad)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .onChange(of: value) { newValue in
                    if newValue < range.lowerBound {
                        value = range.lowerBound
                    } else if newValue > range.upperBound {
                        value = range.upperBound
                    }
                }
            
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 40, alignment: .leading)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct BodyMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        BodyMetricsView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
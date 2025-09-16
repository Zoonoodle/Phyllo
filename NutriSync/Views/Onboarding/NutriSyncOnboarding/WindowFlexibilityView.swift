//
//  WindowFlexibilityView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen - Window Flexibility
//

import SwiftUI

struct WindowFlexibilityView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var flexibilityLevel = ""
    @State private var autoAdjustWindows = true
    @State private var weekendDifferent = false
    
    let flexibilityOptions = ["Strict timing", "Moderate flex", "Very flexible"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            OnboardingSectionProgressBar()
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Schedule Flexibility")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("How adaptive should your eating windows be?")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    // Flexibility level
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Window Flexibility")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 12) {
                            ForEach(flexibilityOptions, id: \.self) { option in
                                FlexibilityOptionButton(
                                    title: option,
                                    description: getFlexibilityDescription(for: option),
                                    isSelected: flexibilityLevel == option,
                                    action: {
                                        flexibilityLevel = option
                                    }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Auto-adjustment toggle
                    VStack(spacing: 16) {
                        ToggleRow(
                            title: "Auto-adjust for missed windows",
                            subtitle: "Automatically redistribute nutrients when you miss a meal window",
                            isOn: $autoAdjustWindows
                        )
                        
                        ToggleRow(
                            title: "Different schedule on weekends",
                            subtitle: "Allow different eating patterns on Saturday and Sunday",
                            isOn: $weekendDifferent
                        )
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
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Button {
                    // Save data to coordinator before proceeding
                    coordinator.flexibilityLevel = flexibilityLevel
                    coordinator.autoAdjustWindows = autoAdjustWindows
                    coordinator.weekendDifferent = weekendDifferent
                    
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Next")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(!flexibilityLevel.isEmpty ? Color.nutriSyncBackground : .white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(!flexibilityLevel.isEmpty ? Color.white : Color.white.opacity(0.1))
                    .cornerRadius(22)
                }
                .disabled(flexibilityLevel.isEmpty)
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
            // Initialize state from coordinator
            flexibilityLevel = coordinator.flexibilityLevel
            autoAdjustWindows = coordinator.autoAdjustWindows
            weekendDifferent = coordinator.weekendDifferent
        }
    }
    
    private func getFlexibilityDescription(for option: String) -> String {
        switch option {
        case "Strict timing":
            return "Windows stay fixed, best for routine"
        case "Moderate flex":
            return "±30 min adjustments allowed"
        case "Very flexible":
            return "Windows adapt to your day"
        default:
            return ""
        }
    }
}

struct FlexibilityOptionButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.1 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(isSelected ? 0.3 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .white))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct WindowFlexibilityView_Previews: PreviewProvider {
    static var previews: some View {
        WindowFlexibilityView()
    }
}
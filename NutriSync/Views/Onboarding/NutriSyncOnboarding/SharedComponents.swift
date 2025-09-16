//
//  SharedComponents.swift
//  NutriSync
//
//  Shared components for NutriSync onboarding screens - Dark Theme
//

import SwiftUI

// MARK: - Progress Bar (Legacy - for backward compatibility)
struct ProgressBar: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: geometry.size.width * (CGFloat(currentStep) / CGFloat(totalSteps)), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Section-based Segmented Progress Bar
struct OnboardingSectionProgressBar: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var viewModel
    
    var body: some View {
        let totalSteps = viewModel.currentSectionScreens.count
        let currentStep = viewModel.currentScreenIndex + 1
        
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < currentStep ? Color.white : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
            }
        }
    }
}

struct ProgressIcon: View {
    let icon: String
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isActive ? Color.white : Color.white.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isActive ? Color.nutriSyncBackground : .white.opacity(0.5))
        }
    }
}

struct ProgressLine: View {
    let isActive: Bool
    
    var body: some View {
        Rectangle()
            .fill(isActive ? Color.white : Color.white.opacity(0.2))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Navigation Header
struct NavigationHeader: View {
    let currentStep: Int
    let totalSteps: Int
    let onBack: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Step indicator
            HStack(spacing: 4) {
                ForEach(1...totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button {
            if isEnabled {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isEnabled ? Color.nutriSyncBackground : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ? Color.white : Color.white.opacity(0.1))
                .cornerRadius(28)
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Option Button (for selection screens)
struct OnboardingOptionButton: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, subtitle: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 16, height: 16)
                    }
                }
            }
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

// MARK: - Multi Select Button (for multiple selection screens)
struct MultiSelectButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
            }
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

// Note: SectionProgressHeader is in its own file
// Note: OnboardingBottomNav is in its own file
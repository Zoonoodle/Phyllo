//
//  MFSharedComponents.swift
//  NutriSync
//
//  Shared components for MacroFactor onboarding screens - Dark Theme
//

import SwiftUI

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
struct MFNavigationHeader: View {
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
struct MFPrimaryButton: View {
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.nutriSyncBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(isEnabled ? 0.2 : 0.1), lineWidth: 1)
                )
                .cornerRadius(16)
        }
        .opacity(isEnabled ? 1 : 0.6)
        .disabled(!isEnabled)
    }
}
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
                .foregroundColor(isActive ? Color(hex: "0A0A0A") : .white.opacity(0.5))
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
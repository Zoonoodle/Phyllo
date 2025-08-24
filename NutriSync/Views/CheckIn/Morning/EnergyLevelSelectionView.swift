//
//  EnergyLevelSelectionView.swift
//  NutriSync
//
//  Energy level selection for morning check-in
//

import SwiftUI

struct EnergyLevelSelectionView: View {
    @Binding var energyLevel: Int
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How's your energy?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This helps us optimize your meal timing")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Energy level options
            VStack(spacing: 16) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            energyLevel = level
                        }
                    } label: {
                        HStack {
                            Image(systemName: energyIcon(for: level))
                                .font(.system(size: 24))
                                .foregroundColor(energyLevel == level ? .white : .white.opacity(0.5))
                                .frame(width: 30)
                            
                            Text(energyLabel(for: level))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(energyLevel == level ? .white : .white.opacity(0.7))
                            
                            Spacer()
                            
                            if energyLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.nutriSyncAccent)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(energyLevel == level ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            energyLevel == level ? Color.nutriSyncAccent : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        )
                    }
                }
            }
            
            Spacer()
            
            // Continue button
            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
    
    private func energyIcon(for level: Int) -> String {
        switch level {
        case 1: return "battery.0"
        case 2: return "battery.25"
        case 3: return "battery.50"
        case 4: return "battery.75"
        case 5: return "battery.100"
        default: return "battery.50"
        }
    }
    
    private func energyLabel(for level: Int) -> String {
        switch level {
        case 1: return "Exhausted"
        case 2: return "Low"
        case 3: return "Moderate"
        case 4: return "Good"
        case 5: return "Excellent"
        default: return "Moderate"
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        EnergyLevelSelectionView(energyLevel: .constant(3)) {
            print("Continue")
        }
    }
    .preferredColorScheme(.dark)
}
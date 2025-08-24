//
//  HungerLevelSelectionView.swift
//  NutriSync
//
//  Hunger level selection for morning check-in
//

import SwiftUI

struct HungerLevelSelectionView: View {
    @Binding var hungerLevel: Int
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How hungry are you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("We'll adjust your first meal window accordingly")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Hunger level options
            VStack(spacing: 16) {
                ForEach(1...5, id: \.self) { level in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            hungerLevel = level
                        }
                    } label: {
                        HStack {
                            Text(hungerEmoji(for: level))
                                .font(.system(size: 28))
                                .frame(width: 35)
                            
                            Text(hungerLabel(for: level))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(hungerLevel == level ? .white : .white.opacity(0.7))
                            
                            Spacer()
                            
                            if hungerLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.nutriSyncAccent)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(hungerLevel == level ? Color.white.opacity(0.1) : Color.white.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            hungerLevel == level ? Color.nutriSyncAccent : Color.clear,
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
    
    private func hungerEmoji(for level: Int) -> String {
        switch level {
        case 1: return "😌"
        case 2: return "🙂"
        case 3: return "😐"
        case 4: return "😋"
        case 5: return "🤤"
        default: return "😐"
        }
    }
    
    private func hungerLabel(for level: Int) -> String {
        switch level {
        case 1: return "Not hungry at all"
        case 2: return "Slightly hungry"
        case 3: return "Moderately hungry"
        case 4: return "Very hungry"
        case 5: return "Starving"
        default: return "Moderately hungry"
        }
    }
}

#Preview {
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        HungerLevelSelectionView(hungerLevel: .constant(3)) {
            print("Continue")
        }
    }
    .preferredColorScheme(.dark)
}
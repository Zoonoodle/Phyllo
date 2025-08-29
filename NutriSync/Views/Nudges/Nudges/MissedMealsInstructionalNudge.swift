//
//  MissedMealsInstructionalNudge.swift
//  NutriSync
//
//  Created on 8/21/25.
//

import SwiftUI

struct MissedMealsInstructionalNudge: View {
    let onDismiss: () -> Void
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Card
            VStack(spacing: 20) {
                // Header
                Text("Describe all the meals you had today")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    instructionItem(
                        icon: "tag.fill",
                        text: "Include restaurant names",
                        subtitle: "For accurate nutrition data"
                    )
                    
                    instructionItem(
                        icon: "clock.fill",
                        text: "Timing comes next",
                        subtitle: "We'll ask when you ate each meal"
                    )
                    
                    instructionItem(
                        icon: "list.bullet",
                        text: "Describe everything",
                        subtitle: "Drinks, sides, desserts"
                    )
                }
                
                // Example text
                VStack(spacing: 8) {
                    Text("Example:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\"I had scrambled eggs and toast for breakfast, a Chipotle chicken bowl for lunch, and grilled salmon with rice for dinner\"")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .italic()
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
                
                // Action button
                Button(action: onDismiss) {
                    Text("Got it!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "1a1a1a"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 20)
            .scaleEffect(animateIn ? 1 : 0.9)
            .opacity(animateIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
    
    private func instructionItem(icon: String, text: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        MissedMealsInstructionalNudge {
            print("Dismissed")
        }
    }
}
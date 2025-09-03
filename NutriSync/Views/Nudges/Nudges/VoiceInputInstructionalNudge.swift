//
//  VoiceInputInstructionalNudge.swift
//  NutriSync
//
//  Created on 8/21/25.
//

import SwiftUI

struct VoiceInputInstructionalNudge: View {
    let onDismiss: () -> Void
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Card
            VStack(spacing: 20) {
                // Header
                Text("For the most accurate nutrition data:")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Tips with examples
                VStack(alignment: .leading, spacing: 16) {
                    instructionItem(
                        icon: "tag.fill",
                        text: "Mention brand names",
                        example: "\"Starbucks venti iced coffee\""
                    )
                    
                    instructionItem(
                        icon: "scalemass.fill",
                        text: "Include portion sizes",
                        example: "\"Large bowl of pasta\" or \"8 oz steak\""
                    )
                    
                    instructionItem(
                        icon: "list.bullet",
                        text: "List all ingredients you know",
                        example: "\"Salad with chicken, avocado, and ranch\""
                    )
                }
                
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
    
    private func instructionItem(icon: String, text: String, example: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(example)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VoiceInputInstructionalNudge {
        }
    }
}
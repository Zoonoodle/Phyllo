//
//  VoiceInputTipsNudge.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI

struct VoiceInputTipsNudge: View {
    let onDismiss: () -> Void
    @State private var animateIn = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Content Card
            VStack(spacing: 20) {
                // Header with icon
                HStack {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                        .symbolEffect(.pulse, value: animateIn)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Tip: Voice Description")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Get more accurate nutrition data")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                
                // Quick tips
                VStack(alignment: .leading, spacing: 16) {
                    tipRow(icon: "tag.fill", 
                           title: "Mention brands",
                           subtitle: "\"Chipotle burrito bowl\"")
                    
                    tipRow(icon: "scalemass.fill", 
                           title: "Include portions",
                           subtitle: "\"Large coffee\" or \"8 oz steak\"")
                    
                    tipRow(icon: "sparkles",
                           title: "AI will search",
                           subtitle: "Automatically finds official nutrition")
                }
                
                // Action buttons
                HStack(spacing: 12) {
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
    
    private func tipRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            }
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VoiceInputTipsNudge {
        }
    }
}
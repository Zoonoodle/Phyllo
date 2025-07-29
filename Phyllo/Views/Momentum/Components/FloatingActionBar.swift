//
//  FloatingActionBar.swift
//  Phyllo
//
//  Created on 7/27/25.
//

import SwiftUI

struct FloatingActionBar: View {
    @State private var isExpanded = false
    @State private var showActions = false
    
    var body: some View {
        HStack(spacing: 16) {
            if isExpanded {
                // Action Buttons
                HStack(spacing: 12) {
                    ActionButton(
                        icon: "camera.fill",
                        label: "Log Meal",
                        color: .phylloAccent
                    ) {
                        // Navigate to scan tab
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    ActionButton(
                        icon: "trophy.fill",
                        label: "Challenge",
                        color: .orange
                    ) {
                        // Open challenge modal
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    
                    ActionButton(
                        icon: "square.and.arrow.up",
                        label: "Share",
                        color: .blue
                    ) {
                        // Share progress
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                .opacity(showActions ? 1 : 0)
                .animation(.spring(response: 0.3).delay(isExpanded ? 0.1 : 0), value: showActions)
            }
            
            // Main Action Button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                    if isExpanded {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showActions = true
                        }
                    } else {
                        showActions = false
                    }
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(Color.phylloAccent)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .shadow(color: .phylloAccent.opacity(0.3), radius: 10, y: 5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .scaleEffect(isExpanded ? 1 : 0.95)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.phylloTextSecondary)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        VStack {
            Spacer()
            FloatingActionBar()
                .padding()
        }
    }
    .preferredColorScheme(.dark)
}
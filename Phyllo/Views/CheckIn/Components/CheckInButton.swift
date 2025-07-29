//
//  CheckInButton.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct CheckInButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case skip
        case minimal  // New minimal style
    }
    
    init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary: return Color.phylloAccent
        case .secondary: return Color.white.opacity(0.1)
        case .skip: return Color.clear
        case .minimal: return Color.white
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary: return Color.black
        case .secondary: return Color.white
        case .skip: return Color.white.opacity(0.5)
        case .minimal: return Color.black
        }
    }
    
    var body: some View {
        if style == .minimal {
            // Minimal circular button with arrow
            Button(action: {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                action()
            }) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(foregroundColor)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            // Original button styles
            Button(action: {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.prepare()
                impact.impactOccurred()
                action()
            }) {
                Text(title)
                    .font(.system(size: 16, weight: style == .skip ? .regular : .semibold))
                    .foregroundColor(foregroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: style == .skip ? 44 : 52)
                    .background(backgroundColor)
                    .cornerRadius(style == .skip ? 0 : 26)
                    .overlay(
                        RoundedRectangle(cornerRadius: style == .skip ? 0 : 26)
                            .stroke(style == .skip ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

// Custom button style for scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
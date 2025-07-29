//
//  InlineNudgeCard.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct InlineNudgeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    let onDismiss: (() -> Void)?
    var style: InlineStyle = .standard
    var showDismiss: Bool = true
    
    @State private var isVisible = true
    @State private var animateIn = false
    
    enum InlineStyle {
        case standard
        case compact
        case prominent
    }
    
    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                switch style {
                case .standard:
                    standardView
                case .compact:
                    compactView
                case .prominent:
                    prominentView
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
            .scaleEffect(animateIn ? 1 : 0.95)
            .opacity(animateIn ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animateIn = true
                }
            }
        }
    }
    
    private var standardView: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(iconColor)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                
                if let actionTitle = actionTitle, let action = onAction {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.phylloAccent)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
            
            if showDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 24, height: 24)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.phylloBorder, lineWidth: 1)
                )
        )
    }
    
    private var compactView: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = onAction {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.phylloAccent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(iconColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(iconColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var prominentView: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(iconColor)
            
            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = onAction {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.phylloBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.phylloAccent)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.03)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    iconColor.opacity(0.3),
                                    iconColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3)) {
            isVisible = false
        }
        onDismiss?()
    }
}

// Preview
struct InlineNudgeCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    InlineNudgeCard(
                        icon: "lightbulb.fill",
                        iconColor: .yellow,
                        title: "Did you know?",
                        subtitle: "Logging meals within 30 minutes improves tracking accuracy by 40%",
                        actionTitle: "Learn More",
                        onAction: { print("Learn more") },
                        onDismiss: { print("Dismissed") },
                        style: .standard
                    )
                    
                    InlineNudgeCard(
                        icon: "info.circle.fill",
                        iconColor: .blue,
                        title: "New feature: Voice logging",
                        subtitle: "",
                        actionTitle: "Try it",
                        onAction: { print("Try voice") },
                        onDismiss: { print("Dismissed") },
                        style: .compact
                    )
                    
                    InlineNudgeCard(
                        icon: "trophy.fill",
                        iconColor: .phylloAccent,
                        title: "You're on a Roll!",
                        subtitle: "3-day streak of logging all meals. Keep it up to unlock premium insights.",
                        actionTitle: "View Progress",
                        onAction: { print("View progress") },
                        onDismiss: nil,
                        style: .prominent,
                        showDismiss: false
                    )
                }
                .padding()
            }
        }
    }
}
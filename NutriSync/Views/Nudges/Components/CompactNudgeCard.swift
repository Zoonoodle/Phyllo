//
//  CompactNudgeCard.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct CompactNudgeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let actionTitle: String?
    let onAction: () -> Void
    let onDismiss: () -> Void
    var position: CompactNudgePosition = .bottom
    
    @State private var animateIn = false
    @State private var isDismissing = false
    
    enum CompactNudgePosition {
        case top
        case bottom
        case center
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                if position == .bottom {
                    Spacer()
                } else if position == .center {
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // Action button (optional)
                    if let actionTitle = actionTitle {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                onAction()
                            }
                        }) {
                            Text(actionTitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.nutriSyncAccent)
                        }
                    }
                    
                    // Dismiss button
                    Button(action: dismissCard) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 24, height: 24)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 20)
                .offset(y: animateIn ? 0 : (position == .top ? -200 : 200))
                .scaleEffect(isDismissing ? 0.9 : 1)
                .opacity(isDismissing ? 0 : 1)
                
                if position == .center {
                    Spacer()
                } else if position == .top {
                    Spacer()
                }
            }
            .frame(width: geometry.size.width)
            .padding(.vertical, position == .top ? 60 : 40)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateIn = true
            }
        }
    }
    
    private func dismissCard() {
        withAnimation(.spring(response: 0.3)) {
            isDismissing = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// Preview
struct CompactNudgeCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground.ignoresSafeArea()
            
            VStack {
                CompactNudgeCard(
                    icon: "lightbulb.fill",
                    iconColor: .yellow,
                    title: "Pro Tip",
                    subtitle: "Log your meals right after eating for the most accurate tracking",
                    actionTitle: "Got it",
                    onAction: { },
                    onDismiss: { },
                    position: .top
                )
                
                CompactNudgeCard(
                    icon: "bell.fill",
                    iconColor: .nutriSyncAccent,
                    title: "Window Starting Soon",
                    subtitle: "Your lunch window starts in 15 minutes",
                    actionTitle: "View",
                    onAction: { },
                    onDismiss: { },
                    position: .bottom
                )
            }
        }
    }
}
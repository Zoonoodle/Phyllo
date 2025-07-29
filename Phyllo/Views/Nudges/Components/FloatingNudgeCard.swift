//
//  FloatingNudgeCard.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct FloatingNudgeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let primaryAction: (title: String, action: () -> Void)?
    let secondaryAction: (title: String, action: () -> Void)?
    let onDismiss: () -> Void
    var position: FloatingPosition = .bottomRight
    var style: FloatingStyle = .standard
    
    @State private var animateIn = false
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var isExpanded = false
    
    enum FloatingPosition {
        case topLeft, topRight, bottomLeft, bottomRight
        
        var alignment: Alignment {
            switch self {
            case .topLeft: return .topLeading
            case .topRight: return .topTrailing
            case .bottomLeft: return .bottomLeading
            case .bottomRight: return .bottomTrailing
            }
        }
    }
    
    enum FloatingStyle {
        case standard
        case minimal
        case expanded
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: position.alignment) {
                // Card content
                VStack(spacing: 0) {
                    if style == .minimal && !isExpanded {
                        // Minimal circular button
                        minimalView
                    } else {
                        // Full card
                        fullCardView
                    }
                }
                .frame(maxWidth: style == .expanded ? nil : 320)
                .background(
                    RoundedRectangle(cornerRadius: isExpanded || style != .minimal ? 20 : 30)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: isExpanded || style != .minimal ? 20 : 30)
                                .strokeBorder(Color.phylloBorder, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .offset(x: dragOffset.width, y: dragOffset.height)
                .scaleEffect(isDragging ? 0.95 : (animateIn ? 1 : 0.8))
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animateIn)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            isDragging = true
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            // Snap to dismiss if dragged far enough
                            if abs(value.translation.width) > 100 || abs(value.translation.height) > 100 {
                                withAnimation(.spring(response: 0.3)) {
                                    dragOffset = CGSize(
                                        width: value.translation.width * 3,
                                        height: value.translation.height * 3
                                    )
                                    animateIn = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onDismiss()
                                }
                            } else {
                                // Snap back
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
                .padding(20)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateIn = true
            }
        }
    }
    
    private var minimalView: some View {
        Button(action: {
            withAnimation {
                isExpanded.toggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
            }
        }
    }
    
    private var fullCardView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    if style == .minimal && isExpanded {
                        withAnimation {
                            isExpanded = false
                        }
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            animateIn = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }
                }) {
                    Image(systemName: style == .minimal && isExpanded ? "chevron.down" : "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Action buttons
            if primaryAction != nil || secondaryAction != nil {
                HStack(spacing: 12) {
                    if let secondary = secondaryAction {
                        Button(action: secondary.action) {
                            Text(secondary.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(18)
                        }
                    }
                    
                    if let primary = primaryAction {
                        Button(action: primary.action) {
                            Text(primary.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.phylloBackground)
                                .frame(maxWidth: .infinity)
                                .frame(height: 36)
                                .background(Color.phylloAccent)
                                .cornerRadius(18)
                        }
                    }
                }
            }
        }
        .padding(20)
    }
}

// Preview
struct FloatingNudgeCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            // Standard floating card
            FloatingNudgeCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .green,
                title: "Great Progress!",
                subtitle: "You've logged 3 meals today",
                primaryAction: ("View Stats", { print("View stats") }),
                secondaryAction: nil,
                onDismiss: { print("Dismissed") },
                position: .bottomRight,
                style: .standard
            )
            
            // Minimal floating card
            FloatingNudgeCard(
                icon: "bell.badge.fill",
                iconColor: .orange,
                title: "Window Alert",
                subtitle: "Your dinner window is starting now",
                primaryAction: ("Log Meal", { print("Log meal") }),
                secondaryAction: ("Snooze", { print("Snooze") }),
                onDismiss: { print("Dismissed") },
                position: .topRight,
                style: .minimal
            )
        }
    }
}
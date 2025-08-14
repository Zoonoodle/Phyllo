//
//  ToastNudge.swift
//  NutriSync
//
//  Created on 7/29/25.
//

import SwiftUI

struct ToastNudge: View {
    let message: String
    let type: ToastType
    let duration: Double
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    @State private var progress: CGFloat = 0
    
    enum ToastType {
        case success
        case warning
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.color)
                
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Progress bar
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(type.color.opacity(0.1))
                            .frame(width: geometry.size.width * progress)
                            .animation(.linear(duration: duration), value: progress)
                    }
                }
            )
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            .offset(y: animateIn ? 0 : -100)
            .scaleEffect(animateIn ? 1 : 0.8)
            .opacity(animateIn ? 1 : 0)
            
            Spacer()
        }
        .padding(.top, 60)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateIn = true
            }
            
            // Start progress animation
            withAnimation(.linear(duration: duration)) {
                progress = 1
            }
            
            // Auto dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                dismiss()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3)) {
            animateIn = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// Convenience modifier for adding toast to any view
struct ToastModifier: ViewModifier {
    @Binding var showToast: Bool
    let message: String
    let type: ToastNudge.ToastType
    let duration: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showToast {
                ToastNudge(
                    message: message,
                    type: type,
                    duration: duration,
                    onDismiss: {
                        showToast = false
                    }
                )
                .zIndex(1000)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func toast(
        isShowing: Binding<Bool>,
        message: String,
        type: ToastNudge.ToastType = .info,
        duration: Double = 3
    ) -> some View {
        modifier(ToastModifier(
            showToast: isShowing,
            message: message,
            type: type,
            duration: duration
        ))
    }
}

// Preview
struct ToastNudge_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var showSuccess = true
        @State private var showWarning = true
        @State private var showError = true
        @State private var showInfo = true
        
        var body: some View {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 80) {
                    ToastNudge(
                        message: "Meal logged successfully!",
                        type: .success,
                        duration: 3,
                        onDismiss: {}
                    )
                    
                    ToastNudge(
                        message: "Window ending in 10 minutes",
                        type: .warning,
                        duration: 3,
                        onDismiss: {}
                    )
                    
                    ToastNudge(
                        message: "Failed to sync data",
                        type: .error,
                        duration: 3,
                        onDismiss: {}
                    )
                    
                    ToastNudge(
                        message: "Tap to dismiss this message",
                        type: .info,
                        duration: 5,
                        onDismiss: {}
                    )
                }
            }
        }
    }
    
    static var previews: some View {
        PreviewWrapper()
    }
}
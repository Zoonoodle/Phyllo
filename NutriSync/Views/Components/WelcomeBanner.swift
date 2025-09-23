//
//  WelcomeBanner.swift
//  NutriSync
//
//  Created on 9/23/25.
//

import SwiftUI

/// A welcoming banner shown to first-time users after onboarding completion
struct WelcomeBanner: View {
    @State private var isShowing = true
    @State private var opacity: Double = 0
    @State private var offset: CGFloat = -20
    
    let onDismiss: () -> Void
    
    // Auto-dismiss timer
    private let autoDismissDelay: Double = 5.0
    
    var body: some View {
        if isShowing {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                                .foregroundStyle(Color.nutriSyncAccent)
                            
                            Text("Welcome to NutriSync!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                        }
                        
                        Text("Here's your personalized first day")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.9))
                        
                        Text("Your meal windows are ready. Tap any window to get started!")
                            .font(.footnote)
                            .foregroundStyle(Color.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background {
                    LinearGradient(
                        colors: [
                            Color.nutriSyncAccent.opacity(0.9),
                            Color.nutriSyncAccent.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: Color.nutriSyncAccent.opacity(0.3), radius: 20, y: 10)
                .padding(.horizontal, 16)
                .offset(y: offset)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        opacity = 1
                        offset = 0
                    }
                    
                    // Auto-dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            dismiss()
                        }
                    }
                }
                
                Spacer()
                    .frame(height: 0)
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            offset = -20
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
            onDismiss()
        }
    }
}

/// Alternative minimal welcome banner
struct MinimalWelcomeBanner: View {
    @State private var isShowing = true
    @State private var progress: CGFloat = 0
    
    let onDismiss: () -> Void
    private let displayDuration: Double = 5.0
    
    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                Image(systemName: "hand.wave.fill")
                    .font(.headline)
                    .foregroundStyle(Color.nutriSyncAccent)
                
                Text("Welcome! Your first day's meal plan is ready")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.white)
                
                Spacer()
                
                Button {
                    dismissBanner()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                    
                    // Progress indicator
                    GeometryReader { geometry in
                        HStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.nutriSyncAccent.opacity(0.1))
                                .frame(width: geometry.size.width * progress)
                            
                            Spacer()
                        }
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
            .padding(.horizontal, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                withAnimation(.linear(duration: displayDuration)) {
                    progress = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                    dismissBanner()
                }
            }
        }
    }
    
    private func dismissBanner() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
        onDismiss()
    }
}

/// Tomorrow plan message for late onboarding completions
struct TomorrowPlanBanner: View {
    @State private var isShowing = true
    let onDismiss: () -> Void
    
    var body: some View {
        if isShowing {
            VStack(spacing: 16) {
                Image(systemName: "moon.stars.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.nutriSyncAccent)
                
                Text("Welcome to NutriSync!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                
                Text("Since it's late in the day, we've prepared your meal windows for tomorrow.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("Get ready to start fresh in the morning with your personalized nutrition plan!")
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    withAnimation {
                        isShowing = false
                        onDismiss()
                    }
                } label: {
                    Text("Got it!")
                        .font(.headline)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.nutriSyncAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
            }
            .padding(.horizontal, 32)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Preview

#Preview("Welcome Banner") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            WelcomeBanner {
                print("Dismissed")
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview("Minimal Banner") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            MinimalWelcomeBanner {
                print("Dismissed")
            }
            
            Spacer()
        }
        .padding(.top, 60)
    }
}

#Preview("Tomorrow Plan") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        TomorrowPlanBanner {
            print("Dismissed")
        }
    }
}
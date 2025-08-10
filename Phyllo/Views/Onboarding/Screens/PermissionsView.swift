//
//  PermissionsView.swift
//  Phyllo
//
//  Permissions request screen
//

import SwiftUI

struct PermissionsView: View {
    @State private var notificationsEnabled = false
    @State private var healthEnabled = false
    @State private var cameraEnabled = false
    @State private var animateIn = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enable key features")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("These help us provide the best experience")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Permissions Cards
                VStack(spacing: 16) {
                    // Notifications
                    PermissionCard(
                        icon: "bell.badge.fill",
                        iconColor: .orange,
                        title: "Smart Nudges",
                        description: "Gentle reminders to eat within your meal windows and track your progress",
                        isEnabled: notificationsEnabled,
                        animationDelay: 0.1
                    ) {
                        requestNotificationPermission()
                    }
                    
                    // Health App
                    PermissionCard(
                        icon: "heart.text.square.fill",
                        iconColor: .red,
                        title: "Apple Health",
                        description: "Sync your activity, sleep, and health data for personalized insights",
                        isEnabled: healthEnabled,
                        animationDelay: 0.2
                    ) {
                        requestHealthPermission()
                    }
                    
                    // Camera
                    PermissionCard(
                        icon: "camera.fill",
                        iconColor: .blue,
                        title: "Camera Access",
                        description: "Scan your meals instantly with AI-powered food recognition",
                        isEnabled: cameraEnabled,
                        animationDelay: 0.3
                    ) {
                        requestCameraPermission()
                    }
                }
                .padding(.horizontal)
                
                // Benefits Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Why enable these?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    BenefitRow(
                        icon: "sparkles",
                        text: "Get personalized coaching at the right moments"
                    )
                    
                    BenefitRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Track how nutrition impacts your sleep and energy"
                    )
                    
                    BenefitRow(
                        icon: "bolt.fill",
                        text: "Log meals 10x faster with photo scanning"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.phylloAccent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.phylloAccent.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                .opacity(animateIn ? 1 : 0)
                .offset(y: animateIn ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateIn)
                
                // Privacy Note
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.phylloAccent)
                    
                    Text("Your privacy is our priority")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("We never share your personal data. All information is encrypted and used only to improve your experience.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: animateIn)
                
                // Skip Note
                Text("You can always enable these later in Settings")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                
                // Spacer for bottom padding
                Color.clear.frame(height: 100)
            }
        }
        .onAppear {
            withAnimation {
                animateIn = true
            }
        }
    }
    
    // MARK: - Permission Requests
    
    private func requestNotificationPermission() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    notificationsEnabled = granted
                }
            }
        }
    }
    
    private func requestHealthPermission() {
        // Placeholder hook for HealthKit integration
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { healthEnabled = true }
    }
    
    private func requestCameraPermission() {
        // Placeholder hook for camera permission
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { cameraEnabled = true }
    }
}

// MARK: - Permission Card

struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isEnabled: Bool
    let animationDelay: Double
    let action: () -> Void
    
    @State private var animateIn = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isEnabled ? iconColor.opacity(0.2) : Color.white.opacity(0.05))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isEnabled ? iconColor : .white.opacity(0.5))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if isEnabled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Enable Button
                if !isEnabled {
                    Text("Enable")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.phylloAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.phylloAccent.opacity(0.2))
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isEnabled ? 0.05 : 0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isEnabled ? iconColor.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(isEnabled ? 1.02 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animateIn ? 1 : 0)
        .offset(x: animateIn ? 0 : -50)
        .animation(.easeOut(duration: 0.6).delay(animationDelay), value: animateIn)
        .onAppear {
            animateIn = true
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.phylloAccent)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        PermissionsView()
    }
}
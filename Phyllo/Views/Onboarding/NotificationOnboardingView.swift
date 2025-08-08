import SwiftUI
import UserNotifications

struct NotificationOnboardingView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @Binding var isPresented: Bool
    @State private var isRequestingPermission = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.phylloAccent)
                    .padding(.top, 60)
                
                // Title
                Text("Never Miss a Meal Window")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Get timely reminders for your personalized meal windows and check-ins to stay on track with your nutrition goals.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            // Benefits
            VStack(spacing: 20) {
                NotificationBenefitRow(
                    icon: "clock.fill",
                    title: "Window Reminders",
                    description: "Know when to eat for optimal energy"
                )
                
                NotificationBenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Check-In Alerts",
                    description: "Track how meals affect your body"
                )
                
                NotificationBenefitRow(
                    icon: "moon.fill",
                    title: "Smart Timing",
                    description: "Respects your sleep schedule"
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Actions
            VStack(spacing: 12) {
                Button(action: enableNotifications) {
                    HStack {
                        if isRequestingPermission {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "bell.badge")
                        }
                        Text("Enable Notifications")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.phylloAccent)
                    )
                }
                .disabled(isRequestingPermission)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.phylloBackground)
    }
    
    private func enableNotifications() {
        isRequestingPermission = true
        
        Task {
            let granted = await notificationManager.requestAuthorization()
            
            isRequestingPermission = false
            
            if granted {
                // Schedule initial notifications
                if let windows = try? await DataSourceProvider.shared.provider.getWindows(for: Date()) {
                    await notificationManager.scheduleWindowNotifications(for: windows)
                }
                
                // Close onboarding
                isPresented = false
            } else {
                // Still close - they can enable later in settings
                isPresented = false
            }
        }
    }
}

struct NotificationBenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.phylloAccent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

#Preview {
    NotificationOnboardingView(isPresented: .constant(true))
        .environmentObject(NotificationManager.shared)
}
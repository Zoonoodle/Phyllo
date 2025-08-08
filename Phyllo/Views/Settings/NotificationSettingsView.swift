import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var isRequestingPermission = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.phylloBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Permission Status Section
                    permissionStatusSection
                    
                    // Notification Types Section
                    if notificationManager.isAuthorized {
                        notificationTypesSection
                        
                        // Quiet Hours Section
                        quietHoursSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .alert("Notification Settings", isPresented: $showingAlert) {
            Button("OK") { }
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Permission Status Section
    
    private var permissionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Push Notifications")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(statusDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                statusIcon
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.phylloElevated)
            )
            
            if notificationManager.authorizationStatus == .provisional {
                // Show upgrade button for provisional
                VStack(spacing: 12) {
                    Button(action: upgradeToFullNotifications) {
                        HStack {
                            Image(systemName: "bell.circle.fill")
                                .font(.system(size: 18))
                            Text("Enable Full Notifications")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.phylloAccent)
                        )
                    }
                    
                    Text("You're receiving quiet notifications. Enable full notifications for sounds and banners.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            } else if !notificationManager.isAuthorized {
                if notificationManager.authorizationStatus == .denied {
                    // Show settings button when denied
                    Button(action: openSettings) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 18))
                            Text("Open Settings")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.phylloAccent)
                        )
                    }
                    
                    Text("To enable notifications, go to Settings > Notifications > Phyllo and turn on Allow Notifications.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    // Show enable button when not determined
                    Button(action: requestPermission) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 18))
                            Text("Enable Notifications")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }
                    .disabled(isRequestingPermission)
                }
            }
        }
    }
    
    private var statusDescription: String {
        switch notificationManager.authorizationStatus {
        case .notDetermined:
            return "Get timely reminders for meal windows and check-ins"
        case .denied:
            return "Notifications are disabled. Enable in Settings to get meal reminders."
        case .authorized:
            return "You'll receive meal window reminders and coaching tips"
        case .provisional:
            return "You're receiving quiet notifications. Upgrade for full experience."
        case .ephemeral:
            return "Temporary access for this session"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private var statusIcon: some View {
        Group {
            switch notificationManager.authorizationStatus {
            case .authorized, .provisional:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            case .denied:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            case .notDetermined:
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Notification Types Section
    
    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Types")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NotificationToggleRow(
                    title: "Meal Window Reminders",
                    description: "Get notified when windows start and end",
                    isOn: $notificationManager.notificationPreferences.windowReminders
                )
                
                NotificationToggleRow(
                    title: "Check-In Reminders",
                    description: "Morning and post-meal check-ins",
                    isOn: $notificationManager.notificationPreferences.checkInReminders
                )
                
                NotificationToggleRow(
                    title: "Missed Window Alerts",
                    description: "Know when you've missed a meal window",
                    isOn: $notificationManager.notificationPreferences.missedWindowAlerts
                )
                
                NotificationToggleRow(
                    title: "Goal Progress",
                    description: "Daily and weekly progress updates",
                    isOn: $notificationManager.notificationPreferences.goalProgress
                )
                
                NotificationToggleRow(
                    title: "Coaching Tips",
                    description: "Personalized nutrition insights",
                    isOn: $notificationManager.notificationPreferences.coachingTips
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.phylloElevated)
            )
        }
        .onChange(of: notificationManager.notificationPreferences) { _, _ in
            notificationManager.savePreferences()
        }
    }
    
    // MARK: - Quiet Hours Section
    
    private var quietHoursSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quiet Hours")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Toggle("", isOn: $notificationManager.notificationPreferences.quietHoursEnabled)
                    .labelsHidden()
                    .tint(Color.phylloAccent)
            }
            
            if notificationManager.notificationPreferences.quietHoursEnabled {
                VStack(spacing: 16) {
                    // Start time
                    HStack {
                        Text("From")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(formatHour(notificationManager.notificationPreferences.quietHoursStart))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    // End time
                    HStack {
                        Text("Until")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(formatHour(notificationManager.notificationPreferences.quietHoursEnd))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.phylloElevated)
        )
        .onChange(of: notificationManager.notificationPreferences.quietHoursEnabled) { _, _ in
            notificationManager.savePreferences()
        }
    }
    
    // MARK: - Actions
    
    private func requestPermission() {
        isRequestingPermission = true
        
        Task {
            let granted = await notificationManager.requestAuthorization()
            
            isRequestingPermission = false
            
            if granted {
                // Schedule initial notifications
                if let windows = try? await DataSourceProvider.shared.provider.getWindows(for: Date()) {
                    await notificationManager.scheduleWindowNotifications(for: windows)
                }
            } else {
                // Check the current status after request
                await notificationManager.checkAuthorizationStatus()
                
                if notificationManager.authorizationStatus == .denied {
                    alertMessage = "Notifications have been disabled. To enable them, please go to Settings > Notifications > Phyllo."
                    showingAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func upgradeToFullNotifications() {
        Task {
            let granted = await notificationManager.requestFullAuthorization()
            if !granted {
                alertMessage = "Please enable full notifications in Settings to get sounds and banners for your meal reminders."
                showingAlert = true
            }
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        
        return "\(hour):00"
    }
}

// MARK: - Supporting Views

struct NotificationToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .tint(Color.phylloAccent)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(NotificationManager.shared)
    }
    .preferredColorScheme(.dark)
}
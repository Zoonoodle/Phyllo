//  ContentView.swift
//  Phyllo
//
//  Created by Brennen Price on 7/27/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var showNotificationOnboarding = false
    @AppStorage("hasSeenNotificationOnboarding") private var hasSeenNotificationOnboarding = false
    @AppStorage("lastNotificationPromptDate") private var lastNotificationPromptDate: Double = 0
    
    var body: some View {
        MainTabView()
            .withNudges()
            .fullScreenCover(isPresented: $showNotificationOnboarding) {
                NotificationOnboardingView(isPresented: $showNotificationOnboarding)
                    .environmentObject(notificationManager)
            }
            .task {
                await checkNotificationOnboarding()
            }
    }
    
    private func checkNotificationOnboarding() async {
        // Check if we should show notification onboarding
        guard !hasSeenNotificationOnboarding else { return }
        
        // Wait a bit for the app to settle
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Check current authorization status
        await notificationManager.checkAuthorizationStatus()
        
        // Show onboarding if not determined or provisional
        if notificationManager.authorizationStatus == .notDetermined {
            showNotificationOnboarding = true
            hasSeenNotificationOnboarding = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
            .environment(\.isPreview, true)
            .onAppear {
                // Initialize singletons for preview
                _ = NudgeManager.shared
                _ = TimeProvider.shared
                _ = ClarificationManager.shared
            }
    }
}




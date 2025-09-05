//  ContentView.swift
//  NutriSync
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
    
    // App refresh tracking
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("lastBackgroundTimestamp") private var lastBackgroundTimestamp: Double = 0
    @State private var shouldRefreshData = false
    
    // Refresh threshold: 20 minutes in seconds
    private let refreshThreshold: TimeInterval = 20 * 60
    
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
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(from: oldPhase, to: newPhase)
            }
            .task(id: shouldRefreshData) {
                if shouldRefreshData {
                    await refreshAppData()
                    shouldRefreshData = false
                }
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
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // Save timestamp when entering background
            lastBackgroundTimestamp = Date().timeIntervalSince1970
            print("📱 App entering background at \(Date())")
            
        case .active:
            // Check if we need to refresh when becoming active
            if lastBackgroundTimestamp > 0 {
                let currentTime = Date().timeIntervalSince1970
                let timeDifference = currentTime - lastBackgroundTimestamp
                
                if timeDifference >= refreshThreshold {
                    print("🔄 App was inactive for \(Int(timeDifference / 60)) minutes, refreshing data...")
                    shouldRefreshData = true
                } else {
                    print("📱 App became active after \(Int(timeDifference)) seconds")
                }
                
                // Reset timestamp
                lastBackgroundTimestamp = 0
            }
            
        case .inactive:
            // App is transitioning, no action needed
            break
            
        @unknown default:
            break
        }
    }
    
    private func refreshAppData() async {
        print("🔄 Starting app data refresh...")
        
        do {
            let provider = DataSourceProvider.shared.provider
            let today = Date()
            
            // Refresh today's windows
            _ = try await provider.getWindows(for: today)
            
            // Refresh today's meals
            _ = try await provider.getMeals(for: today)
            
            // Refresh analyzing meals
            _ = try await provider.getAnalyzingMeals()
            
            // Refresh user profile
            _ = try await provider.getUserProfile()
            
            // Refresh daily analytics
            _ = try await provider.getDailyAnalytics(for: today)
            
            // Trigger notification updates
            await notificationManager.checkAuthorizationStatus()
            if let windows = try? await provider.getWindows(for: today) {
                await notificationManager.scheduleWindowNotifications(for: windows)
            }
            
            // Notify other managers to refresh their data
            await MainActor.run {
                // This will trigger observers in ViewModels to update their UI
                NotificationCenter.default.post(name: .appDataRefreshed, object: nil)
            }
            
            print("✅ App data refresh completed")
        } catch {
            print("❌ Failed to refresh app data: \(error)")
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




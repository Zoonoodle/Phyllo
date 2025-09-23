//  ContentView.swift
//  NutriSync
//
//  Created by Brennen Price on 7/27/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var firebaseConfig: FirebaseConfig
    @EnvironmentObject private var dataProvider: FirebaseDataProvider
    @EnvironmentObject private var notificationManager: NotificationManager
    
    @State private var hasProfile = false
    @State private var isCheckingProfile = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var existingProgress: OnboardingProgress?
    @State private var showGetStarted = true
    @State private var onboardingViewModel = NutriSyncOnboardingViewModel()
    @State private var showingGetStarted = false  // Will be set in onAppear
    @AppStorage("hasSeenGetStarted") private var hasSeenGetStarted = false
    @State private var hasInitializedGetStarted = false  // Track if we've set initial state
    @AppStorage("onboardingResetFlag") private var onboardingResetFlag = 0  // For testing/reset
    
    // First day window generation
    @State private var isGeneratingFirstDayWindows = false
    @State private var showWelcomeBanner = false
    @State private var userProfile: UserProfile?
    
    // Notification onboarding
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
        ZStack {
            switch firebaseConfig.authState {
            case .unknown, .authenticating:
                LoadingView(message: "Initializing...")
                
            case .failed(let error):
                AuthErrorView(error: error) {
                    Task {
                        await firebaseConfig.initializeAuth()
                    }
                }
                
            case .anonymous, .authenticated:
                if isCheckingProfile {
                    LoadingView(message: "Loading your profile...")
                } else if !hasProfile {
                    NavigationStack {
                        NutriSyncOnboardingCoordinator(viewModel: onboardingViewModel, existingProgress: existingProgress, skipSectionIntro: showingGetStarted)
                            .environmentObject(firebaseConfig)
                            .environmentObject(dataProvider)
                    }
                    .fullScreenCover(isPresented: $showingGetStarted) {
                        GetStartedView()
                            .environmentObject(firebaseConfig)
                            .environmentObject(dataProvider)
                            .onDisappear {
                                hasSeenGetStarted = true
                            }
                    }
                    .onAppear {
                        // Only initialize once to avoid state changes during view updates
                        guard !hasInitializedGetStarted else { return }
                        hasInitializedGetStarted = true
                        
                        // Debug: Reset flag if needed (increment onboardingResetFlag to trigger)
                        #if DEBUG
                        if onboardingResetFlag > 0 && hasSeenGetStarted {
                            hasSeenGetStarted = false
                            print("🔄 Reset GetStartedView flag for debugging")
                        }
                        #endif
                        
                        // Show GetStartedView for new users who haven't seen it yet
                        // If they have onboarding progress beyond basics, skip GetStarted
                        let hasProgressBeyondBasics = (existingProgress?.currentSection ?? 0) > 0 || 
                                                      (existingProgress?.completedSections.contains(0) ?? false)
                        
                        // Show GetStarted if user hasn't seen it AND doesn't have progress beyond basics
                        // For completely new users (no progress at all), always show GetStarted
                        if existingProgress == nil && !hasSeenGetStarted {
                            // Brand new user - always show GetStarted
                            showingGetStarted = true
                            print("📱 Showing GetStartedView for new user")
                        } else {
                            // User with some progress - check conditions
                            showingGetStarted = !hasSeenGetStarted && !hasProgressBeyondBasics
                            print("📱 GetStarted decision: hasSeenGetStarted=\(hasSeenGetStarted), hasProgressBeyondBasics=\(hasProgressBeyondBasics), showing=\(showingGetStarted)")
                        }
                    }
                } else {
                    ZStack {
                        MainTabView()
                            .withNudges()
                            .fullScreenCover(isPresented: $showNotificationOnboarding) {
                                NotificationOnboardingView(isPresented: $showNotificationOnboarding)
                                    .environmentObject(notificationManager)
                            }
                            .task {
                                await checkNotificationOnboarding()
                                await checkFirstDayWindows()
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
                        
                        // Show welcome banner for first-time users
                        if showWelcomeBanner {
                            VStack {
                                WelcomeBanner {
                                    showWelcomeBanner = false
                                }
                                .padding(.top, 50)
                                
                                Spacer()
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Loading overlay for first day window generation
                        if isGeneratingFirstDayWindows {
                            Color.black.opacity(0.5)
                                .ignoresSafeArea()
                            
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .nutriSyncAccent))
                                    .scaleEffect(1.5)
                                
                                Text("Preparing your first day...")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding(32)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                            }
                        }
                    }
                }
            }
        }
        .task {
            await checkProfileExistence()
        }
        .onChange(of: firebaseConfig.authState) { _, newState in
            if case .anonymous = newState {
                Task {
                    await checkProfileExistence()
                }
            } else if case .authenticated = newState {
                Task {
                    await checkProfileExistence()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func checkProfileExistence() async {
        guard firebaseConfig.isAuthenticated else { return }
        
        isCheckingProfile = true
        do {
            // Check for completed profile
            hasProfile = try await dataProvider.hasCompletedOnboarding()
            
            // If no profile, check for existing progress
            if !hasProfile {
                existingProgress = try await dataProvider.loadOnboardingProgress()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            hasProfile = false
        }
        isCheckingProfile = false
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
    
    // MARK: - First Day Window Generation
    
    private func checkFirstDayWindows() async {
        // Only check for first-day windows if we have a profile
        guard hasProfile else { return }
        
        do {
            // Get user profile
            guard let profile = try await dataProvider.getUserProfile() else { return }
            self.userProfile = profile
            
            // Check if first-day windows should be generated
            let firstDayService = FirstDayWindowService()
            
            if firstDayService.shouldGenerateFirstDayWindows(profile: profile) {
                // Show loading state
                await MainActor.run {
                    isGeneratingFirstDayWindows = true
                }
                
                // Generate windows for the remainder of today
                let completionTime = profile.onboardingCompletedAt ?? Date()
                let windows = try await firstDayService.generateFirstDayWindows(
                    for: profile,
                    completionTime: completionTime
                )
                
                // Save windows to Firebase
                if !windows.isEmpty {
                    for window in windows {
                        try await dataProvider.saveWindow(window)
                    }
                    
                    // Update profile to mark first day as completed
                    var updatedProfile = profile
                    updatedProfile.firstDayCompleted = true
                    try await dataProvider.saveUserProfile(updatedProfile)
                    
                    // Show welcome banner
                    await MainActor.run {
                        isGeneratingFirstDayWindows = false
                        showWelcomeBanner = true
                    }
                } else {
                    // No windows generated (too late in the day)
                    // The FirstDayWindowService will handle showing tomorrow's plan
                    await MainActor.run {
                        isGeneratingFirstDayWindows = false
                    }
                }
            }
        } catch {
            print("❌ Failed to generate first-day windows: \(error)")
            await MainActor.run {
                isGeneratingFirstDayWindows = false
                errorMessage = "Failed to set up your first day: \(error.localizedDescription)"
                showError = true
            }
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




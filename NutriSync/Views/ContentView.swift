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
    @EnvironmentObject private var gracePeriodManager: GracePeriodManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

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

    // Splash screen
    @State private var showSplash = true

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

    // Paywall state
    @State private var showingPaywall = false
    @State private var paywallPlacement = ""

    // Trial welcome state (separate from paywall)
    @State private var showingTrialWelcome = false

    // TEMPORARY: For taking paywall screenshots
    @State private var showingMockPaywall = false

    // Refresh threshold: 20 minutes in seconds
    private let refreshThreshold: TimeInterval = 20 * 60

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            } else {
                mainContent
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

    @ViewBuilder
    private var mainContent: some View {
        switch firebaseConfig.authState {
        case .unknown, .authenticating:
            LoadingView(message: "Initializing...")

        case .failed(let error):
            authErrorView(error: error)

        case .anonymous, .authenticated:
            authenticatedContent
        }
    }

    private func authErrorView(error: Error) -> some View {
        AuthErrorView(error: error) {
            Task {
                await firebaseConfig.initializeAuth()
            }
        }
    }

    @ViewBuilder
    private var authenticatedContent: some View {
        if isCheckingProfile {
            LoadingView(message: "Loading your profile...")
        } else if !hasProfile {
            OnboardingFlowView(
                viewModel: $onboardingViewModel,
                existingProgress: existingProgress,
                showingGetStarted: $showingGetStarted,
                hasSeenGetStarted: $hasSeenGetStarted,
                hasInitializedGetStarted: $hasInitializedGetStarted,
                onboardingResetFlag: onboardingResetFlag
            )
        } else if !subscriptionManager.isSubscribed && !gracePeriodManager.isInGracePeriod && gracePeriodManager.gracePeriodEndDate != nil {
            // Grace period expired and not subscribed - HARD PAYWALL (blocking)
            // Only show if gracePeriodEndDate exists (means grace period was initialized)
            // NO DISMISS OPTION - user must subscribe to continue
            PaywallView(
                placement: "grace_period_expired",
                onDismiss: nil, // Explicitly nil - cannot be dismissed
                onSubscribe: {
                    // Subscription successful - refresh subscription status
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                }
            )
            .environmentObject(subscriptionManager)
            .environmentObject(gracePeriodManager)
            .interactiveDismissDisabled(true) // Prevent swipe dismiss
        } else {
            // Either subscribed OR in grace period - show app
            MainAppView(
                showNotificationOnboarding: $showNotificationOnboarding,
                showWelcomeBanner: $showWelcomeBanner,
                isGeneratingFirstDayWindows: $isGeneratingFirstDayWindows,
                scenePhase: scenePhase,
                shouldRefreshData: $shouldRefreshData,
                checkNotificationOnboarding: checkNotificationOnboarding,
                checkFirstDayWindows: checkFirstDayWindows,
                handleScenePhaseChange: handleScenePhaseChange,
                refreshAppData: refreshAppData
            )
            .environmentObject(notificationManager)
            .sheet(isPresented: $showingPaywall) {
                PaywallView(
                    placement: paywallPlacement,
                    onDismiss: {
                        showingPaywall = false
                    },
                    onSubscribe: {
                        showingPaywall = false
                        Task {
                            await subscriptionManager.checkSubscriptionStatus()
                        }
                    }
                )
                .environmentObject(subscriptionManager)
                .environmentObject(gracePeriodManager)
            }
            .sheet(isPresented: $showingMockPaywall) {
                MockPaywallView()
            }
            .overlay(alignment: .bottomTrailing) {
                // TEMPORARY: Screenshot button (DELETE after taking screenshots)
                Button {
                    showingMockPaywall = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Screenshot")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.nutriSyncAccent)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 100)
            }
            .onReceive(NotificationCenter.default.publisher(for: .showPaywall)) { notification in
                if let placement = notification.object as? String {
                    // Use separate view for trial welcome
                    if placement == "trial_welcome" {
                        showingTrialWelcome = true
                    } else {
                        paywallPlacement = placement
                        showingPaywall = true
                    }
                }
            }
            .sheet(isPresented: $showingTrialWelcome) {
                TrialWelcomeView(onDismiss: {
                    showingTrialWelcome = false
                })
            }
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

                // NEW: Show trial toast if in grace period
                if gracePeriodManager.isInGracePeriod {
                    // Small delay to let UI settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // This will be handled by MainAppView
                        NotificationCenter.default.post(
                            name: .showTrialToast,
                            object: nil
                        )
                    }
                }
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
                _ = TimeProvider.shared
                _ = ClarificationManager.shared
            }
    }
}

// MARK: - Trial Toast Notification

extension Notification.Name {
    static let showTrialToast = Notification.Name("showTrialToast")
}




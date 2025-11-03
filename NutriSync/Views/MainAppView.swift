//
//  MainAppView.swift
//  NutriSync
//
//  Extracted from ContentView to reduce compilation complexity
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var gracePeriodManager: GracePeriodManager

    @Binding var showNotificationOnboarding: Bool
    @Binding var showWelcomeBanner: Bool
    @Binding var isGeneratingFirstDayWindows: Bool
    let scenePhase: ScenePhase
    @Binding var shouldRefreshData: Bool

    let checkNotificationOnboarding: () async -> Void
    let checkFirstDayWindows: () async -> Void
    let handleScenePhaseChange: (ScenePhase, ScenePhase) -> Void
    let refreshAppData: () async -> Void

    @State private var isGracePeriodBannerCollapsed = false

    var body: some View {
        ZStack {
            mainTabView
            gracePeriodBannerOverlay
            welcomeBannerOverlay
            loadingOverlay
        }
    }

    private var mainTabView: some View {
        MainTabView()
            .fullScreenCover(isPresented: $showNotificationOnboarding) {
                NotificationOnboardingView(isPresented: $showNotificationOnboarding)
                    .environmentObject(notificationManager)
            }
            .task {
                await checkNotificationOnboarding()
                await checkFirstDayWindows()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(oldPhase, newPhase)
            }
            .task(id: shouldRefreshData) {
                if shouldRefreshData {
                    await refreshAppData()
                    shouldRefreshData = false
                }
            }
    }

    @ViewBuilder
    private var gracePeriodBannerOverlay: some View {
        if gracePeriodManager.isInGracePeriod {
            VStack {
                GracePeriodBanner(isCollapsed: $isGracePeriodBannerCollapsed)
                    .environmentObject(gracePeriodManager)
                    .transition(.move(edge: .top).combined(with: .opacity))

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var welcomeBannerOverlay: some View {
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
    }

    @ViewBuilder
    private var loadingOverlay: some View {
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

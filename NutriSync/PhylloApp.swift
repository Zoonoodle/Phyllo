//
//  NutriSyncApp.swift
//  NutriSync
//
//  Created by Brennen Price on 7/27/25.
//

import SwiftUI
import UserNotifications
import RevenueCat
import SuperwallKit

@main
struct NutriSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var firebaseConfig = FirebaseConfig.shared
    @StateObject private var dataProvider = FirebaseDataProvider.shared
    @StateObject private var timeProvider = TimeProvider.shared
    @StateObject private var clarificationManager = ClarificationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var vertexAIService = VertexAIService.shared
    @StateObject private var mealCaptureService = MealCaptureService.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var gracePeriodManager = GracePeriodManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    init() {
        // Configure Firebase FIRST before anything else
        FirebaseConfig.shared.configure()

        // Configure RevenueCat for subscription management
        Purchases.logLevel = .debug  // Change to .warn in production
        Purchases.configure(withAPIKey: "appl_QzcJHpMKoCVNkraSzGBERNhoynr")
        print("💳 RevenueCat configured")

        // Configure Superwall for paywall presentation
        // Note: Superwall automatically integrates with RevenueCat when both SDKs are present
        Superwall.configure(apiKey: "pk_a5e497a59d7774228265ff6c58e3204ac77eba91bb4cc695")
        print("🎨 Superwall configured")

        // Configure data provider after Firebase is ready
        configureDataProvider()

        // Configure notifications
        configureNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseConfig)
                .environmentObject(dataProvider)
                .environmentObject(timeProvider)
                .environmentObject(clarificationManager)
                .environmentObject(checkInManager)
                .environmentObject(vertexAIService)
                .environmentObject(mealCaptureService)
                .environmentObject(notificationManager)
                .environmentObject(gracePeriodManager)
                .environmentObject(subscriptionManager)
                .task {
                    // Initialize Firebase auth first
                    await firebaseConfig.initializeAuth()

                    // After auth, set up user identity for subscriptions
                    if let userId = firebaseConfig.currentUser?.uid {
                        // Identify user in RevenueCat
                        do {
                            _ = try await Purchases.shared.logIn(userId)
                            print("✅ RevenueCat user identity set: \(userId)")
                        } catch {
                            print("❌ RevenueCat login failed: \(error)")
                        }

                        // Identify user in Superwall
                        Superwall.shared.identify(userId: userId)
                        print("✅ Superwall user identity set: \(userId)")

                        // Initialize subscription and grace period managers
                        await subscriptionManager.initialize()
                        await gracePeriodManager.initialize()
                        print("✅ Managers initialized")
                    }
                }
        }
    }
    
    private func configureDataProvider() {
        // Check if Firebase is configured
        let firebaseConfigured = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        
        if !firebaseConfigured {
            print("⚠️ Firebase not configured - GoogleService-Info.plist not found")
            // Could implement a basic in-memory provider here if needed
            // For now, we'll still configure with Firebase and let it handle errors
        }
        
        // Always use Firebase data provider now that mock is removed
        DataSourceProvider.shared.configure(with: FirebaseDataProvider.shared)
        print("🔥 Using Firebase Data Provider")
    }
    
    private func configureNotifications() {
        // Configure notification categories and actions
        let logMealAction = UNNotificationAction(
            identifier: NotificationAction.logMeal.rawValue,
            title: "Log Meal",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: NotificationAction.remindLater.rawValue,
            title: "Remind in 15min",
            options: []
        )
        
        let viewDetailsAction = UNNotificationAction(
            identifier: NotificationAction.viewDetails.rawValue,
            title: "View Details",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss.rawValue,
            title: "Dismiss",
            options: [.destructive]
        )
        
        // Window reminder category
        let windowCategory = UNNotificationCategory(
            identifier: NotificationCategory.windowReminder.rawValue,
            actions: [logMealAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Check-in reminder category
        let checkInCategory = UNNotificationCategory(
            identifier: NotificationCategory.checkInReminder.rawValue,
            actions: [viewDetailsAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Missed window category
        let missedCategory = UNNotificationCategory(
            identifier: NotificationCategory.missedWindow.rawValue,
            actions: [logMealAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            windowCategory,
            checkInCategory,
            missedCategory
        ])
        
        print("📱 Notification categories configured")
    }
}

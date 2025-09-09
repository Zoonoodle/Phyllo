//
//  NutriSyncApp.swift
//  NutriSync
//
//  Created by Brennen Price on 7/27/25.
//

import SwiftUI
import UserNotifications

@main
struct NutriSyncApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var firebaseConfig = FirebaseConfig.shared
    @StateObject private var dataProvider = FirebaseDataProvider.shared
    @StateObject private var timeProvider = TimeProvider.shared
    @StateObject private var nudgeManager = NudgeManager.shared
    @StateObject private var clarificationManager = ClarificationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var vertexAIService = VertexAIService.shared
    @StateObject private var mealCaptureService = MealCaptureService.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Configure Firebase FIRST before anything else
        FirebaseConfig.shared.configure()
        
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
                .environmentObject(nudgeManager)
                .environmentObject(clarificationManager)
                .environmentObject(checkInManager)
                .environmentObject(vertexAIService)
                .environmentObject(mealCaptureService)
                .environmentObject(notificationManager)
                .task {
                    await firebaseConfig.initializeAuth()
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

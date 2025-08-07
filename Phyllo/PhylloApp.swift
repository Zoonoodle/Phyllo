//
//  PhylloApp.swift
//  Phyllo
//
//  Created by Brennen Price on 7/27/25.
//

import SwiftUI
import UserNotifications

@main
struct PhylloApp: App {
    @StateObject private var timeProvider = TimeProvider.shared
    @StateObject private var nudgeManager = NudgeManager.shared
    @StateObject private var clarificationManager = ClarificationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var vertexAIService = VertexAIService.shared
    @StateObject private var mealCaptureService = MealCaptureService.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    init() {
        // Configure Firebase on app launch
        FirebaseConfig.shared.configure()
        
        // Configure data provider based on Firebase availability
        configureDataProvider()
        
        // Configure notifications
        configureNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timeProvider)
                .environmentObject(nudgeManager)
                .environmentObject(clarificationManager)
                .environmentObject(checkInManager)
                .environmentObject(vertexAIService)
                .environmentObject(mealCaptureService)
                .environmentObject(notificationManager)
        }
    }
    
    private func configureDataProvider() {
        // Check if we should use mock data
        let useMockData = ProcessInfo.processInfo.arguments.contains("--use-mock-data")
        
        // Check if Firebase is configured
        let firebaseConfigured = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
        
        if useMockData || !firebaseConfigured {
            // Use mock data provider
            DataSourceProvider.shared.configure(with: MockDataProvider())
            print("📊 Using Mock Data Provider")
        } else {
            // Use Firebase data provider
            DataSourceProvider.shared.configure(with: FirebaseDataProvider())
            print("🔥 Using Firebase Data Provider")
        }
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

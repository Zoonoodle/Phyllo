//
//  PhylloApp.swift
//  Phyllo
//
//  Created by Brennen Price on 7/27/25.
//

import SwiftUI

@main
struct PhylloApp: App {
    @StateObject private var timeProvider = TimeProvider.shared
    @StateObject private var nudgeManager = NudgeManager.shared
    @StateObject private var clarificationManager = ClarificationManager.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var vertexAIService = VertexAIService.shared
    @StateObject private var mealCaptureService = MealCaptureService.shared
    
    init() {
        // Configure Firebase on app launch
        FirebaseConfig.shared.configure()
        
        // Configure data provider based on Firebase availability
        configureDataProvider()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mockDataManager)
                .environmentObject(timeProvider)
                .environmentObject(nudgeManager)
                .environmentObject(clarificationManager)
                .environmentObject(checkInManager)
                .environmentObject(vertexAIService)
                .environmentObject(mealCaptureService)
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
}

//
//  ScanTabView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI
import PhotosUI

struct ScanTabView: View {
    @Binding var showDeveloperDashboard: Bool
    @Binding var selectedTab: Int
    @Binding var scrollToAnalyzingMeal: AnalyzingMeal?
    @State private var selectedMode: ScanMode = .photo
    @State private var showQuickLog = false
    @State private var showVoiceInput = false
    @State private var showLoading = false
    @State private var showResults = false
    @State private var captureAnimation = false
    @State private var capturedImage: UIImage?
    @State private var currentAnalyzingMeal: AnalyzingMeal?
    @State private var lastCompletedMeal: LoggedMeal?
    @State private var showImagePicker = false
    @State private var analysisResult: MealAnalysisResult?
    @StateObject private var clarificationManager = ClarificationManager.shared
    @StateObject private var mealCaptureService = MealCaptureService.shared
    
    private let dataProvider = DataSourceProvider.shared.provider
    
    enum ScanMode: String, CaseIterable {
        case photo = "Photo"
        case voice = "Voice"
        case barcode = "Barcode"
        
        var icon: String {
            switch self {
            case .photo: return "camera.fill"
            case .voice: return "mic.fill"
            case .barcode: return "barcode.viewfinder"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                // Camera preview layer
                CameraPreviewView()
                    .ignoresSafeArea()
                
                // Scanner overlay
                ScannerOverlayView()
                    .ignoresSafeArea()
                
                // Main UI layer
                VStack(spacing: 0) {
                    // Top navigation bar - matching ScheduleView header
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            ZStack {
                                HStack {
                                    // Close button on left
                                    Button(action: {
                                        // Close action - handled by tab navigation
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                            .frame(width: 36, height: 36)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                    
                                    Spacer()
                                    
                                    // Photo library button on right
                                    Button(action: {
                                        showImagePicker = true
                                    }) {
                                        Image(systemName: "photo.on.rectangle")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                            .frame(width: 36, height: 36)
                                            .background(Color.white.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                
                                // Title centered
                                Text("Scan")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 6)
                        
                        // Separator line
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    VStack(spacing: 24) {
                        // Quick actions bar
                        QuickActionsBar(showQuickLog: $showQuickLog)
                            .padding(.horizontal, 20)
                        
                        // Mode selector
                        ScanModeSelector(selectedMode: $selectedMode)
                            .padding(.horizontal, 20)
                        
                        // Capture button with photo library option
                        HStack(spacing: 40) {
                            // Photo library button (smaller)
                            if selectedMode == .photo {
                                Button(action: {
                                    showImagePicker = true
                                }) {
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "photo.stack")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                            )
                                        Text("Library")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            } else {
                                // Spacer to maintain layout
                                Color.clear
                                    .frame(width: 50, height: 50)
                            }
                            
                            // Main capture button
                            CaptureButton(
                                mode: selectedMode,
                                isAnimating: $captureAnimation,
                                onCapture: {
                                    performCapture()
                                }
                            )
                            
                            // Balance spacer
                            Color.clear
                                .frame(width: 50, height: 50)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.bottom, 30)
                }
                .ignoresSafeArea(.keyboard)
            }
            .fullScreenCover(isPresented: $showVoiceInput) {
                VoiceInputView()
                    .onDisappear {
                        if !showVoiceInput {
                            // Voice input completed, start analyzing
                            simulateAIProcessing()
                        }
                    }
            }
            .sheet(isPresented: $showQuickLog) {
                QuickLogView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showLoading) {
                LoadingSheet()
                    .presentationDetents([.height(400)])
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showResults) {
                if let meal = lastCompletedMeal {
                    NavigationStack {
                        FoodAnalysisView(
                            meal: meal,
                            isFromScan: true,
                            onConfirm: {
                                // Save the meal to the data provider
                                Task {
                                    do {
                                        Task { @MainActor in
                                            DebugLogger.shared.dataProvider("Saving meal: \(meal.name)")
                                        }
                                        let start = Date()
                                        
                                        try await dataProvider.saveMeal(meal)
                                        
                                        Task { @MainActor in
                                            let elapsed = Date().timeIntervalSince(start)
                                            DebugLogger.shared.performance("⏱️ Completed Save Meal in \(String(format: "%.3f", elapsed))s")
                                            DebugLogger.shared.success("Meal saved successfully")
                                        }
                                        
                                        // Navigate to schedule to see the meal
                                        await MainActor.run {
                                            DebugLogger.shared.navigation("Navigating to schedule to show saved meal")
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedTab = 0
                                            }
                                            
                                            // Trigger meal sliding animation
                                            DebugLogger.shared.notification("Posting animateMealToWindow notification")
                                            NotificationCenter.default.post(
                                                name: .animateMealToWindow,
                                                object: meal
                                            )
                                        }
                                    } catch {
                                        Task { @MainActor in
                                            DebugLogger.shared.error("Failed to save meal: \(error)")
                                        }
                                    }
                                }
                            }
                        )
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        // Reset state when sheet is dismissed
                        lastCompletedMeal = nil
                        currentAnalyzingMeal = nil
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $capturedImage)
                    .onDisappear {
                        if capturedImage != nil {
                            // Show voice input after selecting image
                            showVoiceInput = true
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .mealAnalysisCompleted)) { notification in
            Task { @MainActor in
                DebugLogger.shared.notification("Received mealAnalysisCompleted notification")
            }
            if let analyzingMeal = notification.object as? AnalyzingMeal,
               let result = notification.userInfo?["result"] as? MealAnalysisResult,
               let savedMeal = notification.userInfo?["savedMeal"] as? LoggedMeal,
               analyzingMeal.id == currentAnalyzingMeal?.id {
                Task { @MainActor in
                    DebugLogger.shared.mealAnalysis("Analysis completed for meal: \(result.mealName)")
                    DebugLogger.shared.logMeal(savedMeal, action: "Received saved meal from notification")
                }
                
                // Store the saved meal and result for reference
                lastCompletedMeal = savedMeal
                analysisResult = result
                
                // Navigate to schedule view and show meal details
                Task { @MainActor in
                    DebugLogger.shared.navigation("Navigating to schedule view to show meal in window")
                }
                
                // First navigate to schedule tab
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 0 // Schedule tab
                }
                
                // Then post notification to show meal details in the window
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    Task { @MainActor in
                        DebugLogger.shared.notification("Posting navigateToMealDetails notification")
                    }
                    NotificationCenter.default.post(
                        name: .navigateToMealDetails,
                        object: savedMeal
                    )
                }
                
                // Clear the current analyzing meal
                currentAnalyzingMeal = nil
            }
        }
    }
    
    private func performCapture() {
        Task { @MainActor in
            DebugLogger.shared.ui("Capture button pressed - Mode: \(selectedMode.rawValue)")
        }
        withAnimation(.spring(response: 0.3)) {
            captureAnimation = true
        }
        
        // Simulate capture and navigate to voice input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            captureAnimation = false
            if selectedMode == .photo {
                // For photo mode, show voice input overlay
                Task { @MainActor in
                    DebugLogger.shared.ui("Showing voice input overlay")
                }
                showVoiceInput = true
            } else if selectedMode == .voice {
                // For voice-only mode, start analyzing immediately
                Task { @MainActor in
                    DebugLogger.shared.ui("Starting voice-only analysis")
                }
                simulateAIProcessing()
            } else {
                // For barcode, start analyzing
                Task { @MainActor in
                    DebugLogger.shared.ui("Starting barcode analysis")
                }
                simulateAIProcessing()
            }
        }
    }
    
    private func simulateAIProcessing() {
        Task {
            do {
                Task { @MainActor in
                    DebugLogger.shared.mealAnalysis("Starting meal analysis process")
                }
                let start = Date()
                
                // Start analyzing meal with real or mock AI
                let analyzingMeal = try await mealCaptureService.startMealAnalysis(
                    image: capturedImage,
                    voiceTranscript: nil // TODO: Add voice transcript support
                )
                
                Task { @MainActor in
                    DebugLogger.shared.logAnalyzingMeal(analyzingMeal, action: "Created")
                    let elapsed = Date().timeIntervalSince(start)
                    DebugLogger.shared.performance("⏱️ Completed Meal Analysis in \(String(format: "%.3f", elapsed))s")
                }
                
                await MainActor.run {
                    currentAnalyzingMeal = analyzingMeal
                    
                    // Navigate to timeline and scroll to analyzing meal
                    Task { @MainActor in
                        DebugLogger.shared.navigation("Navigating to timeline with analyzing meal")
                    }
                    scrollToAnalyzingMeal = analyzingMeal
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = 0
                    }
                }
            } catch {
                Task { @MainActor in
                    DebugLogger.shared.error("Failed to start meal analysis: \(error)")
                }
                await MainActor.run {
                    showLoading = false
                    // TODO: Show error alert
                }
            }
        }
    }
    
    
}

// Loading sheet component
struct LoadingSheet: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Drag indicator
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                Spacer()
                
                MealAnalysisLoadingView()
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Placeholder views - will be replaced with actual implementations

struct QuickActionsBar: View {
    @Binding var showQuickLog: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { showQuickLog = true }) {
                Label("Recent", systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
            
            Button(action: {}) {
                Label("Favorites", systemImage: "star.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
}





#Preview {
    ScanTabView(
        showDeveloperDashboard: .constant(false),
        selectedTab: .constant(2),
        scrollToAnalyzingMeal: .constant(nil)
    )
}
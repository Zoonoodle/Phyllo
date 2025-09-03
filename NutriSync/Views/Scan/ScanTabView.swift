//
//  ScanTabView.swift
//  NutriSync
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
    @State private var showVoiceInput = false
    @State private var showLoading = false
    @State private var showResults = false
    @State private var captureAnimation = false
    @State private var capturedImage: UIImage?
    @State private var currentAnalyzingMeal: AnalyzingMeal?
    @State private var lastCompletedMeal: LoggedMeal?
    @State private var showImagePicker = false
    @State private var analysisResult: MealAnalysisResult?
    @State private var capturePhotoTrigger = false
    @State private var voiceTranscript: String?
    @State private var showRecents = false
    @State private var recentMeals: [LoggedMeal] = []
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
                CameraView(
                    capturedImage: $capturedImage,
                    capturePhoto: $capturePhotoTrigger
                )
                .ignoresSafeArea()
                
                // Scanner overlay
                ScannerOverlayView()
                    .ignoresSafeArea()
                
                // Main UI layer
                VStack(spacing: 0) {
                    // Top navigation bar - simplified
                    VStack(spacing: 0) {
                        VStack(spacing: 8) {
                            // Title centered
                            Text("Scan")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
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
                            
                            // Recents button (right side)
                            if selectedMode == .photo {
                                Button(action: {
                                    showRecents = true
                                    Task {
                                        await loadRecentMeals()
                                    }
                                }) {
                                    VStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "clock.arrow.circlepath")
                                                    .font(.system(size: 20, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                            )
                                        Text("Recents")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            } else {
                                // Spacer to maintain layout
                                Color.clear
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.bottom, 30)
                }
                .ignoresSafeArea(.keyboard)
            }
            .fullScreenCover(isPresented: $showVoiceInput) {
                VoiceInputView(capturedImage: capturedImage) { transcript in
                    voiceTranscript = transcript
                    showVoiceInput = false
                    // Voice input completed, start analyzing
                    simulateAIProcessing()
                }
            }
            .sheet(isPresented: $showRecents) {
                RecentsView(
                    recentMeals: recentMeals,
                    selectedMeal: { meal in
                        // When a recent meal is selected, close the sheet and add it
                        showRecents = false
                        Task {
                            await handleRecentMealSelection(meal)
                        }
                    }
                )
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
                            // Show voice input after selecting image with small delay to ensure image is set
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showVoiceInput = true
                            }
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Pre-warm camera session to prevent black screen on first capture
            RealCameraPreviewView.sharedCameraSession.preWarmSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealAnalysisCompleted)) { notification in
            Task { @MainActor in
                DebugLogger.shared.notification("Received mealAnalysisCompleted notification")
            }
            if let analyzingMeal = notification.object as? AnalyzingMeal,
               let result = notification.userInfo?["result"] as? MealAnalysisResult,
               let savedMeal = notification.userInfo?["savedMeal"] as? LoggedMeal,
               analyzingMeal.id == currentAnalyzingMeal?.id {
                let _ = notification.userInfo?["metadata"] as? AnalysisMetadata
                
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
        
        if selectedMode == .photo {
            // Check if camera is ready
            if !RealCameraPreviewView.sharedCameraSession.isReady {
                Task { @MainActor in
                    DebugLogger.shared.ui("Camera still preparing, please wait...")
                }
                captureAnimation = false
                // TODO: Show "Camera preparing..." message to user
                return
            }
            
            // Trigger actual photo capture
            capturePhotoTrigger = true
            
            // Check for captured image after a longer delay to ensure capture completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                captureAnimation = false
                if capturedImage != nil {
                    Task { @MainActor in
                        DebugLogger.shared.ui("Photo captured, showing voice input overlay")
                    }
                    showVoiceInput = true
                } else {
                    Task { @MainActor in
                        DebugLogger.shared.ui("Photo capture failed - no image received")
                    }
                }
            }
        } else if selectedMode == .voice {
            // For voice-only mode, show voice input
            captureAnimation = false
            Task { @MainActor in
                DebugLogger.shared.ui("Starting voice-only capture")
            }
            showVoiceInput = true
        } else {
            // For barcode, start analyzing
            captureAnimation = false
            Task { @MainActor in
                DebugLogger.shared.ui("Starting barcode analysis")
            }
            simulateAIProcessing()
        }
    }
    
    private func loadRecentMeals() async {
        do {
            // Get meals from the last 7 days
            let calendar = Calendar.current
            let today = Date()
            var allMeals: [LoggedMeal] = []
            
            for daysAgo in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                    let mealsForDay = try await dataProvider.getMeals(for: date)
                    allMeals.append(contentsOf: mealsForDay)
                }
            }
            
            // Sort by most recent first and limit to 10
            recentMeals = allMeals
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(10)
                .map { $0 }
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to load recent meals: \(error)")
            }
            recentMeals = []
        }
    }
    
    private func handleRecentMealSelection(_ meal: LoggedMeal) async {
        // Create a new meal based on the selected recent meal
        let newMeal = LoggedMeal(
            name: meal.name,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            timestamp: Date(),
            windowId: nil, // Will be assigned when added to a window
            micronutrients: meal.micronutrients,
            ingredients: meal.ingredients,
            imageData: meal.imageData,
            appliedClarifications: meal.appliedClarifications
        )
        
        // Save the new meal
        do {
            try await dataProvider.saveMeal(newMeal)
            
            // Navigate to schedule to see the meal
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedTab = 0
                }
                
                // Trigger meal sliding animation
                NotificationCenter.default.post(
                    name: .animateMealToWindow,
                    object: newMeal
                )
            }
        } catch {
            Task { @MainActor in
                DebugLogger.shared.error("Failed to save meal from recent: \(error)")
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
                    voiceTranscript: voiceTranscript
                )
                
                Task { @MainActor in
                    DebugLogger.shared.logAnalyzingMeal(analyzingMeal, action: "Created")
                    let elapsed = Date().timeIntervalSince(start)
                    DebugLogger.shared.performance("⏱️ Completed Meal Analysis in \(String(format: "%.3f", elapsed))s")
                }
                
                await MainActor.run {
                    currentAnalyzingMeal = analyzingMeal
                    
                    // Reset capture state
                    capturedImage = nil
                    voiceTranscript = nil
                    
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

// Recents View - displays recently logged meals
struct RecentsView: View {
    let recentMeals: [LoggedMeal]
    let selectedMeal: (LoggedMeal) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if recentMeals.isEmpty {
                    emptyStateView
                } else {
                    mealListView
                }
            }
            .navigationTitle("Recent Meals")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No recent meals")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Your recently logged meals will appear here")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var mealListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(recentMeals) { meal in
                    mealRow(for: meal)
                }
            }
            .padding(20)
        }
    }
    
    private func mealRow(for meal: LoggedMeal) -> some View {
        Button(action: {
            selectedMeal(meal)
        }) {
            HStack(spacing: 12) {
                mealImage(for: meal)
                mealDetails(for: meal)
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
        }
    }
    
    private func mealImage(for meal: LoggedMeal) -> some View {
        Circle()
            .fill(Color.white.opacity(0.05))
            .frame(width: 56, height: 56)
            .overlay(
                Group {
                    if let photoData = meal.imageData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            )
    }
    
    private func mealDetails(for meal: LoggedMeal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meal.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack(spacing: 12) {
                Text("\(meal.calories) cal")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(formatTimeAgo(meal.timestamp))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            HStack(spacing: 8) {
                MacroTag(value: Double(meal.protein), label: "P", color: .green)
                MacroTag(value: Double(meal.carbs), label: "C", color: .orange)
                MacroTag(value: Double(meal.fat), label: "F", color: .yellow)
            }
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day, .hour, .minute], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes) min ago"
        } else {
            return "Just now"
        }
    }
}

// MacroTag is now a shared component in Views/Components/MacroTag.swift





#Preview {
    ScanTabView(
        showDeveloperDashboard: .constant(false),
        selectedTab: .constant(2),
        scrollToAnalyzingMeal: .constant(nil)
    )
}
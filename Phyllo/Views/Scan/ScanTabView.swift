//
//  ScanTabView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct ScanTabView: View {
    @Binding var showDeveloperDashboard: Bool
    @State private var selectedMode: ScanMode = .photo
    @State private var showQuickLog = false
    @State private var showVoiceInput = false
    @State private var showLoading = false
    @State private var showClarification = false
    @State private var showResults = false
    @State private var captureAnimation = false
    @State private var capturedImage: UIImage?
    @State private var currentAnalyzingMeal: AnalyzingMeal?
    @State private var lastCompletedMeal: LoggedMeal?
    @StateObject private var mockData = MockDataManager.shared
    
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
                                    
                                    // History button on right
                                    Button(action: {
                                        // Show scan history
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
                        
                        // Capture button
                        CaptureButton(
                            mode: selectedMode,
                            isAnimating: $captureAnimation,
                            onCapture: {
                                performCapture()
                            }
                        )
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
            .fullScreenCover(isPresented: $showClarification) {
                ClarificationQuestionsView()
                    .onDisappear {
                        if !showClarification {
                            showResults = true
                        }
                    }
            }
            .sheet(isPresented: $showResults) {
                if let meal = lastCompletedMeal {
                    NavigationStack {
                        FoodAnalysisView(meal: meal, isFromScan: true)
                    }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func performCapture() {
        withAnimation(.spring(response: 0.3)) {
            captureAnimation = true
        }
        
        // Simulate capture and navigate to voice input
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            captureAnimation = false
            if selectedMode == .photo {
                // For photo mode, show voice input overlay
                showVoiceInput = true
            } else if selectedMode == .voice {
                // For voice-only mode, start analyzing immediately
                simulateAIProcessing()
            } else {
                // For barcode, start analyzing
                simulateAIProcessing()
            }
        }
    }
    
    private func simulateAIProcessing() {
        // Start analyzing meal
        let analyzingMeal = mockData.startAnalyzingMeal(
            imageData: capturedImage?.pngData(),
            voiceDescription: nil
        )
        currentAnalyzingMeal = analyzingMeal
        
        // Navigate to timeline and scroll to analyzing meal
        showLoading = false
        NotificationCenter.default.post(
            name: .switchToTimelineWithScroll,
            object: analyzingMeal
        )
        
        // Simulate AI processing time in background
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // Convert to logged meal
            let result = analyzingMeal.toLoggedMeal(
                name: "Grilled Chicken Salad",
                calories: 450,
                protein: 35,
                carbs: 25,
                fat: 20
            )
            
            // Complete the analyzing meal
            mockData.completeAnalyzingMeal(analyzingMeal, with: result)
            lastCompletedMeal = result
            currentAnalyzingMeal = nil
            
            // Show food analysis view after completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showResults = true
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
    ScanTabView(showDeveloperDashboard: .constant(false))
}
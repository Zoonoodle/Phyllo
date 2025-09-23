//
//  EnhancedFinishView.swift
//  NutriSync
//
//  Main container for enhanced onboarding completion flow
//

import SwiftUI

struct EnhancedFinishView: View {
    @State private var viewModel = OnboardingCompletionViewModel()
    @Environment(NutriSyncOnboardingViewModel.self) var coordinator
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    @State private var navigateToApp = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Page navigation
    @State private var currentPage = 0
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            // Page content
            Group {
                switch viewModel.currentScreen {
                case .processing:
                    ProcessingView(message: $viewModel.processingMessage)
                        .transition(.opacity)
                    
                case .visualization, .explanation, .nextSteps:
                    // Swipeable pages
                    TabView(selection: $currentPage) {
                        ProgramVisualizationView(viewModel: viewModel)
                            .tag(0)
                        
                        ProgramExplanationView(viewModel: viewModel)
                            .tag(1)
                        
                        WhatHappensNextView(viewModel: viewModel)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                }
            }
            
            // Navigation controls with page indicators (only show after processing)
            if viewModel.currentScreen != .processing {
                VStack {
                    // Top navigation bar with back button and dots
                    HStack {
                        // Back button (only show on pages after first)
                        if currentPage > 0 {
                            Button(action: {
                                withAnimation {
                                    currentPage = max(0, currentPage - 1)
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                            }
                        } else {
                            // Empty spacer to maintain layout
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        // Page indicators centered
                        PageIndicators(
                            numberOfPages: 3,
                            currentPage: $currentPage
                        )
                        
                        Spacer()
                        
                        // Forward button or empty space for balance
                        if currentPage < 2 {
                            Button(action: {
                                withAnimation {
                                    currentPage = min(2, currentPage + 1)
                                }
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 44, height: 44)
                            }
                        } else {
                            // Empty spacer to maintain layout
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 8)
                    
                    Spacer()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToApp) {
            MainTabView()
                .navigationBarBackButtonHidden(true)
        }
        .alert("Setup Error", isPresented: $showError) {
            Button("Retry") {
                Task {
                    do {
                        try await coordinator.completeOnboarding()
                        navigateToApp = true
                    } catch {
                        errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            // Start processing when view appears
            await viewModel.startProcessing(coordinator: coordinator)
        }
        .onChange(of: viewModel.currentScreen) { _, newScreen in
            // Update page when transitioning from processing
            if newScreen == .visualization {
                currentPage = 0
            }
        }
        .onChange(of: currentPage) { _, newPage in
            // Update viewModel screen based on page
            switch newPage {
            case 0:
                viewModel.currentScreen = .visualization
            case 1:
                viewModel.currentScreen = .explanation
            case 2:
                viewModel.currentScreen = .nextSteps
            default:
                break
            }
        }
    }
}

// MARK: - Page Indicators
struct PageIndicators: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.nutriSyncAccent : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(page == currentPage ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationStack {
        EnhancedFinishView()
            .environmentObject(FirebaseDataProvider.shared)
    }
}
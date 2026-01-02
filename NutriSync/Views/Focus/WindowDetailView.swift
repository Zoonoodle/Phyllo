//
//  WindowDetailView.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowDetailView: View {
    let windowId: String  // Store ID instead of copy
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showEditWindow = false
    @State private var showWindowDetailTour = false
    @State private var windowDetailTourStep = 0
    private let tourManager = TourManager.shared

    // Look up current window from viewModel - this ensures we always have fresh data
    private var window: MealWindow {
        viewModel.mealWindows.first(where: { $0.id == windowId }) ?? fallbackWindow
    }

    // Fallback in case window is removed (shouldn't happen in normal use)
    private var fallbackWindow: MealWindow {
        MealWindow(
            name: "Window",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            targetCalories: 0,
            targetProtein: 0,
            targetCarbs: 0,
            targetFat: 0,
            purpose: .sustainedEnergy,
            flexibility: .moderate,
            type: .regular
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Scrollable nutrition header
                        ScrollableNutritionHeader(window: window, currentPage: $currentPage, viewModel: viewModel)
                        
                        // Custom page indicator
                        HStack(spacing: 8) {
                            ForEach(0..<2) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                            }
                        }
                        .padding(.top, -8) // Reduce spacing between card and indicator

                        // Window score section (only when window has been scored)
                        if let windowScore = window.windowScore {
                            WindowScoreSection(windowScore: windowScore, purposeColor: window.purpose.color)
                        }

                        // Logged foods section
                        WindowFoodsList(window: window, selectedMealId: .constant(nil), viewModel: viewModel)

                        // What to Eat section (for active/upcoming windows)
                        if shouldShowWhatToEat {
                            WhatToEatSectionCard(window: window)
                        }

                        // Window purpose section
                        WindowPurposeCard(window: window)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 10) // Increased padding to avoid Dynamic Island/notch
                    .padding(.horizontal, 32) // Add consistent horizontal padding to entire content
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(window.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [window.purpose.gradientColors.primary, window.purpose.gradientColors.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showEditWindow = true
                        } label: {
                            Label("Edit Window", systemImage: "pencil")
                        }
                        
                        Button {
                            // Skip window action
                        } label: {
                            Label("Skip Window", systemImage: "forward.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.nutriSyncBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showEditWindow) {
            EditWindowView(window: window, viewModel: viewModel)
        }
        .overlayPreferenceValue(SpotlightAnchorKey.self) { anchors in
            if showWindowDetailTour {
                WindowDetailTour(
                    currentStep: $windowDetailTourStep,
                    anchors: anchors,
                    onComplete: {
                        tourManager.completeWindowDetailTour()
                        showWindowDetailTour = false
                        windowDetailTourStep = 0
                    }
                )
            }
        }
        .onAppear {
            // Show Window Detail tour if first time
            if tourManager.shouldShowWindowDetailTour {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showWindowDetailTour = true
                }
            }
        }
    }

    // Check if we should show the What to Eat section in DETAIL VIEW
    // Always show for all window states - users can reference suggestions even after eating
    private var shouldShowWhatToEat: Bool {
        // Always show in detail view - WhatToEatSection handles empty states
        // This allows users to see suggestions even for completed windows
        return true
    }
}

// MARK: - What to Eat Card for Detail View

/// Card displaying food suggestions matching WindowPurposeCard style (non-collapsible)
private struct WhatToEatSectionCard: View {
    let window: MealWindow
    @State private var selectedSuggestion: FoodSuggestion?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header (matches WindowPurposeCard)
            Text("Food Suggestions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            // Card content (matching WindowPurposeCard structure exactly)
            VStack(alignment: .leading, spacing: 20) {
                // Title with icon (matching WindowPurposeCard style)
                HStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.nutriSyncAccent)

                    Text("What to Eat")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Context description (matching WindowPurposeCard description style)
                if let contextNote = window.suggestionContextNote {
                    Text(contextNote)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .lineSpacing(4)
                }

                // Suggestion content (always visible, non-collapsible)
                suggestionContent
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.nutriSyncElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                    )
            )
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            FoodSuggestionDetailSheet(suggestion: suggestion)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private var suggestionContent: some View {
        switch window.suggestionStatus {
        case .pending:
            SuggestionEmptyStateView(status: .pending, windowStartTime: window.startTime)

        case .generating:
            SuggestionEmptyStateView(status: .generating)

        case .ready:
            if window.smartSuggestions.isEmpty {
                SuggestionEmptyStateView(status: .failed, onRetry: nil)
            } else {
                suggestionsList
            }

        case .failed:
            SuggestionEmptyStateView(status: .failed, onRetry: nil)
        }
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Suggestions header (matching WindowPurposeCard subsection style)
            Text("Personalized Ideas")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            // Suggestion cards with proper spacing
            VStack(spacing: 12) {
                ForEach(window.smartSuggestions) { suggestion in
                    FoodSuggestionCard(suggestion: suggestion) {
                        selectedSuggestion = suggestion
                    }
                }
            }
        }
    }
}

// MARK: - Window Score Section

/// Section showing window score with new design: ScoreText, progress bar, factor chips, and insight
private struct WindowScoreSection: View {
    let windowScore: WindowScore
    let purposeColor: Color

    @State private var showBreakdown = false

    // Generate factor chips from macro breakdown
    private var adherenceFactors: [FactorChipData] {
        // Convert 0-100 scores to contribution values (-2.5 to +2.5)
        func toContribution(_ score: Int) -> Double {
            // 100 = +2.5, 50 = 0, 0 = -2.5
            return (Double(score) - 50) / 20.0
        }

        return [
            FactorChipData(label: "Calories", value: toContribution(windowScore.breakdown.calorieScore)),
            FactorChipData(label: "Protein", value: toContribution(windowScore.breakdown.proteinScore)),
            FactorChipData(label: "Carbs", value: toContribution(windowScore.breakdown.carbScore)),
            FactorChipData(label: "Fat", value: toContribution(windowScore.breakdown.fatScore))
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Window Score")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 16) {
                // Score display with progress bar
                VStack(alignment: .leading, spacing: 8) {
                    ScoreText(score: windowScore.displayScore, size: .medium, showTotal: true)
                    ScoreProgressBar.fromInternal(windowScore.score)
                }

                // Insight text
                InsightBox(
                    title: "Adherence",
                    text: windowScore.generatedInsight,
                    icon: "target"
                )

                // Contributing factors
                VStack(alignment: .leading, spacing: 12) {
                    Text("MACRO ADHERENCE")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .tracking(0.5)

                    FactorChipGrid(factors: adherenceFactors)
                }

                // Expandable detailed breakdown
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showBreakdown.toggle()
                    }
                }) {
                    HStack {
                        Text("See detailed breakdown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Image(systemName: showBreakdown ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 8)
                }
                .buttonStyle(PlainButtonStyle())

                // Expanded breakdown
                if showBreakdown {
                    detailedBreakdownView
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.nutriSyncElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
                    )
            )
        }
    }

    @ViewBuilder
    private var detailedBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Per-macro breakdown with progress bars
            VStack(spacing: 12) {
                MacroAdherenceRow(
                    label: "Calories",
                    score: windowScore.breakdown.calorieScore,
                    description: adherenceDescription(windowScore.breakdown.calorieScore)
                )
                MacroAdherenceRow(
                    label: "Protein",
                    score: windowScore.breakdown.proteinScore,
                    description: adherenceDescription(windowScore.breakdown.proteinScore)
                )
                MacroAdherenceRow(
                    label: "Carbs",
                    score: windowScore.breakdown.carbScore,
                    description: adherenceDescription(windowScore.breakdown.carbScore)
                )
                MacroAdherenceRow(
                    label: "Fat",
                    score: windowScore.breakdown.fatScore,
                    description: adherenceDescription(windowScore.breakdown.fatScore)
                )
            }
        }
        .padding(.top, 8)
    }

    private func adherenceDescription(_ score: Int) -> String {
        switch score {
        case 90...100: return "On target"
        case 70..<90: return "Close"
        case 50..<70: return "Needs work"
        default: return "Off target"
        }
    }
}

// MARK: - Macro Adherence Row

private struct MacroAdherenceRow: View {
    let label: String
    let score: Int
    let description: String

    private var scoreColor: Color {
        switch score {
        case 85...100: return .nutriSyncAccent
        case 70..<85: return Color(hex: "A8E063")
        case 50..<70: return Color(hex: "FFD93D")
        case 25..<50: return Color(hex: "FFA500")
        default: return Color(hex: "FF6B6B")
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(scoreColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor)
                        .frame(width: geometry.size.width * CGFloat(score) / 100)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: score)
                }
            }
            .frame(height: 6)
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = ScheduleViewModel()

    if let window = viewModel.mealWindows.first {
        WindowDetailView(windowId: window.id, viewModel: viewModel)
    }
}

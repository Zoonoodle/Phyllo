//
//  NutritionDashboardView.swift
//  NutriSync
//
//  Main nutrition dashboard container
//

import SwiftUI

struct NutritionDashboardView: View {
    @Binding var showDeveloperDashboard: Bool
    @StateObject private var viewModel = NutritionDashboardViewModel()
    @StateObject private var insightsEngine = InsightsEngine.shared
    @StateObject private var checkInManager = CheckInManager.shared
    @StateObject private var timeProvider = TimeProvider.shared
    
    @State private var selectedView: DashboardView = .now
    @State private var ringAnimations = RingAnimationState()
    @State private var refreshing = false
    @State private var infoPopupData: InfoPopupData? = nil
    
    enum DashboardView {
        case now, today, week, insights
    }
    
    struct RingAnimationState {
        var timingProgress: Double = 0
        var nutrientProgress: Double = 0
        var adherenceProgress: Double = 0
        var animating: Bool = false
    }
    
    struct InfoPopupData {
        let title: String
        let description: String
        let color: Color
        let position: CGPoint
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with tabs
                    headerSection
                    
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            contentView
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await refresh()
                    }
                }
                
                // Info popup overlay
                if let popupData = infoPopupData {
                    InfoFloatingCard(
                        data: popupData,
                        onDismiss: { infoPopupData = nil }
                    )
                }
            }
        }
        .onAppear {
            loadData()
            animateRings()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Centered title with settings button
            ZStack {
                // Settings button on the right
                HStack {
                    Spacer()
                    
                    Button(action: { showDeveloperDashboard = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 36, height: 36)
                    }
                }
                
                // Centered title
                Text("Nutrition Performance")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // View selector tabs
            viewSelector
        }
    }
    
    private var viewSelector: some View {
        HStack(spacing: 0) {
            ForEach([DashboardView.now, .today, .week, .insights], id: \.self) { view in
                Button(action: { selectedView = view }) {
                    VStack(spacing: 4) {
                        Text(viewTitle(for: view))
                            .font(.system(size: 14, weight: selectedView == view ? .semibold : .medium))
                            .foregroundColor(selectedView == view ? .white : .white.opacity(0.5))
                        
                        Rectangle()
                            .fill(selectedView == view ? Color.nutriSyncAccent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func viewTitle(for view: DashboardView) -> String {
        switch view {
        case .now: return "NOW"
        case .today: return "TODAY"
        case .week: return "WEEK"
        case .insights: return "INSIGHTS"
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        switch selectedView {
        case .now:
            NutritionDashboardNowView(
                viewModel: viewModel,
                ringAnimations: $ringAnimations,
                infoPopupData: $infoPopupData
            )
        case .today:
            NutritionDashboardTodayView(viewModel: viewModel)
        case .week:
            NutritionDashboardWeekView(viewModel: viewModel)
        case .insights:
            NutritionDashboardInsightsView(
                viewModel: viewModel,
                insightsEngine: insightsEngine
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadData() {
        Task {
            await viewModel.loadData()
        }
    }
    
    private func animateRings() {
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            ringAnimations.timingProgress = viewModel.timingPercentage / 100
            ringAnimations.nutrientProgress = viewModel.nutrientPercentage / 100
            ringAnimations.adherenceProgress = viewModel.adherencePercentage / 100
        }
    }
    
    private func refresh() async {
        refreshing = true
        await viewModel.loadData()
        refreshing = false
    }
}

// MARK: - Activity Ring Component

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let diameter: CGFloat
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.8),
                            color,
                            color.opacity(0.9)
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * min(progress, 1.0))
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Info Floating Card

struct InfoFloatingCard: View {
    let data: NutritionDashboardView.InfoPopupData
    let onDismiss: () -> Void
    
    @State private var animateIn = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(data.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            Text(data.description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(data.color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: data.color.opacity(0.3), radius: 20)
        .offset(dragOffset)
        .scaleEffect(isDragging ? 0.95 : (animateIn ? 1.0 : 0.8))
        .opacity(animateIn ? 1.0 : 0)
        .frame(maxWidth: 320)
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    if abs(value.translation.height) > 100 || abs(value.translation.width) > 100 {
                        onDismiss()
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring()) {
                animateIn = true
            }
        }
    }
}

#Preview {
    NutritionDashboardView(showDeveloperDashboard: .constant(false))
        .preferredColorScheme(.dark)
}
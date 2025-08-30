//
//  NightShiftTimelineView.swift
//  NutriSync
//
//  Special timeline view for night shift workers that respects biological time over clock time
//

import SwiftUI

struct NightShiftTimelineView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    // Dynamic layout manager for content-based heights
    @StateObject private var layoutManager = TimelineLayoutManager()
    @State private var calculatedHourLayouts: [TimelineLayoutManager.HourLayout] = []
    @State private var calculatedWindowLayouts: [TimelineLayoutManager.WindowLayout] = []
    
    // For night shift, we want 24 hours starting from wake time
    private var biologicalHours: [Int] {
        guard let profile = viewModel.userProfile else {
            return Array(0..<24)
        }
        
        let calendar = Calendar.current
        let wakeHour = calendar.component(.hour, from: profile.wakeTime)
        
        // Create array starting from wake hour for 24 hours
        var hours: [Int] = []
        for i in 0..<24 {
            let hour = (wakeHour + i) % 24
            hours.append(hour)
        }
        return hours
    }
    
    // Get human-readable labels for biological time
    private func biologicalTimeLabel(for hour: Int, offset: Int) -> String {
        let hoursFromWake = offset
        
        if hoursFromWake == 0 {
            return "Wake Up"
        } else if hoursFromWake < 4 {
            return "Early Day"
        } else if hoursFromWake < 8 {
            return "Mid Day"
        } else if hoursFromWake < 12 {
            return "Late Day"
        } else if hoursFromWake < 16 {
            return "Evening"
        } else if hoursFromWake < 20 {
            return "Late Evening"
        } else {
            return "Pre-Sleep"
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 16) {
                // Header explaining biological time
                biologicalTimeHeader
                
                // Timeline content
                timelineContent
                    .onAppear {
                        updateLayouts()
                        scrollToCurrentBiologicalTime(proxy: proxy)
                    }
                    .onChange(of: viewModel.mealWindows.count) { _, _ in
                        updateLayouts()
                    }
                    .onChange(of: viewModel.todaysMeals.count) { _, _ in
                        updateLayouts()
                    }
                    .onReceive(timer) { _ in
                        currentTime = Date()
                    }
            }
        }
    }
    
    @ViewBuilder
    private var biologicalTimeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.nutriSyncAccent)
                Text("Night Shift Mode")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text("Timeline organized by your biological clock, not wall clock time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.nutriSyncCard)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var timelineContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(biologicalHours.enumerated()), id: \.element) { index, hour in
                    NightShiftHourRow(
                        hour: hour,
                        biologicalLabel: biologicalTimeLabel(for: hour, offset: index),
                        isCurrentHour: Calendar.current.component(.hour, from: currentTime) == hour,
                        height: calculatedHourLayouts.first(where: { $0.hour == hour })?.height ?? 60
                    )
                    .frame(height: calculatedHourLayouts.first(where: { $0.hour == hour })?.height ?? 60)
                    .id("hour-\(hour)")
                }
            }
            .overlay(alignment: .topLeading) {
                overlayContent
            }
        }
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        ZStack(alignment: .topLeading) {
            // Current time indicator
            CurrentTimeIndicatorDynamic(
                hourLayouts: calculatedHourLayouts,
                currentTime: currentTime
            )
            
            // Windows overlay with midnight split handling
            WindowsOverlayWithMidnightSplit(
                windowLayouts: calculatedWindowLayouts,
                viewModel: viewModel,
                selectedWindow: $selectedWindow,
                showWindowDetail: $showWindowDetail,
                animationNamespace: animationNamespace
            )
        }
    }
    
    private func updateLayouts() {
        // Process windows, splitting any that cross midnight
        let processedWindows = viewModel.mealWindows.flatMap { window in
            window.crossesMidnight ? window.splitAtMidnight() : [window]
        }
        
        let layouts = layoutManager.calculateLayouts(
            for: processedWindows,
            hours: biologicalHours,
            viewModel: viewModel
        )
        
        calculatedHourLayouts = layouts.hours
        calculatedWindowLayouts = layouts.windows
    }
    
    private func scrollToCurrentBiologicalTime(proxy: ScrollViewProxy) {
        // Calculate current biological time (hours since wake)
        guard let profile = viewModel.userProfile else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let wakeHour = calendar.component(.hour, from: profile.wakeTime)
        let currentHour = calendar.component(.hour, from: now)
        
        // Find the position in our biological timeline
        let biologicalPosition = (currentHour - wakeHour + 24) % 24
        
        if biologicalPosition < biologicalHours.count {
            let targetHour = biologicalHours[biologicalPosition]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("hour-\(targetHour)", anchor: .center)
                }
            }
        }
    }
}

// Special hour row for night shift showing biological time
struct NightShiftHourRow: View {
    let hour: Int
    let biologicalLabel: String
    let isCurrentHour: Bool
    let height: CGFloat
    
    private var timeString: String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Time column with biological label
            VStack(alignment: .leading, spacing: 4) {
                Text(timeString)
                    .font(.system(size: 14, weight: isCurrentHour ? .semibold : .regular))
                    .foregroundColor(isCurrentHour ? .nutriSyncAccent : .secondary)
                    .frame(width: 60, alignment: .leading)
                
                Text(biologicalLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.tertiary)
                    .lineLimit(1)
            }
            
            // Timeline line
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 1)
                    .overlay(alignment: .top) {
                        Circle()
                            .fill(isCurrentHour ? Color.nutriSyncAccent : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(isCurrentHour ? Color.nutriSyncAccent.opacity(0.05) : Color.clear)
    }
}

// Windows overlay that handles midnight-crossing windows
struct WindowsOverlayWithMidnightSplit: View {
    let windowLayouts: [TimelineLayoutManager.WindowLayout]
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    
    var body: some View {
        ForEach(windowLayouts) { layout in
            WindowCardDynamic(
                window: layout.window,
                layout: layout,
                meals: mealsForWindow(layout.window),
                analyzingMeals: analyzingMealsForWindow(layout.window),
                selectedWindow: $selectedWindow,
                showWindowDetail: $showWindowDetail,
                animationNamespace: animationNamespace
            )
            .position(x: layout.position.x, y: layout.position.y)
        }
    }
    
    private func mealsForWindow(_ window: MealWindow) -> [LoggedMeal] {
        viewModel.todaysMeals.filter { meal in
            window.contains(timestamp: meal.loggedAt)
        }
    }
    
    private func analyzingMealsForWindow(_ window: MealWindow) -> [UUID] {
        viewModel.analyzingMeals.filter { id in
            viewModel.mealWindows.first(where: { $0.id == id }) == window
        }
    }
}
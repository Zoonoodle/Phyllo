//
//  SimpleTimelineView.swift
//  NutriSync
//
//  A simplified timeline view that correctly positions windows
//

import SwiftUI

struct SimpleTimelineView: View {
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    @State private var showJumpToNowButton = true  // Always show for now, TODO: detect scroll position
    @State private var scrollViewProxy: ScrollViewProxy?
    
    // Dynamic layout manager for content-based heights
    @StateObject private var layoutManager = TimelineLayoutManager()
    @State private var calculatedHourLayouts: [TimelineLayoutManager.HourLayout] = []
    @State private var calculatedWindowLayouts: [TimelineLayoutManager.WindowLayout] = []
    
    // Get the hours to display
    private var hours: [Int] {
        viewModel.timelineHours
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottom) {
                timelineContent
                    .onAppear {
                        scrollViewProxy = proxy
                        updateLayouts()
                        scrollToCurrentTimeOrFirstWindow(proxy: proxy)
                    }
                    .onChange(of: viewModel.mealWindows.count) { _, _ in
                        updateLayouts()
                    }
                    .onChange(of: viewModel.todaysMeals.count) { _, _ in
                        updateLayouts()
                    }
                    .onChange(of: viewModel.analyzingMeals.count) { _, _ in
                        updateLayouts()
                    }
                    .onReceive(timer) { _ in
                        currentTime = Date()
                    }
                
                // Jump to Now button
                if showJumpToNowButton {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scrollToCurrentTime(proxy: proxy)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 14))
                            Text("Now")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.nutriSyncAccent)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.bottom, 20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
    }
    
    // Separate timeline content into its own computed property
    @ViewBuilder
    private var timelineContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            timelineHours
                .overlay(alignment: .topLeading) {
                    overlayContent
                }
        }
    }
    
    // Hour rows as separate computed property
    @ViewBuilder
    private var timelineHours: some View {
        VStack(spacing: 0) {
            ForEach(calculatedHourLayouts, id: \.hour) { hourLayout in
                HourRowView(
                    hour: hourLayout.hour,
                    height: hourLayout.height,
                    currentTime: currentTime
                )
                .frame(height: hourLayout.height)
                .id("hour-\(hourLayout.hour)")
            }
        }
    }
    
    // Overlay content as separate computed property
    @ViewBuilder
    private var overlayContent: some View {
        ZStack(alignment: .topLeading) {
            CurrentTimeIndicatorDynamic(
                hourLayouts: calculatedHourLayouts,
                windowLayouts: calculatedWindowLayouts,
                currentTime: currentTime
            )
            
            WindowsOverlayDynamic(
                windowLayouts: calculatedWindowLayouts,
                viewModel: viewModel,
                selectedWindow: $selectedWindow,
                showWindowDetail: $showWindowDetail,
                animationNamespace: animationNamespace
            )
        }
    }
    
    // Update layouts when data changes
    private func updateLayouts() {
        let layouts = layoutManager.calculateLayouts(
            for: viewModel.mealWindows,
            hours: hours,
            viewModel: viewModel
        )
        
        calculatedHourLayouts = layouts.hours
        calculatedWindowLayouts = layouts.windows
    }
    
    private func scrollToCurrentTimeOrFirstWindow(proxy: ScrollViewProxy) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Always scroll to current time if it's within our timeline hours
        if hours.contains(currentHour) {
            // Calculate the anchor position based on how far through the hour we are
            // This provides more accurate positioning than just using .top or .center
            let minuteProgress = CGFloat(currentMinute) / 60.0
            let anchor: UnitPoint = UnitPoint(x: 0.5, y: 0.3 - (minuteProgress * 0.15))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("hour-\(currentHour)", anchor: anchor)
                }
            }
        } else if let firstWindow = viewModel.mealWindows.first {
            // Fallback: If current time is not in timeline, scroll to first window
            let windowHour = calendar.component(.hour, from: firstWindow.startTime)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo("hour-\(windowHour)", anchor: .top)
                }
            }
        }
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Only scroll if current time is within our timeline hours
        if hours.contains(currentHour) {
            // Calculate the anchor position based on how far through the hour we are
            let minuteProgress = CGFloat(currentMinute) / 60.0
            let anchor: UnitPoint = UnitPoint(x: 0.5, y: 0.3 - (minuteProgress * 0.15))
            
            proxy.scrollTo("hour-\(currentHour)", anchor: anchor)
            
            // Hide the button after scrolling
            withAnimation(.easeOut(duration: 0.3).delay(0.5)) {
                showJumpToNowButton = false
            }
        }
    }
}

// Enhanced hour row with current time highlight
struct HourRowView: View {
    let hour: Int
    let height: CGFloat
    let currentTime: Date
    
    private var isCurrentHour: Bool {
        Calendar.current.component(.hour, from: currentTime) == hour
    }
    
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
    
    // Check if this is a new day marker (for schedules crossing midnight)
    private var isNewDay: Bool {
        // If this is midnight and there are previous hours > 12, we crossed midnight
        if hour == 0 {
            return true // Always show midnight as new day
        }
        return false
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Show "Next Day" indicator if this is midnight
            if isNewDay {
                HStack {
                    Text("— Next Day —")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.vertical, 4)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.leading, 48)
            }
            
            HStack(alignment: .top, spacing: 12) {
                // Time label
                Text(timeString)
                    .font(isCurrentHour ? TimelineTypography.hourLabelCurrent : TimelineTypography.hourLabel)
                    .foregroundColor(isCurrentHour ? .white.opacity(TimelineOpacity.currentHour) : .white.opacity(TimelineOpacity.otherHour))
                    .frame(width: 48, alignment: .leading)
                    .padding(.top, -8)
                
                // Hour divider line
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.white.opacity(isCurrentHour ? 0.12 : 0.08))
                        .frame(height: 1)
                    
                    Spacer()
                }
                .frame(height: height)
            }
            .frame(height: height)
            .padding(.horizontal)
        }
    }
}

// Current time indicator with dynamic heights
struct CurrentTimeIndicatorDynamic: View {
    let hourLayouts: [TimelineLayoutManager.HourLayout]
    let windowLayouts: [TimelineLayoutManager.WindowLayout]
    let currentTime: Date
    
    private var currentOffset: CGFloat {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        guard let hourLayout = hourLayouts.first(where: { $0.hour == currentHour }) else { return 0 }
        
        let minuteOffset = (CGFloat(currentMinute) / 60.0) * hourLayout.height
        return hourLayout.yOffset + minuteOffset
    }
    
    // Check if there's an active window at the current time
    private var hasActiveWindow: Bool {
        for layout in windowLayouts {
            let window = layout.window
            if currentTime >= window.startTime && currentTime <= window.endTime {
                return true
            }
        }
        return false
    }
    
    var body: some View {
        let currentHour = Calendar.current.component(.hour, from: currentTime)
        if hourLayouts.contains(where: { $0.hour == currentHour }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.green.opacity(0.5), radius: 3)
                
                // Only show the line and time label if there's no active window
                if !hasActiveWindow {
                    Rectangle()
                        .fill(Color.green.opacity(0.6))
                        .frame(height: 1)
                    
                    Text(formatCurrentTime())
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                }
            }
            .offset(x: 56, y: currentOffset)
            .animation(.linear(duration: 0.3), value: currentOffset)
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
}

// Keep original for backward compatibility
struct CurrentTimeIndicator: View {
    let hours: [Int]
    let hourHeight: CGFloat
    let currentTime: Date
    
    private var currentOffset: CGFloat {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        guard let hourIndex = hours.firstIndex(of: currentHour) else { return 0 }
        
        let hourOffset = CGFloat(hourIndex) * hourHeight
        let minuteOffset = (CGFloat(currentMinute) / 60.0) * hourHeight
        
        return hourOffset + minuteOffset
    }
    
    var body: some View {
        if hours.contains(Calendar.current.component(.hour, from: currentTime)) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: Color.green.opacity(0.5), radius: 3)
                
                Rectangle()
                    .fill(Color.green.opacity(0.6))
                    .frame(height: 1)
                
                Text(formatCurrentTime())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.8))
                    )
            }
            .offset(x: 56, y: currentOffset)
            .animation(.linear(duration: 0.3), value: currentOffset)
        }
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
}

// Dynamic overlay for windows using calculated layouts
struct WindowsOverlayDynamic: View {
    let windowLayouts: [TimelineLayoutManager.WindowLayout]
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(windowLayouts, id: \.window.id) { layout in
                ExpandableWindowBanner(
                    window: layout.window,
                    meals: viewModel.mealsInWindow(layout.window),
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail,
                    animationNamespace: animationNamespace,
                    viewModel: viewModel,
                    bannerHeight: layout.height
                )
                .frame(width: geometry.size.width - 95)
                .offset(x: 68, y: layout.yPosition)
            }
        }
    }
}

// Keep original overlay for backward compatibility  
struct WindowsOverlay: View {
    let windows: [MealWindow]
    let hours: [Int]
    let hourHeight: CGFloat
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(windows) { window in
                WindowBannerView(
                    window: window,
                    viewModel: viewModel,
                    selectedWindow: $selectedWindow,
                    showWindowDetail: $showWindowDetail,
                    animationNamespace: animationNamespace
                )
                .frame(width: geometry.size.width - 95) // Consistent width with proper padding
                .offset(x: 68, y: calculateWindowOffset(for: window))
            }
        }
    }
    
    private func calculateWindowOffset(for window: MealWindow) -> CGFloat {
        let calendar = Calendar.current
        
        // Get window start time components
        let windowHour = calendar.component(.hour, from: window.startTime)
        let windowMinute = calendar.component(.minute, from: window.startTime)
        
        // Find the index of this hour in our hours array
        guard let hourIndex = hours.firstIndex(of: windowHour) else {
            print("⚠️ Hour \(windowHour) not found in timeline hours: \(hours)")
            return 0
        }
        
        // Calculate offset
        let hourOffset = CGFloat(hourIndex) * hourHeight
        let minuteOffset = (CGFloat(windowMinute) / 60.0) * hourHeight
        
        return hourOffset + minuteOffset
    }
}

// Window banner wrapper that provides consistent sizing
struct WindowBannerView: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var selectedWindow: MealWindow?
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    
    private var windowHeight: CGFloat {
        // Scale height based on window duration while maintaining minimum visibility
        let duration = window.endTime.timeIntervalSince(window.startTime) / 3600.0 // Hours
        
        // Base height scaling: 
        // 30 min = 70px
        // 1 hour = 95px  
        // 1.5 hours = 120px
        // 2 hours = 145px
        let scaledHeight = 70 + (duration * 50)
        
        // Ensure minimum and maximum bounds
        return min(max(scaledHeight, 70), 180)  // Min 70px, max 180px
    }
    
    var body: some View {
        ExpandableWindowBanner(
            window: window,
            meals: viewModel.mealsInWindow(window),
            selectedWindow: $selectedWindow,
            showWindowDetail: $showWindowDetail,
            animationNamespace: animationNamespace,
            viewModel: viewModel,
            bannerHeight: windowHeight
        )
    }
}


#Preview {
    SimpleTimelineView(
        viewModel: ScheduleViewModel(),
        selectedWindow: .constant(nil),
        showWindowDetail: .constant(false),
        animationNamespace: Namespace().wrappedValue
    )
    .preferredColorScheme(.dark)
    .background(Color.black)
}
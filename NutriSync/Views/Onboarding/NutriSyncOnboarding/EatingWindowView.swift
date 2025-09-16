//
//  EatingWindowView.swift
//  NutriSync
//
//  Early vs late eating preference based on circadian science
//

import SwiftUI

struct EatingWindowView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedWindow: EatingWindow?
    
    enum EatingWindow: String, CaseIterable {
        case earlyBird = "earlyBird"
        case balanced = "balanced"
        case nightOwl = "nightOwl"
        
        var title: String {
            switch self {
            case .earlyBird: return "Early Bird"
            case .balanced: return "Balanced"
            case .nightOwl: return "Night Owl"
            }
        }
        
        var schedule: String {
            switch self {
            case .earlyBird: return "1-9 hours after waking"
            case .balanced: return "3-11 hours after waking"
            case .nightOwl: return "5-13 hours after waking"
            }
        }
        
        var description: String {
            switch self {
            case .earlyBird:
                return "Optimal for metabolism • Aligns with natural cortisol rhythm"
            case .balanced:
                return "Moderate approach • Good for most schedules"
            case .nightOwl:
                return "Accommodates late schedules • May impact sleep quality"
            }
        }
        
        var benefits: [String] {
            switch self {
            case .earlyBird:
                return [
                    "Better insulin sensitivity",
                    "Improved weight management",
                    "Enhanced sleep quality"
                ]
            case .balanced:
                return [
                    "Flexible scheduling",
                    "Social compatibility",
                    "Steady energy levels"
                ]
            case .nightOwl:
                return [
                    "Fits late work schedules",
                    "Social dinner flexibility",
                    "Extended morning fast"
                ]
            }
        }
        
        var icon: String {
            switch self {
            case .earlyBird: return "sunrise.fill"
            case .balanced: return "sun.max.fill"
            case .nightOwl: return "moon.stars.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .earlyBird: return .orange
            case .balanced: return .yellow
            case .nightOwl: return .purple
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    OnboardingSectionProgressBar()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Title
                    Text("When do you prefer to eat?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Subtitle
                    Text("Research shows that eating earlier in the day, when insulin sensitivity is highest, can improve metabolic health and weight management.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Visual timeline
                    CircadianTimelineView(selectedWindow: selectedWindow)
                        .padding(.bottom, 24)
                    
                    // Options
                    VStack(spacing: 16) {
                        ForEach(EatingWindow.allCases, id: \.self) { window in
                            EatingWindowCard(
                                window: window,
                                isSelected: selectedWindow == window,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedWindow = window
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 100)
                
                    // Navigation
                    HStack {
                        Button {
                            coordinator.previousScreen()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button {
                            // Save data to coordinator before proceeding
                            if let selected = selectedWindow {
                                coordinator.eatingWindow = selected.rawValue
                            }
                            
                            coordinator.nextScreen()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.nutriSyncBackground)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(selectedWindow != nil ? Color.white : Color.white.opacity(0.3))
                            .cornerRadius(22)
                        }
                        .disabled(selectedWindow == nil)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .padding(.top, 20)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Eating Window Card
struct EatingWindowCard: View {
    let window: EatingWindowView.EatingWindow
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 16) {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.white : Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                        }
                    }
                    
                    // Icon and title
                    HStack(spacing: 12) {
                        Image(systemName: window.icon)
                            .font(.system(size: 24))
                            .foregroundColor(window.iconColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(window.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(window.schedule)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                }
                
                // Description
                Text(window.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Benefits
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(window.benefits, id: \.self) { benefit in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.nutriSyncAccent)
                            
                            Text(benefit)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Circadian Timeline Visual
struct CircadianTimelineView: View {
    let selectedWindow: EatingWindowView.EatingWindow?
    
    var body: some View {
        VStack(spacing: 8) {
            // Relative time labels
            HStack {
                Text("Wake")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                Text("+4h")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Text("+8h")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Text("+12h")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                
                Spacer()
                
                Text("Sleep")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 24)
            
            // Timeline bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    // Eating window
                    if let window = selectedWindow {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nutriSyncAccent)
                            .frame(width: windowWidth(for: window, in: geometry.size.width), height: 8)
                            .offset(x: windowOffset(for: window, in: geometry.size.width))
                    }
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)
        }
    }
    
    private func windowWidth(for window: EatingWindowView.EatingWindow, in totalWidth: CGFloat) -> CGFloat {
        // 8 hours of 16 hour awake display
        return totalWidth * (8.0 / 16.0)
    }
    
    private func windowOffset(for window: EatingWindowView.EatingWindow, in totalWidth: CGFloat) -> CGFloat {
        let hourWidth = totalWidth / 16.0
        
        switch window {
        case .earlyBird: return hourWidth * 1   // 1 hour after wake
        case .balanced: return hourWidth * 3    // 3 hours after wake
        case .nightOwl: return hourWidth * 5    // 5 hours after wake
        }
    }
    
    private func windowDescription(for window: EatingWindowView.EatingWindow) -> String {
        switch window {
        case .earlyBird:
            return "Start eating 1 hour after waking • 8-hour window"
        case .balanced:
            return "Start eating 3 hours after waking • 8-hour window"
        case .nightOwl:
            return "Start eating 5 hours after waking • 8-hour window"
        }
    }
}
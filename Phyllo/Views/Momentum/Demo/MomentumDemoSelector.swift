//
//  MomentumDemoSelector.swift
//  Phyllo - Momentum Redesign Demo
//
//  Created on 1/31/25.
//
//  This view allows easy switching between different Momentum tab
//  redesign iterations for comparison and testing.
//

import SwiftUI

struct MomentumDemoSelector: View {
    @Binding var showDeveloperDashboard: Bool
    @State private var selectedVersion: DemoVersion = .current
    @State private var showComparison = false
    
    enum DemoVersion: String, CaseIterable {
        case current = "Current Design"
        case v1Journey = "V1: Journey Timeline"
        case v2DataStory = "V2: Data Story"
        case v3Interactive = "V3: Interactive Insights"
        
        var description: String {
            switch self {
            case .current:
                return "The existing 4-card grid layout with social features"
            case .v1Journey:
                return "Horizontal timeline showing nutrition journey with predictive insights"
            case .v2DataStory:
                return "Chapter-based storytelling through data visualization"
            case .v3Interactive:
                return "Interactive charts with gestures, filters, and AI assistant"
            }
        }
        
        var icon: String {
            switch self {
            case .current: return "square.grid.2x2.fill"
            case .v1Journey: return "timeline.selection"
            case .v2DataStory: return "book.pages.fill"
            case .v3Interactive: return "hand.tap.fill"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .current: return .gray
            case .v1Journey: return .blue
            case .v2DataStory: return .purple
            case .v3Interactive: return .orange
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground.ignoresSafeArea()
                
                if showComparison {
                    // Comparison mode - show side by side
                    ComparisonView(
                        showDeveloperDashboard: $showDeveloperDashboard,
                        onClose: {
                            withAnimation(.spring(response: 0.5)) {
                                showComparison = false
                            }
                        }
                    )
                } else {
                    // Selection mode
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Momentum Redesign")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Choose a design iteration to explore")
                                    .font(.system(size: 18))
                                    .foregroundColor(.phylloTextSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showDeveloperDashboard = true
                            }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.phylloTextSecondary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.phylloElevated)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 60)
                        .padding(.bottom, 32)
                        
                        // Version selector
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(DemoVersion.allCases, id: \.self) { version in
                                    VersionCard(
                                        version: version,
                                        isSelected: selectedVersion == version,
                                        action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedVersion = version
                                            }
                                        }
                                    )
                                }
                                
                                // Comparison button
                                Button(action: {
                                    withAnimation(.spring(response: 0.5)) {
                                        showComparison = true
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "square.split.2x1.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.phylloAccent)
                                        
                                        Text("Compare Designs Side by Side")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.phylloTextTertiary)
                                    }
                                    .padding(24)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.phylloAccent.opacity(0.2), Color.phylloAccent.opacity(0.05)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.phylloAccent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.top, 20)
                                
                                // Launch button
                                Button(action: {
                                    // This would navigate to the selected version
                                    // Implementation depends on your navigation setup
                                }) {
                                    HStack {
                                        Text("Launch \(selectedVersion.rawValue)")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.phylloAccent)
                                    .cornerRadius(16)
                                }
                                .padding(.top, 32)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: .constant(selectedVersion != .current)) {
            // Show selected version
            Group {
                switch selectedVersion {
                case .current:
                    MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
                case .v1Journey:
                    JourneyTimelineView(showDeveloperDashboard: $showDeveloperDashboard)
                case .v2DataStory:
                    DataStoryView(showDeveloperDashboard: $showDeveloperDashboard)
                case .v3Interactive:
                    InteractiveInsightsView(showDeveloperDashboard: $showDeveloperDashboard)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
            .overlay(alignment: .topTrailing) {
                // Close button
                Button(action: {
                    selectedVersion = .current
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.phylloTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.phylloElevated)
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }
}

struct VersionCard: View {
    let version: MomentumDemoSelector.DemoVersion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(version.accentColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: version.icon)
                        .font(.system(size: 28))
                        .foregroundColor(version.accentColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(version.rawValue)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(version.description)
                        .font(.system(size: 14))
                        .foregroundColor(.phylloTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? version.accentColor : .phylloTextTertiary)
            }
            .padding(20)
            .background(Color.phylloElevated)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? version.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .cornerRadius(20)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComparisonView: View {
    @Binding var showDeveloperDashboard: Bool
    let onClose: () -> Void
    @State private var leftVersion: MomentumDemoSelector.DemoVersion = .current
    @State private var rightVersion: MomentumDemoSelector.DemoVersion = .v1Journey
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compare Designs")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.phylloTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.phylloElevated)
                        .clipShape(Circle())
                }
            }
            .padding()
            
            // Version selectors
            HStack(spacing: 16) {
                VersionPicker(
                    title: "Left Side",
                    selected: $leftVersion,
                    exclude: rightVersion
                )
                
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 20))
                    .foregroundColor(.phylloTextTertiary)
                
                VersionPicker(
                    title: "Right Side",
                    selected: $rightVersion,
                    exclude: leftVersion
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Split view
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left view
                    ViewContainer(version: leftVersion, showDeveloperDashboard: $showDeveloperDashboard)
                        .frame(width: geometry.size.width / 2)
                        .clipped()
                    
                    // Divider
                    Rectangle()
                        .fill(Color.phylloTextTertiary.opacity(0.3))
                        .frame(width: 1)
                    
                    // Right view
                    ViewContainer(version: rightVersion, showDeveloperDashboard: $showDeveloperDashboard)
                        .frame(width: geometry.size.width / 2)
                        .clipped()
                }
            }
        }
        .background(Color.phylloBackground)
    }
}

struct VersionPicker: View {
    let title: String
    @Binding var selected: MomentumDemoSelector.DemoVersion
    let exclude: MomentumDemoSelector.DemoVersion
    
    var availableVersions: [MomentumDemoSelector.DemoVersion] {
        MomentumDemoSelector.DemoVersion.allCases.filter { $0 != exclude }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.phylloTextTertiary)
            
            Menu {
                ForEach(availableVersions, id: \.self) { version in
                    Button(action: {
                        selected = version
                    }) {
                        Label(version.rawValue, systemImage: version.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selected.icon)
                        .font(.system(size: 16))
                        .foregroundColor(selected.accentColor)
                    
                    Text(selected.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.phylloTextTertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.phylloElevated)
                .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ViewContainer: View {
    let version: MomentumDemoSelector.DemoVersion
    @Binding var showDeveloperDashboard: Bool
    
    var body: some View {
        Group {
            switch version {
            case .current:
                MomentumTabView(showDeveloperDashboard: $showDeveloperDashboard)
            case .v1Journey:
                JourneyTimelineView(showDeveloperDashboard: $showDeveloperDashboard)
            case .v2DataStory:
                DataStoryView(showDeveloperDashboard: $showDeveloperDashboard)
            case .v3Interactive:
                InteractiveInsightsView(showDeveloperDashboard: $showDeveloperDashboard)
            }
        }
        .scaleEffect(0.5)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phylloBackground)
    }
}

#Preview {
    @Previewable @State var showDeveloperDashboard = false
    MomentumDemoSelector(showDeveloperDashboard: $showDeveloperDashboard)
        .preferredColorScheme(.dark)
}
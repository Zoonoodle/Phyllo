//
//  FloatingTabBar.swift
//  Phyllo
//
//  Created on 7/30/25.
//

import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        FloatingTabItem(icon: "calendar", selectedIcon: "calendar", label: "Schedule"),
        FloatingTabItem(icon: "plus", selectedIcon: "plus", label: "Scan", isAccent: true),
        FloatingTabItem(icon: "chart.line.uptrend.xyaxis", selectedIcon: "chart.line.uptrend.xyaxis", label: "Insights")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                if tabs[index].isAccent {
                    // Special scan button in the middle
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        selectedTab = index
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 56, height: 56)
                                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: tabs[index].icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .offset(y: -8) // Lift the scan button slightly
                } else {
                    // Regular tab buttons
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedTab = index
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == index ? .white : .gray)
                                .frame(height: 24)
                            
                            if selectedTab == index {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 4, height: 4)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .padding(.bottom, 8) // Extra padding for home indicator
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.9)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
    }
}

// Custom tab item for floating bar
struct FloatingTabItem {
    let icon: String
    let selectedIcon: String
    let label: String
    let isAccent: Bool
    
    init(icon: String, selectedIcon: String, label: String, isAccent: Bool = false) {
        self.icon = icon
        self.selectedIcon = selectedIcon
        self.label = label
        self.isAccent = isAccent
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            FloatingTabBar(selectedTab: .constant(0))
        }
    }
}
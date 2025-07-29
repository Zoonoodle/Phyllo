//
//  CustomTabBar.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        TabItem(icon: "calendar", selectedIcon: "calendar", label: "Schedule"),
        TabItem(icon: "chart.line.uptrend.xyaxis", selectedIcon: "chart.line.uptrend.xyaxis", label: "Insights"),
        TabItem(icon: "camera", selectedIcon: "camera.fill", label: "Scan")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Separation line
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
            
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    TabBarButton(
                        tab: tabs[index],
                        isSelected: selectedTab == index,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedTab = index
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 2)
            .padding(.bottom, 16) // Account for home indicator
            .background(
                Color(red: 0.07, green: 0.07, blue: 0.07) // Solid dark background
            )
        }
    }
}

struct TabItem {
    let icon: String
    let selectedIcon: String
    let label: String
}

struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    .frame(width: 30, height: 30)
                
                Text(tab.label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    .fixedSize()
            }
            .padding(.vertical, 4)
            .frame(minWidth: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(0))
        }
    }
}
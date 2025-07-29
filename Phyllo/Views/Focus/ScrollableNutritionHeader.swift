//
//  ScrollableNutritionHeader.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct ScrollableNutritionHeader: View {
    let window: MealWindow
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $currentPage) {
                MacroNutritionPage(window: window)
                    .tag(0)
                
                MicroNutritionPage(window: window)
                    .tag(1)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 320)
            .frame(maxWidth: .infinity)
            
            // Custom page indicator
            HStack(spacing: 8) {
                ForEach(0..<2) { index in
                    Circle()
                        .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.phylloBorder, lineWidth: 1)
                )
        )
        .onAppear {
            // Add haptic feedback when swiping
            UIImpactFeedbackGenerator(style: .light).prepare()
        }
        .onChange(of: currentPage) { _ in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        ScrollableNutritionHeader(window: MockDataManager.shared.mealWindows[0])
            .padding()
    }
    .onAppear {
        MockDataManager.shared.completeMorningCheckIn()
        MockDataManager.shared.simulateTime(hour: 12)
    }
}
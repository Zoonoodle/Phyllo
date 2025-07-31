//
//  ScrollableNutritionHeader.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct ScrollableNutritionHeader: View {
    let window: MealWindow
    @Binding var currentPage: Int
    
    var body: some View {
        TabView(selection: $currentPage) {
            MacroNutritionPage(window: window)
                .tag(0)
            
            MicroNutritionPage(window: window)
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .clipped() // Prevent content from extending beyond bounds
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.phylloBorder, lineWidth: 1)
                )
        )
        .clipped() // Also clip the entire component
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
    @Previewable @State var currentPage = 0
    
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        ScrollableNutritionHeader(window: MockDataManager.shared.mealWindows[0], currentPage: $currentPage)
            .padding()
    }
    .onAppear {
        MockDataManager.shared.completeMorningCheckIn()
        MockDataManager.shared.simulateTime(hour: 12)
    }
}
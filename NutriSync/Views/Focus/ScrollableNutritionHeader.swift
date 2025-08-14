//
//  ScrollableNutritionHeader.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct ScrollableNutritionHeader: View {
    let window: MealWindow
    @Binding var currentPage: Int
    @ObservedObject var viewModel: ScheduleViewModel
    
    var body: some View {
        TabView(selection: $currentPage) {
            MacroNutritionPage(window: window, viewModel: viewModel)
                .tag(0)
            
            MicroNutritionPage(window: window, viewModel: viewModel)
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
                        .strokeBorder(Color.nutriSyncBorder, lineWidth: 1)
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
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        if let window = viewModel.mealWindows.first {
            ScrollableNutritionHeader(
                window: window,
                currentPage: $currentPage,
                viewModel: viewModel
            )
            .padding()
        }
    }
}
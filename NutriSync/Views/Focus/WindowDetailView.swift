//
//  WindowDetailView.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowDetailView: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Scrollable nutrition header
                        ScrollableNutritionHeader(window: window, currentPage: $currentPage, viewModel: viewModel)
                        
                        // Custom page indicator
                        HStack(spacing: 8) {
                            ForEach(0..<2) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                            }
                        }
                        .padding(.top, -8) // Reduce spacing between card and indicator
                        
                        // Logged foods section
                        WindowFoodsList(window: window, selectedMealId: .constant(nil), viewModel: viewModel)
                        
                        // Window purpose section
                        WindowPurposeCard(window: window)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 10) // Increased padding to avoid Dynamic Island/notch
                    .padding(.horizontal, 32) // Add consistent horizontal padding to entire content
                }
            }
            .navigationTitle(windowTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            // Edit window action
                        } label: {
                            Label("Edit Window", systemImage: "pencil")
                        }
                        
                        Button {
                            // Skip window action
                        } label: {
                            Label("Skip Window", systemImage: "forward.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.nutriSyncBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var windowTitle: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        
        switch hour {
        case 5...10:
            return "Breakfast Window"
        case 11...14:
            return "Lunch Window"
        case 15...17:
            return "Snack Window"
        case 18...21:
            return "Dinner Window"
        default:
            return "Late Snack Window"
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    if let window = viewModel.mealWindows.first {
        WindowDetailView(window: window, viewModel: viewModel)
    }
}

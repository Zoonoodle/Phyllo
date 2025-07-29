//
//  WindowDetailView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowDetailView: View {
    let window: MealWindow
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mockData = MockDataManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.phylloBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Scrollable nutrition header
                        ScrollableNutritionHeader(window: window)
                            .padding(.horizontal)
                        
                        // Logged foods section
                        WindowFoodsList(window: window)
                            .padding(.horizontal)
                        
                        // Window purpose section
                        WindowPurposeCard(window: window)
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                    }
                    .padding(.top)
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
            .toolbarBackground(Color.phylloBackground, for: .navigationBar)
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
    WindowDetailView(window: MockDataManager.shared.mealWindows[0])
        .onAppear {
            MockDataManager.shared.completeMorningCheckIn()
            MockDataManager.shared.simulateTime(hour: 12)
        }
}
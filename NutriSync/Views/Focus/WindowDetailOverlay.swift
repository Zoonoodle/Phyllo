//
//  WindowDetailOverlay.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowDetailOverlay: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var showWindowDetail: Bool
    @Binding var selectedMealId: String?
    let animationNamespace: Namespace.ID
    @State private var animateContent = false
    @State private var currentPage = 0
    @State private var showEditWindow = false
    
    var body: some View {
        ZStack {
            // Background
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Add extra padding for Dynamic Island/notch
                Color.clear
                    .frame(height: 50) // Space for Dynamic Island
                
                // Custom navigation bar
                customNavigationBar
                    .padding(.top, 8)  // Small additional padding below Dynamic Island
                    .background(Color.nutriSyncBackground)
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Scrollable nutrition header
                        ScrollableNutritionHeader(window: window, currentPage: $currentPage, viewModel: viewModel)
                            .padding(.horizontal, 16)
                        
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
                        WindowFoodsList(window: window, selectedMealId: $selectedMealId, viewModel: viewModel)
                            .padding(.horizontal, 16)
                        
                        // Window purpose section
                        WindowPurposeCard(window: window)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .opacity(animateContent ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showEditWindow) {
            EditWindowView(window: window, viewModel: viewModel)
        }
    }
    
    private var customNavigationBar: some View {
        HStack {
            // Back button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showWindowDetail = false
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                    Text("Back")
                        .font(.system(size: 16))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle()) // Ensure button is tappable
            
            Spacer()
            
            // Centered title
            Text(windowTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Menu button
            Menu {
                Button {
                    showEditWindow = true
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
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
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
    WindowDetailOverlay(
        window: MealWindow.mockWindows(for: .performanceFocus).first!,
        viewModel: ScheduleViewModel(),
        showWindowDetail: .constant(true),
        selectedMealId: .constant(nil),
        animationNamespace: Namespace().wrappedValue
    )
}
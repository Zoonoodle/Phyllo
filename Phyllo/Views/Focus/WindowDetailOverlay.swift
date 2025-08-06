//
//  WindowDetailOverlay.swift
//  Phyllo
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background that expands from banner
                RoundedRectangle(cornerRadius: animateContent ? 0 : 16)
                    .fill(Color.phylloBackground)
                    .matchedGeometryEffect(
                        id: "window-\(window.id)",
                        in: animationNamespace,
                        properties: .frame,
                        isSource: false
                    )
                    .ignoresSafeArea(edges: animateContent ? .all : [])
                
                // Content
                VStack(spacing: 0) {
                // Safe area padding at top
                Color.phylloBackground
                    .frame(height: 60)
                    .ignoresSafeArea()
                
                // Custom header with back button, title, and menu
                HStack {
                    // Back button
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            animateContent = false
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
                    
                    Spacer()
                    
                    // Centered title
                    Text(windowTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    // Menu button
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
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(Color.phylloBackground)
                .opacity(animateContent ? 1 : 0)
                
                // Window detail content
                ScrollView {
                    VStack(spacing: 24) {
                        // Scrollable nutrition header
                        ScrollableNutritionHeader(window: window, currentPage: $currentPage, viewModel: viewModel)
                            .padding(.horizontal, 32)
                        
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
                            .padding(.horizontal, 32)
                        
                        // Window purpose section
                        WindowPurposeCard(window: window)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                    }
                    .padding(.top)
                    .frame(maxWidth: geometry.size.width)
                }
                .opacity(animateContent ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
                animateContent = true
            }
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
    WindowDetailOverlay(
        window: MealWindow.mockWindows(for: .performanceFocus).first!,
        viewModel: ScheduleViewModel(),
        showWindowDetail: .constant(true),
        selectedMealId: .constant(nil),
        animationNamespace: Namespace().wrappedValue
    )
}
//
//  WindowDetailOverlay.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct WindowDetailOverlay: View {
    let window: MealWindow
    @Binding var showWindowDetail: Bool
    let animationNamespace: Namespace.ID
    @State private var animateContent = false
    
    var body: some View {
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
                // Custom header with back button
                HStack {
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
                    
                    Text(windowTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
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
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
                .background(Color.phylloBackground)
                .opacity(animateContent ? 1 : 0)
                
                // Window detail content
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
                .opacity(animateContent ? 1 : 0)
            }
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
        window: MockDataManager.shared.mealWindows[0],
        showWindowDetail: .constant(true),
        animationNamespace: Namespace().wrappedValue
    )
    .onAppear {
        MockDataManager.shared.completeMorningCheckIn()
        MockDataManager.shared.simulateTime(hour: 12)
    }
}
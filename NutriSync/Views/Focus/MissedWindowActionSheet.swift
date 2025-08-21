//
//  MissedWindowActionSheet.swift
//  NutriSync
//
//  Created on 8/20/25.
//

import SwiftUI

struct MissedWindowActionSheet: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    @Binding var isPresented: Bool
    @Binding var showSimplifiedMealLogging: Bool
    @Binding var selectedMissedWindow: MealWindow?
    
    @State private var isProcessingFasting = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)
            
            // Title
            VStack(spacing: 4) {
                Text("Missed \(windowTitle)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(formatTimeRange(start: window.startTime, end: window.endTime))")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 24)
            
            // Action buttons
            VStack(spacing: 12) {
                // Log meal button
                Button(action: {
                    selectedMissedWindow = window
                    showSimplifiedMealLogging = true
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16))
                        Text("Log meal for this window")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.nutriSyncAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Mark as fasted button
                Button(action: {
                    Task {
                        isProcessingFasting = true
                        await viewModel.markWindowAsFasted(windowId: window.id)
                        isProcessingFasting = false
                        isPresented = false
                    }
                }) {
                    HStack {
                        if isProcessingFasting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "moon.fill")
                                .font(.system(size: 16))
                        }
                        Text("I was fasting")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessingFasting)
                
                // Cancel button
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(Color.nutriSyncElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 16)
    }
    
    private var windowTitle: String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "Breakfast"
        case 11...12: return "Brunch"
        case 13...15: return "Lunch"
        case 16...17: return "Snack"
        case 18...21: return "Dinner"
        default: return "Snack"
        }
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        let startHour = calendar.component(.hour, from: start)
        let endHour = calendar.component(.hour, from: end)
        let sameAMPM = (startHour < 12 && endHour < 12) || (startHour >= 12 && endHour >= 12)
        
        if sameAMPM {
            formatter.dateFormat = "h:mm"
            let startTime = formatter.string(from: start)
            formatter.dateFormat = "h:mm a"
            let endTime = formatter.string(from: end)
            return "\(startTime) - \(endTime)"
        } else {
            formatter.dateFormat = "h:mm a"
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var showSimplifiedMealLogging = false
    @Previewable @State var selectedMissedWindow: MealWindow?
    @Previewable @StateObject var viewModel = ScheduleViewModel()
    
    ZStack {
        Color.nutriSyncBackground.ignoresSafeArea()
        
        if let window = viewModel.mealWindows.first {
            MissedWindowActionSheet(
                window: window,
                viewModel: viewModel,
                isPresented: $isPresented,
                showSimplifiedMealLogging: $showSimplifiedMealLogging,
                selectedMissedWindow: $selectedMissedWindow
            )
        }
    }
}
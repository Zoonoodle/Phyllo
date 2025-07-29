//
//  CheckInDemoView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct CheckInDemoView: View {
    @State private var showMorningCheckIn = false
    @State private var showPostMealCheckIn = false
    @State private var selectedMeal = "Breakfast Bowl"
    
    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Check-In Demos")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Test the morning and post-meal check-in flows")
                        .font(.system(size: 16))
                        .foregroundColor(.phylloTextSecondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Demo buttons
                VStack(spacing: 20) {
                    // Morning check-in card
                    Button(action: { showMorningCheckIn = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "sun.horizon.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.phylloAccent)
                                    
                                    Text("Morning Check-In")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Sleep quality, day focus, and mood")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16))
                                .foregroundColor(.phylloTextSecondary)
                        }
                        .padding(24)
                        .background(Color.phylloElevated)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.phylloBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Post-meal check-in card
                    Button(action: { showPostMealCheckIn = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "fork.knife.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.phylloAccent)
                                    
                                    Text("Post-Meal Check-In")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Energy, fullness, and mood tracking")
                                    .font(.system(size: 14))
                                    .foregroundColor(.phylloTextSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16))
                                .foregroundColor(.phylloTextSecondary)
                        }
                        .padding(24)
                        .background(Color.phylloElevated)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.phylloBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Check-in status
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.phylloAccent)
                            
                            Text("Check-In Status")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            StatusRow(
                                icon: "sunrise.fill",
                                label: "Morning Check-In",
                                status: CheckInManager.shared.hasCompletedMorningCheckIn ? "Completed" : "Pending",
                                isCompleted: CheckInManager.shared.hasCompletedMorningCheckIn
                            )
                            
                            StatusRow(
                                icon: "fork.knife",
                                label: "Pending Meal Check-Ins",
                                status: "\(CheckInManager.shared.pendingPostMealCheckIns.count)",
                                isCompleted: CheckInManager.shared.pendingPostMealCheckIns.isEmpty
                            )
                        }
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showMorningCheckIn) {
            MorningCheckInView()
        }
        .sheet(isPresented: $showPostMealCheckIn) {
            PostMealCheckInView(
                mealId: "demo-meal",
                mealName: selectedMeal
            )
        }
    }
}

// MARK: - Status Row
struct StatusRow: View {
    let icon: String
    let label: String
    let status: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isCompleted ? .phylloAccent : .phylloTextTertiary)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.phylloTextSecondary)
            
            Spacer()
            
            Text(status)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isCompleted ? .phylloAccent : .white)
        }
    }
}

#Preview {
    CheckInDemoView()
        .preferredColorScheme(.dark)
}
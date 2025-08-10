//
//  NoWindowsView.swift
//  Phyllo
//
//  Created on 8/10/25.
//

import SwiftUI

struct NoWindowsView: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @State private var showMorningCheckIn = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: "sun.max.fill")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(.phylloAccent.opacity(0.8))
                .padding(.top, 60)
            
            VStack(spacing: 16) {
                Text("Start Your Day")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Complete your morning check-in to generate today's personalized meal schedule")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            
            // Check-in button
            Button(action: {
                showMorningCheckIn = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Complete Morning Check-In")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.phylloAccent)
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            
            // Info cards
            VStack(spacing: 12) {
                CheckInInfoCard(
                    icon: "clock.fill",
                    title: "Personalized Timing",
                    description: "Meal windows adapt to your wake time and daily schedule"
                )
                
                CheckInInfoCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Smart Nutrition",
                    description: "Calorie and macro targets calculated for your goals"
                )
                
                CheckInInfoCard(
                    icon: "moon.stars.fill",
                    title: "Better Recovery",
                    description: "Optimal meal timing for energy and sleep quality"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phylloBackground)
        .sheet(isPresented: $showMorningCheckIn) {
            MorningCheckInView()
        }
    }
}

struct CheckInInfoCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.phylloAccent)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

#Preview {
    NoWindowsView()
        .preferredColorScheme(.dark)
}
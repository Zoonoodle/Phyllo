//
//  NoWindowsView.swift
//  NutriSync
//
//  Created on 8/10/25.
//

import SwiftUI

struct NoWindowsView: View {
    @StateObject private var nudgeManager = NudgeManager.shared
    @State private var showMorningCheckIn = false
    @State private var showContent = false
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Welcome text at top
            VStack(spacing: 16) {
                Text("Good morning!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(animateText ? 1.0 : 0)
                    .offset(y: animateText ? 0 : 20)
                
                Text("Let's start your day with a quick check-\nin to optimize your nutrition plan.")
                    .font(.system(size: 16))
                    .foregroundColor(.nutriSyncTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(animateText ? 1.0 : 0)
                    .offset(y: animateText ? 0 : 20)
            }
            .padding(.horizontal, 32)
            .padding(.top, 60)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: animateText)
            
            Spacer()
            
            // Coffee steam animation in center
            CoffeeSteamAnimation()
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showContent)
            
            Spacer()
            
            // Bottom section
            VStack(spacing: 40) {
                // Text under coffee
                Text("Takes less than 15 seconds")
                    .font(.system(size: 14))
                    .foregroundColor(.nutriSyncTextTertiary)
                    .opacity(animateText ? 1.0 : 0)
                
                // Continue button aligned to right
                HStack {
                    Spacer()
                    Button(action: {
                        showMorningCheckIn = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                    .opacity(animateText ? 1.0 : 0)
                    .scaleEffect(animateText ? 1.0 : 0.8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: animateText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nutriSyncBackground)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
                animateText = true
            }
        }
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
                .foregroundColor(.nutriSyncAccent)
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
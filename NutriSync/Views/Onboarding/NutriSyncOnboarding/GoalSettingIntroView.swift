//
//  GoalSettingIntroView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 8 - Dark Theme
//

import SwiftUI

struct GoalSettingIntroView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Title
            HStack {
                Text("Goal Setting")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 32)
            
            // Progress icons
            HStack(spacing: 0) {
                // Profile icon
                ProgressIcon(icon: "person.fill", isActive: true, isCompleted: true)
                    .overlay(
                        Image(systemName: "line.diagonal")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .rotationEffect(.degrees(-45))
                            .offset(x: 12, y: -8),
                        alignment: .topTrailing
                    )
                
                ProgressLine(isActive: true)
                
                // Shield icon
                ProgressIcon(icon: "shield.fill", isActive: true, isCompleted: true)
                    .overlay(
                        Image(systemName: "line.diagonal")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .rotationEffect(.degrees(-45))
                            .offset(x: 12, y: -8),
                        alignment: .topTrailing
                    )
                
                ProgressLine(isActive: true)
                
                // Target icon (current)
                ProgressIcon(icon: "target", isActive: true, isCompleted: false)
                
                ProgressLine(isActive: false)
                
                // Graph icon
                ProgressIcon(icon: "chart.line.uptrend.xyaxis", isActive: false, isCompleted: false)
                
                ProgressLine(isActive: false)
                
                // Food icon
                ProgressIcon(icon: "fork.knife", isActive: false, isCompleted: false)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
            
            // Content
            VStack(alignment: .leading, spacing: 24) {
                Text("Goal")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("NutriSync's personalized windows are designed to optimize your nutrition timing. Don't worry – you can update your goal any time.")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            Button {
                coordinator.nextScreen()
            } label: {
                Text("Go to Goal Setup")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.nutriSyncBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
}

struct GoalSettingIntroView_Previews: PreviewProvider {
    static var previews: some View {
        GoalSettingIntroView()
    }
}
//
//  AlmostThereView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 12 - Dark Theme
//

import SwiftUI

struct AlmostThereView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Title
            HStack {
                Text("Almost There")
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
                
                // Target icon
                ProgressIcon(icon: "target", isActive: true, isCompleted: true)
                    .overlay(
                        Image(systemName: "line.diagonal")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .rotationEffect(.degrees(-45))
                            .offset(x: 12, y: -8),
                        alignment: .topTrailing
                    )
                
                ProgressLine(isActive: true)
                
                // Graph icon (current)
                ProgressIcon(icon: "chart.line.uptrend.xyaxis", isActive: true, isCompleted: false)
                
                ProgressLine(isActive: false)
                
                // Food icon
                ProgressIcon(icon: "fork.knife", isActive: false, isCompleted: false)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
            
            // Content
            VStack(alignment: .leading, spacing: 24) {
                Text("Program")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Let's optimize your meal timing windows based on your information. Your schedule will dynamically adapt to your lifestyle and progress. Don't worry – you can always adjust your windows or preferences later.")
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
                Text("Go to Program Design")
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

struct AlmostThereView_Previews: PreviewProvider {
    static var previews: some View {
        AlmostThereView()
    }
}
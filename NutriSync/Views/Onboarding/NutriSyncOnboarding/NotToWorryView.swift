//
//  NotToWorryView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 6 - Dark Theme
//

import SwiftUI

struct NotToWorryView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 6)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title
                    Text("Not to worry!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // Subtitle
                    Text("NutriSync will adapt your eating windows based on your lifestyle and progress. This is just a starting point.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.bottom, 20)
                    
                    // Week 1
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 1")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("NutriSync will create your initial eating windows optimized for your daily rhythm.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Week 2
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 2")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("After you log eight consecutive days of meals and check-ins, our algorithm will start optimizing your windows based on your energy patterns and progress.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Week 3 and beyond
                    HStack(alignment: .top, spacing: 16) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Week 3 and beyond")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Our algorithm will optimize your meal timing without complex tracking. Your needs change over time, but NutriSync will continue to adapt your eating windows to keep you aligned with your goals.")
                                .font(.system(size: 17))
                                .foregroundColor(.white.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Navigation
            HStack {
                Button {
                    coordinator.previousScreen()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Button {
                    coordinator.nextScreen()
                } label: {
                    HStack(spacing: 6) {
                        Text("Done with basics")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.nutriSyncBackground)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.white)
                    .cornerRadius(22)
                }
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

struct NotToWorryView_Previews: PreviewProvider {
    static var previews: some View {
        NotToWorryView()
    }
}
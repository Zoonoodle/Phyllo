//
//  NotificationOnboardingView.swift
//  NutriSync
//
//  Created by Brennen Price on 8/14/25.
//

import SwiftUI

struct NotificationOnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.bottom, 16)
                
                // Title
                Text("Never Miss a Meal Window")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Get gentle reminders when your meal windows open and close, helping you stay on track with your nutrition goals.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button {
                        Task {
                            isLoading = true
                            await notificationManager.requestAuthorization()
                            isLoading = false
                            isPresented = false
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                            }
                            Text("Enable Notifications")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(28)
                    }
                    .disabled(isLoading)
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Maybe Later")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }
}

struct NotificationOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationOnboardingView(isPresented: .constant(true))
            .environmentObject(NotificationManager.shared)
            .preferredColorScheme(.dark)
    }
}
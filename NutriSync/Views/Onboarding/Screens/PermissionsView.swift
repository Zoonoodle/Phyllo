//
//  PermissionsView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct PermissionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var cameraGranted = false
    @State private var notificationGranted = false
    @State private var healthGranted = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // App icon
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "00D26A"))
                .padding(.bottom, 32)
            
            // Title
            Text("NutriSync needs your permission to:")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 32)
            
            // Permission list
            VStack(spacing: 20) {
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "For meal scanning",
                    isGranted: $cameraGranted
                )
                
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "For meal window reminders",
                    isGranted: $notificationGranted
                )
                
                PermissionRow(
                    icon: "heart.text.square.fill",
                    title: "Health Data",
                    description: "Optional, for Apple Health sync",
                    isGranted: $healthGranted
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button {
                    // Request permissions
                    viewModel.nextScreen()
                } label: {
                    Text("Allow Access")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "0A0A0A"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "00D26A"))
                        .cornerRadius(28)
                }
                
                Button {
                    viewModel.nextScreen()
                } label: {
                    Text("Maybe Later")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0A0A0A"))
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isGranted: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(hex: "00D26A"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "00D26A"))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
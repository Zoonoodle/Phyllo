//
//  MFGoalSettingIntroView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 8
//

import SwiftUI

struct MFGoalSettingIntroView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Text("Goal Setting")
                    .font(.system(size: 34, weight: .bold))
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
                            .foregroundColor(.gray)
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
                            .foregroundColor(.gray)
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
                
                Text("MacroFactor's targets will be customized to keep you on track with the goal you specify. Don't worry – you can update your goal any time.")
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            Button {
                // Continue action
            } label: {
                Text("Go to Goal Setup")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.white)
    }
}

struct MFGoalSettingIntroView_Previews: PreviewProvider {
    static var previews: some View {
        MFGoalSettingIntroView()
    }
}
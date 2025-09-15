//
//  PerformanceHeaderView.swift
//  NutriSync
//
//  Performance view header matching Schedule view design
//

import SwiftUI

struct PerformanceHeaderView: View {
    @Binding var showingSettingsMenu: Bool
    let meals: [LoggedMeal]
    let userProfile: UserProfile
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                // Settings button and title in one row
                ZStack {
                    HStack {
                        // Settings button (left side)
                        Button(action: {
                            showingSettingsMenu = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Balance right side
                        Color.clear.frame(width: 44, height: 44)
                    }
                    
                    // Title with date centered
                    VStack(spacing: 2) {
                        Text("Performance")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(dateFormatter.string(from: Date()))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            
            // Separator line
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}
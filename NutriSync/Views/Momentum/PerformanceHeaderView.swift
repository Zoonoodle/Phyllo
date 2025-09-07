//
//  PerformanceHeaderView.swift
//  NutriSync
//
//  Performance view header matching Schedule view design
//

import SwiftUI

struct PerformanceHeaderView: View {
    @Binding var showDeveloperDashboard: Bool
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
                        Spacer()
                        
                        // Settings button
                        Button(action: {
                            showDeveloperDashboard = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.6))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
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
                
                // Macro bars (reusing Schedule's MacroSummaryBar)
                MacroSummaryBar(meals: meals, userProfile: userProfile)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 6)
            
            // Separator line
            Divider()
                .background(Color.white.opacity(0.1))
        }
    }
}
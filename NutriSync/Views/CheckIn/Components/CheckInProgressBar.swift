//
//  CheckInProgressBar.swift
//  NutriSync
//
//  Created on 7/28/25.
//

import SwiftUI

struct CheckInProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.nutriSyncAccent)
                    .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Segmented Progress Bar
struct SegmentedProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < currentStep ? Color.nutriSyncAccent : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
            }
        }
    }
}
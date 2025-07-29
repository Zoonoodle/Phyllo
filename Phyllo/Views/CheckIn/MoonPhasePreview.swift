//
//  MoonPhasePreview.swift
//  Phyllo
//
//  Standalone preview for moon phase visualization
//

import SwiftUI

struct MoonPhasePreview: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    Text("Moon Phase Visualization")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 40)
                    
                    Text("Sleep Hours → Moon Phase")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Show different sleep amounts
                    ForEach([0.0, 2.0, 4.0, 6.0, 7.0, 8.0, 9.0, 10.0, 12.0], id: \.self) { hours in
                        VStack(spacing: 16) {
                            HStack {
                                Text("\(hours, specifier: "%.0f") hours")
                                    .foregroundColor(.white)
                                    .frame(width: 80, alignment: .leading)
                                
                                Spacer()
                                
                                // Simplified moon shape preview
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        .frame(width: 60, height: 60)
                                    
                                    MoonShape(phase: phaseForHours(hours))
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                }
                                
                                Spacer()
                                
                                Text(phaseDescription(hours))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .frame(width: 120, alignment: .trailing)
                            }
                            .padding(.horizontal, 40)
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // Calculate phase based on hours (simplified for preview)
    func phaseForHours(_ hours: Double) -> CGFloat {
        if hours == 0 { return 0 }
        else if hours < 7 { return CGFloat(hours / 7) * 0.95 }
        else if hours <= 9 { return 1.0 }
        else { return max(0.5, 1.0 - CGFloat((hours - 9) * 0.1)) }
    }
    
    func phaseDescription(_ hours: Double) -> String {
        if hours == 0 { return "No moon" }
        else if hours < 4 { return "Thin crescent" }
        else if hours < 7 { return "Growing" }
        else if hours <= 9 { return "Full moon" }
        else { return "Waning" }
    }
}

#Preview {
    MoonPhasePreview()
}
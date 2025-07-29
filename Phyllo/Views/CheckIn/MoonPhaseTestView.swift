//
//  MoonPhaseTestView.swift
//  Phyllo
//
//  Moon Phase Test View
//

import SwiftUI

struct MoonPhaseTestView: View {
    @State private var sleepHours: Double = 7.0
    
    var body: some View {
        ZStack {
            Color.phylloBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("Moon Phase Visualization Test")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // Current sleep hours display
                VStack(spacing: 8) {
                    Text("\(sleepHours, specifier: "%.1f") hours of sleep")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Optimal: 7-9 hours")
                        .font(.caption)
                        .foregroundColor(.phylloTextSecondary)
                }
                
                // Moon visualization
                MoonPhaseVisualization(sleepHours: sleepHours)
                    .frame(height: 300)
                
                // Slider to adjust sleep hours
                VStack(spacing: 16) {
                    Text("Adjust Sleep Hours")
                        .font(.caption)
                        .foregroundColor(.phylloTextSecondary)
                    
                    Slider(value: $sleepHours, in: 0...12, step: 0.5)
                        .tint(.phylloGreen)
                        .padding(.horizontal, 40)
                    
                    // Quick presets
                    HStack(spacing: 16) {
                        ForEach([0.0, 3.0, 5.0, 7.0, 9.0, 11.0], id: \.self) { hours in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    sleepHours = hours
                                }
                            }) {
                                Text("\(Int(hours))h")
                                    .font(.caption)
                                    .foregroundColor(sleepHours == hours ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        sleepHours == hours ? Color.phylloGreen : Color.white.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    MoonPhaseTestView()
        .preferredColorScheme(.dark)
}
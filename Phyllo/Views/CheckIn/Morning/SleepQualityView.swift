//
//  SleepQualityView.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import SwiftUI

struct SleepQualityView: View {
    @Binding var selectedQuality: MorningCheckIn.SleepQuality?
    let onContinue: () -> Void
    
    @State private var sleepHours: Double = 7.0
    @State private var showContent = false
    
    private var derivedQuality: MorningCheckIn.SleepQuality {
        switch sleepHours {
        case 0..<3: return .terrible
        case 3..<5: return .poor
        case 5..<7: return .fair
        case 7..<9: return .good
        default: return .excellent
        }
    }
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How many hours did you sleep?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("Track your sleep to optimize your energy and meal timing.")
                    .font(.system(size: 15))
                    .foregroundColor(.phylloTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .animation(.easeOut(duration: 0.6), value: showContent)
            
            Spacer()
            
            // Sleep visualization
            VStack(spacing: 40) {
                MoonPhaseVisualization(sleepHours: sleepHours)
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: showContent)
                
                // Sleep hours slider
                SleepHoursSlider(hours: $sleepHours)
                    .padding(.horizontal, 20)
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)
            }
            
            Spacer()
            
            // Continue button
            HStack {
                Spacer()
                CheckInButton("", style: .minimal) {
                    selectedQuality = derivedQuality
                    onContinue()
                }
                .opacity(showContent ? 1.0 : 0)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: showContent)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        SleepQualityView(
            selectedQuality: .constant(nil),
            onContinue: {}
        )
    }
}
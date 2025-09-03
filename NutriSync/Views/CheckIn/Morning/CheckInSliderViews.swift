//
//  CheckInSliderViews.swift
//  NutriSync
//
//  Slider-based inputs for morning check-in
//

import SwiftUI

// MARK: - Sleep Quality Slider

struct SleepQualitySliderView: View {
    @Binding var sleepQuality: Int
    let onContinue: () -> Void
    
    private let labels = ["Terrible", "Poor", "Fair", "Good", "Great", "Excellent"]
    private let emojis = ["😴", "😔", "😐", "🙂", "😊", "😄"]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How did you sleep?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your sleep quality affects meal timing and energy distribution")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Emoji display
            Text(emojis[min(Int(Double(sleepQuality) / 2), emojis.count - 1)])
                .font(.system(size: 80))
            
            // Quality label
            Text(labels[min(Int(Double(sleepQuality) / 2), labels.count - 1)])
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            // Slider
            VStack(spacing: 16) {
                Slider(value: Binding(
                    get: { Double(sleepQuality) },
                    set: { sleepQuality = Int($0) }
                ), in: 0...10, step: 1)
                .tint(.nutriSyncAccent)
                
                HStack {
                    Text("0")
                    Spacer()
                    Text("5")
                    Spacer()
                    Text("10")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
}

// MARK: - Energy Level Slider

struct EnergyLevelSliderView: View {
    @Binding var energyLevel: Int
    let onContinue: () -> Void
    
    private let labels = ["Exhausted", "Very Low", "Low", "Moderate", "Good", "Energized"]
    private let colors: [Color] = [.red, .orange, .yellow, .green.opacity(0.8), .green, .cyan]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How's your energy?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("We'll adjust your first meal timing based on your energy")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Energy indicator
            ZStack {
                Circle()
                    .fill(colors[min(Int(Double(energyLevel) / 2), colors.count - 1)].opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 50))
                    .foregroundColor(colors[min(Int(Double(energyLevel) / 2), colors.count - 1)])
            }
            
            // Energy label
            Text(labels[min(Int(Double(energyLevel) / 2), labels.count - 1)])
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            // Slider
            VStack(spacing: 16) {
                Slider(value: Binding(
                    get: { Double(energyLevel) },
                    set: { energyLevel = Int($0) }
                ), in: 0...10, step: 1)
                .tint(colors[min(Int(Double(energyLevel) / 2), colors.count - 1)])
                
                HStack {
                    Text("Low")
                    Spacer()
                    Text("High")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
}

// MARK: - Hunger Level Slider

struct HungerLevelSliderView: View {
    @Binding var hungerLevel: Int
    let onContinue: () -> Void
    
    private let labels = ["Not hungry", "Slightly", "Somewhat", "Moderate", "Hungry", "Very hungry"]
    private let icons = ["circle", "circle.lefthalf.filled", "circle.fill", "circle.inset.filled", "circle.hexagongrid", "circle.hexagongrid.fill"]
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Text("How hungry are you?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your hunger level determines when your first meal should be")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Hunger indicator
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 140, height: 140)
                
                Image(systemName: icons[min(Int(Double(hungerLevel) / 2), icons.count - 1)])
                    .font(.system(size: 60))
                    .foregroundColor(.nutriSyncAccent)
            }
            
            // Hunger label
            Text(labels[min(Int(Double(hungerLevel) / 2), labels.count - 1)])
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            // Info text
            Text(hungerInfoText)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            
            // Slider
            VStack(spacing: 16) {
                Slider(value: Binding(
                    get: { Double(hungerLevel) },
                    set: { hungerLevel = Int($0) }
                ), in: 0...10, step: 1)
                .tint(.nutriSyncAccent)
                
                HStack {
                    Text("Not hungry")
                    Spacer()
                    Text("Very hungry")
                }
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.nutriSyncAccent)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
    }
    
    private var hungerInfoText: String {
        if hungerLevel >= 7 {
            return "First meal in 30-45 minutes"
        } else if hungerLevel <= 3 {
            return "First meal in 75-90 minutes"
        } else {
            return "First meal in about 60 minutes"
        }
    }
}

// MARK: - Previews

struct CheckInSliderViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SleepQualitySliderView(sleepQuality: .constant(5)) {
                // Preview action
            }
            .previewDisplayName("Sleep Quality")
            
            EnergyLevelSliderView(energyLevel: .constant(5)) {
                // Preview action
            }
            .previewDisplayName("Energy Level")
            
            HungerLevelSliderView(hungerLevel: .constant(5)) {
                // Preview action
            }
            .previewDisplayName("Hunger Level")
        }
        .preferredColorScheme(.dark)
        .background(Color.nutriSyncBackground)
    }
}
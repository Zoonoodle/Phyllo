//
//  ImpactCalculatorView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct ImpactCalculatorView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var showImpact = false
    @State private var animateNumber = false
    
    private var lostHours: Int {
        // Calculate based on energy level (1-10 scale)
        let energyDeficit = 10 - viewModel.userData.currentEnergyLevel
        return energyDeficit * 365 // Hours per year
    }
    
    private var lostDays: Int {
        lostHours / 24
    }
    
    var body: some View {
        OnboardingScreenBase(
            viewModel: viewModel,
            showBack: true,
            nextTitle: showImpact ? "Let's fix this" : "Calculate Impact",
            nextAction: {
                if !showImpact {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showImpact = true
                    }
                } else {
                    viewModel.nextScreen()
                }
            }
        ) {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)
            
            // Title
            Text("How's your current energy level?")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            
            // Energy slider with emoji faces
            VStack(spacing: 32) {
                // Emoji indicator
                Text(energyEmoji)
                    .font(.system(size: 60))
                    .animation(.spring(response: 0.3), value: viewModel.userData.currentEnergyLevel)
                
                // Slider
                VStack(spacing: 16) {
                    HStack {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text("10")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    CustomSlider(
                        value: Binding(
                            get: { Double(viewModel.userData.currentEnergyLevel) },
                            set: { viewModel.userData.currentEnergyLevel = Int($0) }
                        ),
                        range: 1...10,
                        step: 1
                    )
                }
                .padding(.horizontal, 48)
                
                // Current value
                Text("Energy Level: \(viewModel.userData.currentEnergyLevel)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Impact message (appears after slider interaction)
            if showImpact {
                VStack(spacing: 16) {
                    Text("At this rate, you'll lose")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Animated number (Opal-style)
                    Text("\(animateNumber ? lostHours : 0) hours")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "FF6B6B"))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: animateNumber)
                    
                    Text("of productive time this year")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("That's \(lostDays) days of feeling suboptimal")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 8)
                }
                .padding(.top, 40)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .onAppear {
                    withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                        animateNumber = true
                    }
                }
            }
            
                Spacer()
            }
        }
    }
    
    private var energyEmoji: String {
        switch viewModel.userData.currentEnergyLevel {
        case 1...2: return "😴"
        case 3...4: return "😑"
        case 5...6: return "😐"
        case 7...8: return "🙂"
        case 9...10: return "😊"
        default: return "😐"
        }
    }
}

// Custom slider matching the app's design
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "00D26A"))
                    .frame(width: fillWidth(in: geometry.size.width), height: 8)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(x: thumbOffset(in: geometry.size.width) - 12)
                    .gesture(
                        DragGesture()
                            .onChanged { drag in
                                updateValue(from: drag.location.x, in: geometry.size.width)
                            }
                    )
            }
            .frame(height: 24)
            .contentShape(Rectangle())
            .onTapGesture { location in
                updateValue(from: location.x, in: geometry.size.width)
            }
        }
        .frame(height: 24)
    }
    
    private func fillWidth(in totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * percentage
    }
    
    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * percentage
    }
    
    private func updateValue(from x: CGFloat, in totalWidth: CGFloat) {
        let percentage = max(0, min(1, x / totalWidth))
        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * percentage
        value = round(newValue / step) * step
    }
}

// MARK: - Preview
struct ImpactCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        ImpactCalculatorView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
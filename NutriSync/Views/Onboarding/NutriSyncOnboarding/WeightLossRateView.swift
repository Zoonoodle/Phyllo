//
//  WeightLossRateView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 11 - Dark Theme
//

import SwiftUI
import UIKit

struct WeightLossRateView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedRate: Double = 0.5 // % of body weight per week
    @State private var isDragging = false
    
    var isWeightGain: Bool {
        coordinator.goal.lowercased() == "gain weight"
    }
    
    // Rate options - dynamic based on goal
    var rateOptions: [(label: String, rate: Double, color: Color)] {
        if isWeightGain {
            return [
                (label: "Conservative", rate: 0.25, color: Color.green),
                (label: "Standard", rate: 0.5, color: Color.blue),
                (label: "Moderate", rate: 0.75, color: Color.purple),
                (label: "Aggressive", rate: 1.0, color: Color.orange)
            ]
        } else {
            return [
                (label: "Conservative", rate: 0.25, color: Color.blue),
                (label: "Standard", rate: 0.5, color: Color.green),
                (label: "Aggressive", rate: 0.75, color: Color.orange),
                (label: "Extreme", rate: 1.0, color: Color.red)
            ]
        }
    }
    
    var currentWeight: Double {
        coordinator.weight > 0 ? coordinator.weight : 70 // Default to 70kg if not set
    }
    
    var targetWeight: Double {
        coordinator.targetWeight ?? (currentWeight - 10) // Default to 10kg loss
    }
    
    var weeklyChange: Double {
        currentWeight * (selectedRate / 100)
    }
    
    var monthlyChange: Double {
        weeklyChange * 4.33 // Average weeks per month
    }
    
    var estimatedDailyCalories: Double {
        let tdee = coordinator.tdee ?? 2000
        let dailyChange = (weeklyChange * 2.2 * 3500) / 7 // Convert kg to lbs, 3500 cal per lb
        if isWeightGain {
            return tdee + dailyChange // Add calories for gain
        } else {
            return max(1200, tdee - dailyChange) // Subtract for loss, minimum 1200
        }
    }
    
    var weeksToGoal: Int {
        let totalChange = isWeightGain ? (targetWeight - currentWeight) : (currentWeight - targetWeight)
        guard totalChange > 0 && weeklyChange > 0 else { return 0 }
        return Int(ceil(totalChange / weeklyChange))
    }
    
    var estimatedEndDate: Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeksToGoal, to: Date()) ?? Date()
    }
    
    var currentRateLabel: String {
        if isWeightGain {
            if selectedRate <= 0.25 {
                return "Conservative (Recommended)"
            } else if selectedRate <= 0.5 {
                return "Standard"
            } else if selectedRate <= 0.75 {
                return "Moderate"
            } else {
                return "Aggressive (Monitor closely)"
            }
        } else {
            if selectedRate <= 0.25 {
                return "Conservative"
            } else if selectedRate <= 0.5 {
                return "Standard (Recommended)"
            } else if selectedRate <= 0.75 {
                return "Aggressive"
            } else {
                return "Extreme (Not Recommended)"
            }
        }
    }
    
    var currentRateColor: Color {
        if isWeightGain {
            if selectedRate <= 0.25 {
                return .green
            } else if selectedRate <= 0.5 {
                return .blue
            } else if selectedRate <= 0.75 {
                return .purple
            } else {
                return .orange
            }
        } else {
            if selectedRate <= 0.25 {
                return .blue
            } else if selectedRate <= 0.5 {
                return .green
            } else if selectedRate <= 0.75 {
                return .orange
            } else {
                return .red
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Progress bar
                    OnboardingSectionProgressBar()
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    
                    // Title
                    Text("At what rate?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Subtitle
                    Text(isWeightGain ? "Set your desired rate of weight gain." : "Set your desired rate of weight loss.")
                        .font(.system(size: 17))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    
                    // Rate section
                    VStack(spacing: 32) {
                        // Current rate label
                        Text(currentRateLabel)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(currentRateColor)
                            .animation(.easeInOut(duration: 0.2), value: selectedRate)
                        
                        // Interactive Slider
                        VStack(spacing: 16) {
                            GeometryReader { sliderGeometry in
                                ZStack(alignment: .leading) {
                                    // Track
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(height: 4)
                                    
                                    // Active track with gradient
                                    LinearGradient(
                                        colors: [.blue, .green, .orange, .red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .mask(
                                        Rectangle()
                                            .frame(width: sliderGeometry.size.width * CGFloat(selectedRate), height: 4)
                                    )
                                    
                                    // Thumb
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        .scaleEffect(isDragging ? 1.2 : 1.0)
                                        .offset(x: sliderGeometry.size.width * CGFloat(selectedRate) - 16)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
                                }
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            let newValue = value.location.x / sliderGeometry.size.width
                                            selectedRate = min(max(0.1, Double(newValue)), 1.0)
                                            
                                            // Haptic feedback at key points
                                            if abs(selectedRate - 0.25) < 0.02 ||
                                               abs(selectedRate - 0.5) < 0.02 ||
                                               abs(selectedRate - 0.75) < 0.02 {
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            }
                                        }
                                        .onEnded { _ in
                                            isDragging = false
                                        }
                                )
                                .onTapGesture { location in
                                    let newValue = location.x / sliderGeometry.size.width
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedRate = min(max(0.1, Double(newValue)), 1.0)
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                            .frame(height: 32)
                            
                            // Labels
                            HStack {
                                Text("Slow")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                Spacer()
                                Text("Fast")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Rate details (now dynamic)
                        VStack(spacing: 16) {
                            // Weekly change
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white.opacity(0.6))
                                Text(String(format: "%@%.2f lbs (%.1f%% BW) / Week", 
                                          isWeightGain ? "+" : "−",
                                          weeklyChange * 2.2, selectedRate))
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            // Monthly change
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.white.opacity(0.6))
                                Text(String(format: "%@%.2f lbs (%.1f%% BW) / Month", 
                                          isWeightGain ? "+" : "−",
                                          monthlyChange * 2.2, selectedRate * 4.33))
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                                .padding(.vertical, 8)
                            
                            // Calorie target
                            HStack {
                                Image(systemName: "flame")
                                    .foregroundColor(.white.opacity(0.6))
                                Text(String(format: "~ %.0f kcal estimated daily target", estimatedDailyCalories))
                                    .font(.system(size: 17))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // End date
                            HStack {
                                Image(systemName: "flag.checkered")
                                    .foregroundColor(.white.opacity(0.6))
                                Text("Approximate end date: \(estimatedEndDate, formatter: dateFormatter)")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Warning for extreme rates
                            if selectedRate > 0.75 {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(isWeightGain ? "Monitor body composition closely" : "This rate may be difficult to sustain")
                                        .font(.system(size: 14))
                                        .foregroundColor(.orange)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Navigation
                    HStack {
                        Button {
                            coordinator.previousScreen()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button {
                            // Save weight change rate to coordinator (convert to kg per week)
                            coordinator.weightLossRate = isWeightGain ? weeklyChange : -weeklyChange
                            coordinator.nextScreen()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(Color.nutriSyncBackground)
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(22)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color.nutriSyncBackground)
        .ignoresSafeArea(.keyboard)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }
}

struct WeightLossRateView_Previews: PreviewProvider {
    static var previews: some View {
        WeightLossRateView()
    }
}
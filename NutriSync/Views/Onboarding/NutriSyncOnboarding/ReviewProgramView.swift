//
//  ReviewProgramView.swift
//  NutriSync
//
//  Final review screen showing personalized meal schedule
//

import SwiftUI
import FirebaseAuth

struct ReviewProgramView: View {
    @Environment(NutriSyncOnboardingViewModel.self) var coordinator
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    @State private var isCreatingProfile = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToApp = false
    
    // Use data from coordinator instead of mock
    private var wakeTime: Date { coordinator.wakeTime }
    private var bedTime: Date { coordinator.bedTime }
    private var mealFrequency: String { coordinator.mealFrequency }
    private var eatingWindow: String { coordinator.eatingWindow }
    private var breakfastHabit: String { coordinator.breakfastHabit }
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        // Handle close
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Personalized")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Meal Schedule")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.nutriSyncAccent)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Schedule visualization
                        MealScheduleVisualization()
                            .padding(.vertical, 24)
                        
                        // Key insights
                        VStack(spacing: 16) {
                            InsightCard(
                                icon: "sun.max.fill",
                                iconColor: .orange,
                                title: "Circadian Aligned",
                                description: "Your eating window aligns with peak insulin sensitivity for optimal metabolism"
                            )
                            
                            InsightCard(
                                icon: "clock.fill",
                                iconColor: .nutriSyncAccent,
                                title: "16:8 Fasting Schedule",
                                description: "8-hour eating window promotes metabolic flexibility and cellular repair"
                            )
                            
                            InsightCard(
                                icon: "moon.stars.fill",
                                iconColor: .purple,
                                title: "Sleep Optimized",
                                description: "Last meal 3 hours before bed supports deep sleep and recovery"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Meal windows
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your Meal Windows")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            MealWindowCard(
                                time: "8:00 AM",
                                title: "Breakfast Window",
                                description: "High protein to kickstart metabolism",
                                calories: "450-550",
                                icon: "sunrise.fill",
                                color: .orange
                            )
                            
                            MealWindowCard(
                                time: "1:00 PM",
                                title: "Lunch Window",
                                description: "Balanced macros for sustained energy",
                                calories: "600-700",
                                icon: "sun.max.fill",
                                color: .yellow
                            )
                            
                            MealWindowCard(
                                time: "6:00 PM",
                                title: "Dinner Window",
                                description: "Light and nutrient-dense for recovery",
                                calories: "500-600",
                                icon: "sunset.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .padding(.bottom, 100)
                }
                
                Spacer()
                
                // Start button
                VStack(spacing: 12) {
                    Button(action: startJourney) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.nutriSyncAccent)
                                .frame(height: 56)
                            
                            if isCreatingProfile {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                    Text("Creating your profile...")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            } else {
                                Text("Start Your Journey")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isCreatingProfile)
                    
                    Text("You can adjust your schedule anytime")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationDestination(isPresented: $navigateToApp) {
            MainTabView()
                .navigationBarBackButtonHidden(true)
        }
        .alert("Setup Error", isPresented: $showError) {
            Button("Retry") {
                startJourney()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func startJourney() {
        Task {
            isCreatingProfile = true
            
            do {
                print("[ReviewProgramView] Starting profile creation")
                
                // Complete onboarding and create profile atomically
                try await coordinator.completeOnboarding()
                
                // Add haptic feedback for success
                await MainActor.run {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
                
                print("[ReviewProgramView] Profile created successfully")
                
                // Navigate to main app
                await MainActor.run {
                    navigateToApp = true
                }
                
            } catch {
                print("[ReviewProgramView] Profile creation failed: \(error.localizedDescription)")
                
                await MainActor.run {
                    errorMessage = "Failed to create your profile: \(error.localizedDescription)\n\nPlease check your internet connection and try again."
                    showError = true
                    
                    // Add haptic feedback for error
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
            
            isCreatingProfile = false
        }
    }
}

// MARK: - Meal Schedule Visualization
struct MealScheduleVisualization: View {
    var body: some View {
        VStack(spacing: 16) {
            // Time labels
            HStack {
                ForEach([6, 9, 12, 15, 18, 21, 24], id: \.self) { hour in
                    Text(hour == 24 ? "12" : "\(hour)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if hour != 24 {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Visual timeline
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 60)
                
                // Sleep periods
                HStack(spacing: 0) {
                    // Early morning sleep (12 AM - 7 AM)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 80, height: 60)
                    
                    Spacer()
                    
                    // Night sleep (11 PM - 12 AM)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 27, height: 60)
                }
                
                // Eating window
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [Color.nutriSyncAccent, Color.nutriSyncAccent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 133, height: 40)
                    .offset(x: 53) // 8 AM start
                
                // Meal markers
                HStack(spacing: 0) {
                    // Breakfast
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: 53)
                    
                    // Lunch
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: 77)
                    
                    // Dinner
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: 77)
                }
            }
            .padding(.horizontal, 24)
            
            // Legend
            HStack(spacing: 24) {
                LegendItem(color: Color.nutriSyncAccent, label: "Eating Window")
                LegendItem(color: Color.purple.opacity(0.3), label: "Sleep")
                LegendItem(color: Color.white, label: "Meals")
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Meal Window Card
struct MealWindowCard: View {
    let time: String
    let title: String
    let description: String
    let calories: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Time badge
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(time)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 60)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("\(calories) cal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct ReviewProgramView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewProgramView()
    }
}
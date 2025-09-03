import SwiftUI

struct DailyNutriSyncRing: View {
    let dailySummary: ScheduleViewModel.DailyNutritionSummary
    @State private var animateProgress: Bool = false
    
    private var calorieProgress: Double {
        guard dailySummary.targetCalories > 0 else { return 0 }
        return Double(dailySummary.totalCalories) / Double(dailySummary.targetCalories)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            HStack {
                Text("Daily NutriSync Ring")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Calorie ring with more top padding
            ZStack {
                // Background ring with open bottom
                Circle()
                    .trim(from: 0.12, to: 0.88)
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(90))
                
                // Progress ring with open bottom and tapered ends
                Circle()
                    .trim(from: 0, to: animateProgress ? min(calorieProgress * 0.76, 0.76) : 0)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.phylloAccent, Color.phylloAccent.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(126))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateProgress)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(Int(calorieProgress * 100))%")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("of daily goal")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(dailySummary.totalCalories) / \(dailySummary.targetCalories) cal")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Daily totals summary
            VStack(spacing: 12) {
                HStack(spacing: 24) {
                    DailyMacroIndicator(
                        label: "Windows",
                        value: "\(dailySummary.completedWindows)/\(dailySummary.totalWindows)",
                        color: .phylloAccent
                    )
                    
                    DailyMacroIndicator(
                        label: "Meals",
                        value: "\(dailySummary.meals.count)",
                        color: .blue
                    )
                }
                
                // Macro bars with proper padding
                HStack(spacing: 20) {
                    MacroProgressBar(
                        title: "Protein",
                        consumed: dailySummary.totalProtein,
                        target: dailySummary.targetProtein,
                        color: .orange
                    )
                    
                    MacroProgressBar(
                        title: "Fat",
                        consumed: dailySummary.totalFat,
                        target: dailySummary.targetFat,
                        color: .yellow
                    )
                    
                    MacroProgressBar(
                        title: "Carbs",
                        consumed: dailySummary.totalCarbs,
                        target: dailySummary.targetCarbs,
                        color: .blue
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 24)
        .background(Color.phylloCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}

struct DailyMacroIndicator: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// Reuse the MacroProgressBar from MacroNutritionPage
// It's already defined there, so we'll rely on that

#Preview {
    ZStack {
        Color.phylloBackground.ignoresSafeArea()
        
        ScrollView {
            DailyNutriSyncRing(
                dailySummary: ScheduleViewModel.DailyNutritionSummary(
                    date: Date(),
                    totalCalories: 1850,
                    targetCalories: 2400,
                    totalProtein: 145,
                    targetProtein: 180,
                    totalFat: 65,
                    targetFat: 80,
                    totalCarbs: 220,
                    targetCarbs: 280,
                    completedWindows: 3,
                    totalWindows: 5,
                    micronutrients: [:],
                    meals: [],
                    windows: [],
                    dayPurpose: nil
                )
            )
            .padding()
        }
    }
}
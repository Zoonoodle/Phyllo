//
//  ProgramExplanationView.swift
//  NutriSync
//
//  Clean data breakdown screen for onboarding completion
//

import SwiftUI

struct ProgramExplanationView: View {
    let viewModel: OnboardingCompletionViewModel
    @Environment(NutriSyncOnboardingViewModel.self) var coordinator
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 8) {
                        Text("How We Built Your Program")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Science-based calculations for optimal results")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 24)
                    
                    // Data sections (clean, no emojis, facts-focused)
                    VStack(spacing: 24) {
                        if let program = viewModel.program {
                            DataSection(
                                title: "Your Metabolic Profile",
                                rows: [
                                    DataRow(label: "TDEE", value: "\(program.tdee.formatted()) cal/day"),
                                    DataRow(label: "BMR", value: "\(program.bmr.formatted()) cal/day"),
                                    DataRow(label: "Activity", value: "+\((program.tdee - program.bmr).formatted()) cal/day")
                                ]
                            )
                            
                            DataSection(
                                title: "Your Goal Strategy",
                                rows: [
                                    DataRow(label: "Target", value: "\(program.targetCalories.formatted()) cal/day"),
                                    DataRow(label: program.deficit > 0 ? "Deficit" : "Surplus", 
                                           value: "\(abs(program.deficit).formatted()) cal/day"),
                                    DataRow(label: "Timeline", value: program.timeline)
                                ]
                            )
                        }
                        
                        // Sleep-optimized schedule
                        if let firstDay = viewModel.weeklyWindows.first,
                           let firstWindow = firstDay.windows.first,
                           let lastWindow = firstDay.windows.last {
                            
                            DataSection(
                                title: "Sleep-Optimized Schedule",
                                rows: [
                                    DataRow(label: "Wake", value: formatTime(coordinator.wakeTime)),
                                    DataRow(label: "First meal", value: formatTime(firstWindow.startTime)),
                                    DataRow(label: "Last meal", value: formatTime(lastWindow.endTime)),
                                    DataRow(label: "Bed", value: formatTime(coordinator.bedTime))
                                ]
                            )
                        }
                        
                        // Training windows (if applicable)
                        if coordinator.exerciseFrequency != "Never" {
                            DataSection(
                                title: "Training Windows",
                                rows: [
                                    DataRow(label: "Pre-workout", value: "90 min before"),
                                    DataRow(label: "Post-workout", value: "Within 30 min"),
                                    DataRow(label: "Recovery", value: "Enhanced portions")
                                ]
                            )
                        }
                        
                        // Macro distribution
                        if let macros = viewModel.macroTargets {
                            DataSection(
                                title: "Macro Distribution",
                                rows: [
                                    DataRow(label: "Protein", 
                                           value: "\(macros.protein)g (\(macros.proteinPercentage)%)",
                                           highlight: true),
                                    DataRow(label: "Carbs", 
                                           value: "\(macros.carbs)g (\(macros.carbPercentage)%)"),
                                    DataRow(label: "Fat", 
                                           value: "\(macros.fat)g (\(macros.fatPercentage)%)")
                                ]
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Swipe hint
                    Text("Swipe to continue")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Data Section
struct DataSection: View {
    let title: String
    let rows: [DataRow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title with divider
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
            }
            
            // Data rows
            VStack(spacing: 12) {
                ForEach(rows, id: \.label) { row in
                    HStack {
                        Text(row.label)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text(row.value)
                            .font(.system(size: 16, weight: row.highlight ? .semibold : .regular))
                            .foregroundColor(row.highlight ? Color.nutriSyncAccent : .white)
                            .monospacedDigit() // For better number alignment
                    }
                }
            }
        }
    }
}

// MARK: - Data Row Model
struct DataRow {
    let label: String
    let value: String
    var highlight: Bool = false
}

// Extension for number formatting
extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
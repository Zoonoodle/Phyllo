//
//  WeightCheckView.swift
//  NutriSync
//
//  Weight tracking screen for Daily Sync
//

import SwiftUI

struct WeightCheckView: View {
    @ObservedObject var viewModel: DailySyncViewModel
    @State private var weightText = ""
    @State private var showSkipOptions = false
    @State private var selectedSkipReason: WeightSkipReason?
    @State private var showTrend = false
    @FocusState private var isWeightFocused: Bool
    
    // Previous weight for reference
    var lastWeight: Double? {
        WeightTrackingManager.shared.lastWeightEntry?.weight
    }
    
    var changeFromLast: Double? {
        guard let last = lastWeight,
              let current = Double(weightText) else { return nil }
        return current - last
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with context
            VStack(spacing: 12) {
                Text("Time for a check-in!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("How much do you weigh today?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                // Best practices reminder
                HStack(spacing: 4) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.nutriSyncAccent.opacity(0.7))
                    
                    Text("Best after bathroom, before eating")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 4)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Weight input section
            VStack(spacing: 32) {
                // Large weight input
                VStack(spacing: 16) {
                    HStack(alignment: .lastTextBaseline, spacing: 12) {
                        TextField("0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                            .focused($isWeightFocused)
                            .onChange(of: weightText) { newValue in
                                // Limit to reasonable weight range
                                if let weight = Double(newValue), weight > 500 {
                                    weightText = "500"
                                }
                            }
                        
                        Text("lbs")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    // Show change from last weight
                    if let change = changeFromLast {
                        HStack(spacing: 4) {
                            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12, weight: .medium))
                            
                            Text(String(format: "%.1f lbs from last time", abs(change)))
                                .font(.system(size: 14))
                        }
                        .foregroundColor(change > 0 ? .green : .orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    // Last weight reference
                    if let last = lastWeight {
                        Text("Previous: \(String(format: "%.1f", last)) lbs")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // Quick weight buttons for common increments
                if let last = lastWeight {
                    HStack(spacing: 12) {
                        ForEach([-2, -1, 0, 1, 2], id: \.self) { change in
                            Button(action: {
                                let newWeight = last + Double(change)
                                weightText = String(format: "%.1f", newWeight)
                                hideKeyboard()
                            }) {
                                Text(change > 0 ? "+\(change)" : change == 0 ? "Same" : "\(change)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 56, height: 36)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Trend indicator (if available)
                if let trend = WeightTrackingManager.shared.currentTrend,
                   trend.daysTracked > 0 {
                    Button(action: { showTrend.toggle() }) {
                        HStack(spacing: 8) {
                            Image(systemName: trend.monthlyTrend.icon)
                                .font(.system(size: 16))
                            
                            Text("View your trend")
                                .font(.system(size: 14, weight: .medium))
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .opacity(0.5)
                        }
                        .foregroundColor(.nutriSyncAccent)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                // Navigation buttons
                HStack(spacing: 12) {
                    Button(action: { viewModel.previousScreen() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                    }
                    
                    Button(action: saveWeight) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.nutriSyncAccent)
                            .cornerRadius(16)
                    }
                    .disabled(weightText.isEmpty && selectedSkipReason == nil)
                    .opacity((weightText.isEmpty && selectedSkipReason == nil) ? 0.5 : 1)
                }
                
                // Skip option
                Button(action: { showSkipOptions.toggle() }) {
                    Text("Skip today")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Auto-focus weight field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isWeightFocused = true
            }
        }
        .sheet(isPresented: $showSkipOptions) {
            SkipWeightSheet(
                selectedReason: $selectedSkipReason,
                isPresented: $showSkipOptions,
                onSkip: {
                    saveSkippedWeight()
                }
            )
        }
        .sheet(isPresented: $showTrend) {
            WeightTrendView()
        }
    }
    
    private func saveWeight() {
        guard let weight = Double(weightText) else {
            // If no weight entered but we're here, skip
            saveSkippedWeight()
            return
        }
        
        Task {
            let entry = WeightEntry(
                weight: weight,
                context: WeightEntry.WeighInContext(
                    timeOfDay: "morning",
                    syncContext: viewModel.syncData.syncContext,
                    notes: nil,
                    skippedReason: nil,
                    wasEstimated: false
                ),
                userId: FirebaseDataProvider.shared.currentUserId ?? ""
            )
            
            do {
                try await WeightTrackingManager.shared.saveWeightEntry(entry)
                viewModel.recordedWeight = weight
                viewModel.nextScreen()
            } catch {
                print("Failed to save weight: \(error)")
                // Continue anyway
                viewModel.nextScreen()
            }
        }
    }
    
    private func saveSkippedWeight() {
        Task {
            if let skipReason = selectedSkipReason {
                let entry = WeightEntry(
                    weight: lastWeight ?? 0,
                    context: WeightEntry.WeighInContext(
                        timeOfDay: "morning",
                        syncContext: viewModel.syncData.syncContext,
                        notes: nil,
                        skippedReason: skipReason.rawValue,
                        wasEstimated: true
                    ),
                    userId: FirebaseDataProvider.shared.currentUserId ?? ""
                )
                
                do {
                    try await WeightTrackingManager.shared.saveWeightEntry(entry)
                } catch {
                    print("Failed to save skipped weight: \(error)")
                }
            }
            
            viewModel.nextScreen()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Skip Weight Sheet
struct SkipWeightSheet: View {
    @Binding var selectedReason: WeightSkipReason?
    @Binding var isPresented: Bool
    let onSkip: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Why are you skipping?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(WeightSkipReason.allCases, id: \.self) { reason in
                            Button(action: {
                                selectedReason = reason
                                isPresented = false
                                onSkip()
                            }) {
                                HStack {
                                    Image(systemName: reason.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(.nutriSyncAccent)
                                        .frame(width: 30)
                                    
                                    Text(reason.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
    }
}

// MARK: - Weight Trend View
struct WeightTrendView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = WeightTrackingManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                if let trend = manager.currentTrend {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Current weight card
                            if let current = trend.currentWeight {
                                VStack(spacing: 12) {
                                    Text("Current Weight")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Text(String(format: "%.1f lbs", current))
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    // Trend indicator
                                    HStack {
                                        Image(systemName: trend.monthlyTrend.icon)
                                        Text(trend.monthlyTrend.rawValue.capitalized)
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.nutriSyncAccent)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                            }
                            
                            // Stats grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                StatCard(
                                    title: "Weekly Avg",
                                    value: trend.weeklyAverage.map { String(format: "%.1f", $0) } ?? "—",
                                    unit: "lbs"
                                )
                                
                                StatCard(
                                    title: "Days Tracked",
                                    value: "\(trend.daysTracked)",
                                    unit: "days"
                                )
                            }
                            
                            // Recent entries
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Entries")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                ForEach(manager.weightHistory.prefix(7)) { entry in
                                    HStack {
                                        Text(entry.date, style: .date)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.1f lbs", entry.weight))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.03))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Weight Trend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
    }
}

// MARK: - Stat Card Component
private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}
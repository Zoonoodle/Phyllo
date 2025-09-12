//
//  EditWindowView.swift
//  NutriSync
//
//  Created for editing window and deleting meals.
//

import SwiftUI

struct EditWindowView: View {
    let window: MealWindow
    @ObservedObject var viewModel: ScheduleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var mealToDelete: LoggedMeal?
    @State private var isDeleting = false
    
    // Filter meals for this window
    private var windowMeals: [LoggedMeal] {
        viewModel.mealsInWindow(window)
    }
    
    private var windowTitle: String {
        window.name.isEmpty ? "Edit Window" : "Edit \(window.name)"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Window info card
                        windowInfoCard
                        
                        // Meals section with delete capability
                        mealsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(windowTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                    .fontWeight(.medium)
                }
            }
            .toolbarBackground(Color.nutriSyncBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .alert("Delete Meal", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                mealToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let meal = mealToDelete {
                    Task {
                        isDeleting = true
                        await viewModel.deleteMeal(meal)
                        isDeleting = false
                        mealToDelete = nil
                    }
                }
            }
        } message: {
            if let meal = mealToDelete {
                Text("Are you sure you want to delete \"\(meal.name)\"? This action cannot be undone.")
            }
        }
    }
    
    @ViewBuilder
    private var windowInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Window Time")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Text(formatTimeRange(start: window.startTime, end: window.endTime))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Target")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(window.targetCalories) cal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack {
                Label("Meals Logged", systemImage: "fork.knife")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("\(windowMeals.count)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    @ViewBuilder
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Logged Foods")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                if !windowMeals.isEmpty {
                    Text("(\(windowMeals.count))")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
            }
            
            if windowMeals.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(windowMeals) { meal in
                        editableMealCard(meal: meal)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func editableMealCard(meal: LoggedMeal) -> some View {
        HStack(spacing: 16) {
            // Delete button
            Button {
                mealToDelete = meal
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red.opacity(0.8))
            }
            .disabled(isDeleting)
            
            // Emoji
            Text(meal.emoji)
                .font(.system(size: 32))
                .frame(width: 40)
            
            // Meal info
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Time
                    Text(formatTime(meal.timestamp))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Calories
                    Text("\(meal.calories) cal")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.3))
                    
                    // Macros
                    HStack(spacing: 4) {
                        Text("\(meal.protein)P")
                            .foregroundColor(.orange.opacity(0.7))
                        Text("\(meal.carbs)C")
                            .foregroundColor(.blue.opacity(0.7))
                        Text("\(meal.fat)F")
                            .foregroundColor(.yellow.opacity(0.7))
                    }
                    .font(.system(size: 12))
                }
            }
            
            Spacer()
            
            // Chevron for detail (future feature)
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No meals logged")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Add meals to this window from the main screen")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
                        )
                        .foregroundColor(.white.opacity(0.1))
                )
        )
    }
    
    // MARK: - Helper Functions
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTime = formatter.string(from: start)
        let endTime = formatter.string(from: end)
        return "\(startTime) - \(endTime)"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    EditWindowView(
        window: MealWindow.mockWindows(for: .performanceFocus).first!,
        viewModel: ScheduleViewModel()
    )
}
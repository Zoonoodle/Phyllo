//
//  MealDetailsEditView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct MealDetailsEditView: View {
    @Environment(\.dismiss) private var dismiss
    let meal: MockMeal
    
    // State for editing
    @State private var mealName: String = ""
    @State private var ingredients: [IngredientItem] = []
    @State private var showAddIngredient = false
    
    init(meal: MockMeal) {
        self.meal = meal
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Meal name section
                        mealNameSection
                        
                        // Ingredients list
                        ingredientsSection
                        
                        // Updated nutrition
                        updatedNutritionSection
                        
                        // Save button
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Edit Details")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupInitialData()
        }
    }
    
    // MARK: - Sections
    
    private var mealNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Name")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            TextField("Enter meal name", text: $mealName)
                .font(.system(size: 17))
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showAddIngredient = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            
            VStack(spacing: 12) {
                ForEach($ingredients) { $ingredient in
                    IngredientRow(ingredient: $ingredient)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    private var updatedNutritionSection: some View {
        VStack(spacing: 16) {
            Text("Updated Nutrition")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            
            HStack(spacing: 20) {
                NutritionSummaryItem(
                    value: calculateTotalCalories(),
                    label: "cal",
                    color: .white
                )
                
                NutritionSummaryItem(
                    value: calculateTotalProtein(),
                    label: "g protein",
                    color: .blue
                )
                
                NutritionSummaryItem(
                    value: calculateTotalCarbs(),
                    label: "g carbs",
                    color: .orange
                )
                
                NutritionSummaryItem(
                    value: calculateTotalFat(),
                    label: "g fat",
                    color: .yellow
                )
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            // Save changes
            dismiss()
        }) {
            Text("Save Changes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialData() {
        mealName = meal.name
        
        // Mock ingredients based on meal
        ingredients = [
            IngredientItem(name: "Grilled Chicken", amount: 150, unit: "g", calories: 248, protein: 28, carbs: 0, fat: 14),
            IngredientItem(name: "Mixed Greens", amount: 2, unit: "cups", calories: 20, protein: 2, carbs: 4, fat: 0),
            IngredientItem(name: "Avocado", amount: 0.5, unit: "whole", calories: 120, protein: 2, carbs: 6, fat: 11),
            IngredientItem(name: "Balsamic Dressing", amount: 2, unit: "tbsp", calories: 32, protein: 0, carbs: 2, fat: 3)
        ]
    }
    
    private func calculateTotalCalories() -> Int {
        ingredients.reduce(0) { $0 + $1.calories }
    }
    
    private func calculateTotalProtein() -> Int {
        ingredients.reduce(0) { $0 + $1.protein }
    }
    
    private func calculateTotalCarbs() -> Int {
        ingredients.reduce(0) { $0 + $1.carbs }
    }
    
    private func calculateTotalFat() -> Int {
        ingredients.reduce(0) { $0 + $1.fat }
    }
}

struct IngredientItem: Identifiable {
    let id = UUID()
    var name: String
    var amount: Double
    var unit: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
}

struct IngredientRow: View {
    @Binding var ingredient: IngredientItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(ingredient.calories) cal")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { adjustAmount(-0.5) }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                VStack(spacing: 2) {
                    Text(formatAmount(ingredient.amount))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(ingredient.unit)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(minWidth: 60)
                
                Button(action: { adjustAmount(0.5) }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func adjustAmount(_ change: Double) {
        let newAmount = max(0, ingredient.amount + change)
        let ratio = newAmount / ingredient.amount
        
        ingredient.amount = newAmount
        ingredient.calories = Int(Double(ingredient.calories) * ratio)
        ingredient.protein = Int(Double(ingredient.protein) * ratio)
        ingredient.carbs = Int(Double(ingredient.carbs) * ratio)
        ingredient.fat = Int(Double(ingredient.fat) * ratio)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", amount)
        } else if amount.truncatingRemainder(dividingBy: 0.5) == 0 {
            return String(format: "%.1f", amount)
        } else {
            return String(format: "%.2f", amount)
        }
    }
}

struct NutritionSummaryItem: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

#Preview {
    MealDetailsEditView(meal: MockMeal(
        id: UUID(),
        name: "Grilled Chicken Salad",
        subtitle: "with Avocado & Balsamic Dressing",
        image: "photo",
        calories: 420,
        protein: 35,
        carbs: 12,
        fat: 28,
        fiber: 8,
        confidence: 94,
        timestamp: Date()
    ))
}
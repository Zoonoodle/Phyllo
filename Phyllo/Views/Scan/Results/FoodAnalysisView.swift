//
//  FoodAnalysisView.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI

struct FoodAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEditView = false
    @State private var confidenceAnimation = false
    
    // Mock data
    let mockMeal = MockMeal(
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
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Food image
                        foodImageSection
                        
                        // Food name and confidence
                        foodInfoSection
                        
                        // Nutrition overview
                        nutritionOverviewSection
                        
                        // Detailed nutrition
                        detailedNutritionSection
                        
                        // Action buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Analysis Results")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showEditView) {
            MealDetailsEditView(meal: mockMeal)
        }
    }
    
    // MARK: - Sections
    
    private var foodImageSection: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.05))
            .frame(height: 250)
            .overlay(
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.2))
                    Text("Food image preview")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
            )
            .overlay(
                // Confidence badge
                VStack {
                    HStack {
                        Spacer()
                        confidenceBadge
                    }
                    Spacer()
                }
                .padding(16)
            )
    }
    
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.green)
            
            Text("\(mockMeal.confidence)% Confident")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(confidenceAnimation ? 1.05 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                confidenceAnimation = true
            }
        }
    }
    
    private var foodInfoSection: some View {
        VStack(spacing: 8) {
            Text(mockMeal.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text(mockMeal.subtitle)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var nutritionOverviewSection: some View {
        VStack(spacing: 16) {
            // Calories
            HStack {
                Text("\(mockMeal.calories)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("calories")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.5))
                    .offset(y: 8)
            }
            
            // Macros
            HStack(spacing: 24) {
                MacroView(value: mockMeal.protein, label: "Protein", color: .blue)
                MacroView(value: mockMeal.carbs, label: "Carbs", color: .orange)
                MacroView(value: mockMeal.fat, label: "Fat", color: .yellow)
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
    
    private var detailedNutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Nutrition")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                NutritionRow(label: "Dietary Fiber", value: "\(mockMeal.fiber)g", color: .green)
                NutritionRow(label: "Sugars", value: "3g", color: .pink)
                NutritionRow(label: "Sodium", value: "320mg", color: .cyan)
                NutritionRow(label: "Cholesterol", value: "85mg", color: .orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Edit details button
            Button(action: { showEditView = true }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Edit Details")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Confirm and log button
            Button(action: {
                // Log the meal
                dismiss()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Confirm & Log")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                )
            }
        }
    }
}

struct MacroView: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)g")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// Mock data structure
struct MockMeal {
    let id: UUID
    let name: String
    let subtitle: String
    let image: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let fiber: Int
    let confidence: Int
    let timestamp: Date
}

#Preview {
    FoodAnalysisView()
}
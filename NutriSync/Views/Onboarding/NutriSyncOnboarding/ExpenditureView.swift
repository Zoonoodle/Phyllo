//
//  ExpenditureView.swift
//  NutriSync
//
//  NutriSync Onboarding Screen 5 - Dark Theme
//

import SwiftUI

struct ExpenditureView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var expenditure = 1805
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBar(totalSteps: 31, currentStep: 5)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            // Title
            Text("We estimated your initial expenditure.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 80)
            
            // Calorie display
            Text("\(expenditure) kcal")
                .font(.system(size: 60, weight: .light))
                .foregroundColor(.white)
                .padding(.bottom, 40)
            
            // Question
            Text("Does this look right to you?")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .padding(.bottom, 12)
            
            // Description
            Text("Expenditure is the number of calories you would need to consume to maintain your current weight.")
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button {
                    // User disagrees with the estimate - proceed anyway for now
                    coordinator.tdee = Double(expenditure)
                    coordinator.nextScreen()
                } label: {
                    HStack {
                        Text("No")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(25)
                }
                
                Button {
                    // User agrees with the estimate
                    coordinator.tdee = Double(expenditure)
                    coordinator.nextScreen()
                } label: {
                    HStack {
                        Text("Yes")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(25)
                }
                
                Button {
                    // User is not sure - proceed with estimate
                    coordinator.tdee = Double(expenditure)
                    coordinator.nextScreen()
                } label: {
                    HStack {
                        Text("Not Sure")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color.nutriSyncBackground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 20)
            
            // Back button
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
                .padding(.leading, 20)
                
                Spacer()
            }
            .padding(.bottom, 34)
        }
        .background(Color.nutriSyncBackground)
    }
}

struct ExpenditureView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenditureView()
    }
}
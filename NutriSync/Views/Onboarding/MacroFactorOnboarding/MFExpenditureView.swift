//
//  MFExpenditureView.swift
//  NutriSync
//
//  MacroFactor Replica Screen 5
//

import SwiftUI

struct MFExpenditureView: View {
    @State private var expenditure = 1805
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            MFProgressBar(totalSteps: 14, currentStep: 5)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            
            // Title
            Text("We estimated your initial expenditure.")
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 80)
            
            // Calorie display
            Text("\(expenditure) kcal")
                .font(.system(size: 60, weight: .light))
                .padding(.bottom, 40)
            
            // Question
            Text("Does this look right to you?")
                .font(.system(size: 22))
                .padding(.bottom, 12)
            
            // Description
            Text("Expenditure is the number of calories you would need to consume to maintain your current weight.")
                .font(.system(size: 17))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button {
                    // No action
                } label: {
                    HStack {
                        Text("No")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(25)
                }
                
                Button {
                    // Yes action
                } label: {
                    HStack {
                        Text("Yes")
                            .font(.system(size: 18, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(25)
                }
                
                Button {
                    // Not sure action
                } label: {
                    HStack {
                        Text("Not Sure")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black)
                    .cornerRadius(25)
                }
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 20)
            
            // Back button
            HStack {
                Button {
                    // Back action
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 44, height: 44)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(Circle())
                }
                .padding(.leading, 20)
                
                Spacer()
            }
            .padding(.bottom, 34)
        }
        .background(Color.white)
    }
}

struct MFExpenditureView_Previews: PreviewProvider {
    static var previews: some View {
        MFExpenditureView()
    }
}
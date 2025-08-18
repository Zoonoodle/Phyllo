//
//  GenderSelectionView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI

struct GenderSelectionView: View {
    @Binding var currentPage: Int
    @State private var selectedGender: Gender? = nil
    
    enum Gender: String, CaseIterable {
        case female = "Female"
        case male = "Male"
        
        var icon: String {
            switch self {
            case .female: return "♀"
            case .male: return "♂"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<10) { index in
                        Capsule()
                            .fill(index <= 3 ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Title
                VStack(spacing: 12) {
                    Text("What is your sex?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Your selection will be used to help you visually determine your body fat percentage.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Gender selection buttons
                VStack(spacing: 16) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGender = gender
                            }
                        }) {
                            HStack(spacing: 20) {
                                Text(gender.icon)
                                    .font(.system(size: 28))
                                    .foregroundColor(selectedGender == gender ? .white : .white.opacity(0.7))
                                
                                Text(gender.rawValue)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(selectedGender == gender ? .white : .white.opacity(0.7))
                                
                                Spacer()
                            }
                            .padding(.horizontal, 32)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedGender == gender ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(
                                                selectedGender == gender ? Color.green : Color.white.opacity(0.2),
                                                lineWidth: selectedGender == gender ? 2 : 1
                                            )
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            currentPage -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // Save gender
                        if let gender = selectedGender {
                            UserDefaults.standard.set(gender.rawValue, forKey: "userGender")
                        }
                        
                        withAnimation(.spring(response: 0.3)) {
                            currentPage += 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 18, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(selectedGender != nil ? Color.green : Color.gray)
                        .cornerRadius(30)
                    }
                    .disabled(selectedGender == nil)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    GenderSelectionView(currentPage: .constant(4))
}
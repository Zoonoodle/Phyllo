//
//  SexSelectionView.swift
//  NutriSync
//
//  Sex/Gender selection screen for onboarding
//

import SwiftUI

struct SexSelectionView: View {
    @Environment(NutriSyncOnboardingViewModel.self) private var coordinator
    @State private var selectedSex = "Male"
    @State private var isInitialized = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Title
                Text("What is your sex?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                
                // Options
                VStack(spacing: 20) {
                    // Female option
                    Button {
                        selectedSex = "Female"
                        coordinator.gender = selectedSex
                    } label: {
                        HStack(spacing: 20) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(0))
                                .overlay(
                                    Text("♀")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .frame(width: 40)
                            
                            Text("Female")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .opacity(selectedSex == "Female" ? 1 : 0)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedSex == "Female" ? Color.white : Color.white.opacity(0.2), lineWidth: selectedSex == "Female" ? 2 : 1)
                        )
                        .cornerRadius(16)
                    }
                
                    // Male option
                    Button {
                        selectedSex = "Male"
                        coordinator.gender = selectedSex
                    } label: {
                        HStack(spacing: 20) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .overlay(
                                    Text("♂")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .frame(width: 40)
                            
                            Text("Male")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                        .opacity(selectedSex == "Male" ? 1 : 0)
                                )
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .background(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(selectedSex == "Male" ? Color.white : Color.white.opacity(0.2), lineWidth: selectedSex == "Male" ? 2 : 1)
                        )
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 80) // Space for navigation buttons
            }
        }
        .onAppear {
            loadDataFromCoordinator()
        }
    }
    
    private func loadDataFromCoordinator() {
        guard !isInitialized else { return }
        isInitialized = true
        
        if !coordinator.gender.isEmpty {
            selectedSex = coordinator.gender
        }
    }
}

struct SexSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            SexSelectionView()
        }
    }
}
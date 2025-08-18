//
//  NameInputView.swift
//  NutriSync
//
//  Created on 8/17/25.
//

import SwiftUI

struct NameInputView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicators
                HStack(spacing: 8) {
                    ForEach(0..<10) { index in
                        Capsule()
                            .fill(index <= 1 ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 3)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Title
                VStack(spacing: 12) {
                    Text("What's your name?")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We'll use this to personalize your experience.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Name input field
                VStack(spacing: 8) {
                    TextField("", text: $viewModel.userData.name)
                        .placeholder(when: viewModel.userData.name.isEmpty) {
                            Text("Enter your name")
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                        .padding(.horizontal, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            isNameFocused ? Color.green : Color.white.opacity(0.2),
                                            lineWidth: isNameFocused ? 2 : 1
                                        )
                                )
                        )
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if !viewModel.userData.name.isEmpty {
                                viewModel.nextScreen()
                            }
                        }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Navigation buttons
                HStack {
                    Button(action: {
                        viewModel.previousScreen()
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
                        viewModel.nextScreen()
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
                        .background(viewModel.userData.name.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(30)
                    }
                    .disabled(viewModel.userData.name.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            isNameFocused = true
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
}

// Helper to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    NameInputView(viewModel: OnboardingViewModel())
}
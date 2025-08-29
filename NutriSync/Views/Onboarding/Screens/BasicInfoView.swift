//
//  BasicInfoView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct BasicInfoView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
    }
    
    var body: some View {
        OnboardingScreenBase(
            viewModel: viewModel,
            showBack: true,
            nextTitle: "Next",
            nextAction: {
                // Validate before proceeding
                guard !viewModel.userData.name.isEmpty else { return }
                viewModel.nextScreen()
            }
        ) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        Text("Let's get to know you")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                        
                        VStack(spacing: 24) {
                            // Name input
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What should we call you?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                TextField("", text: $viewModel.userData.name)
                                    .placeholder(when: viewModel.userData.name.isEmpty) {
                                        Text("Enter your name")
                                            .foregroundColor(.white.opacity(0.3))
                                    }
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                    .focused($focusedField, equals: .name)
                                    .submitLabel(.next)
                            }
                            
                            // Birth date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("When were you born?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                DatePicker(
                                    "",
                                    selection: $viewModel.userData.birthDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .accentColor(Color(hex: "00D26A"))
                                .colorScheme(.dark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                            
                            // Biological sex
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What's your biological sex?")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    ForEach(BiologicalSex.allCases, id: \.self) { sex in
                                        SexSelectionButton(
                                            title: sex.rawValue,
                                            isSelected: viewModel.userData.biologicalSex == sex
                                        ) {
                                            viewModel.userData.biologicalSex = sex
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
                .onTapGesture {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            focusedField = .name
        }
    }
}

struct SexSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? Color(hex: "0A0A0A") : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    isSelected ? 
                    Color(hex: "00D26A") : 
                    Color.white.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? 
                            Color.clear : 
                            Color.white.opacity(0.1), 
                            lineWidth: 1
                        )
                )
                .cornerRadius(12)
        }
    }
}

// TextField placeholder modifier
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview
struct BasicInfoView_Previews: PreviewProvider {
    static var previews: some View {
        BasicInfoView(viewModel: OnboardingViewModel())
            .preferredColorScheme(.dark)
    }
}
//
//  OnboardingPreviewView.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//  For testing onboarding screens

import SwiftUI

struct OnboardingPreviewView: View {
    @State private var selectedScreen = 0
    
    let screens = [
        ("Permissions", AnyView(PermissionsView(viewModel: OnboardingViewModel()))),
        ("Welcome", AnyView(WelcomeView(viewModel: OnboardingViewModel()))),
        ("Impact Calculator", AnyView(ImpactCalculatorView(viewModel: OnboardingViewModel()))),
        ("Good News", AnyView(GoodNewsView(viewModel: OnboardingViewModel())))
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<screens.count, id: \.self) { index in
                        Button {
                            withAnimation {
                                selectedScreen = index
                            }
                        } label: {
                            Text(screens[index].0)
                                .font(.caption)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedScreen == index ? 
                                    Color(hex: "00D26A") : 
                                    Color.white.opacity(0.1)
                                )
                                .foregroundColor(
                                    selectedScreen == index ? 
                                    Color(hex: "0A0A0A") : 
                                    .white
                                )
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
            .background(Color(hex: "0A0A0A"))
            
            // Screen content
            TabView(selection: $selectedScreen) {
                ForEach(0..<screens.count, id: \.self) { index in
                    screens[index].1
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct OnboardingPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPreviewView()
    }
}
//
//  OnboardingNavigation.swift
//  NutriSync
//
//  Created by Claude on 8/14/25.
//

import SwiftUI

struct OnboardingNavigation: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let showBack: Bool
    let nextTitle: String
    let nextAction: (() -> Void)?
    
    init(
        viewModel: OnboardingViewModel,
        showBack: Bool = true,
        nextTitle: String = "Next",
        nextAction: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.showBack = showBack
        self.nextTitle = nextTitle
        self.nextAction = nextAction
    }
    
    var body: some View {
        HStack {
            // Back button
            if showBack {
                Button {
                    viewModel.previousScreen()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .contentShape(Rectangle())
                }
            } else {
                Spacer()
                    .frame(width: 50)
            }
            
            Spacer()
            
            // Next button (MacroFactor style)
            Button {
                if let action = nextAction {
                    action()
                } else {
                    viewModel.nextScreen()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(nextTitle)
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .frame(height: 50)
                .background(Color.black)
                .cornerRadius(25)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
    }
}

// Updated base view for onboarding screens
struct OnboardingScreenBase<Content: View>: View {
    @ObservedObject var viewModel: OnboardingViewModel
    let showBack: Bool
    let nextTitle: String
    let nextAction: (() -> Void)?
    @ViewBuilder let content: Content
    
    init(
        viewModel: OnboardingViewModel,
        showBack: Bool = true,
        nextTitle: String = "Next",
        nextAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.viewModel = viewModel
        self.showBack = showBack
        self.nextTitle = nextTitle
        self.nextAction = nextAction
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Navigation
            OnboardingNavigation(
                viewModel: viewModel,
                showBack: showBack,
                nextTitle: nextTitle,
                nextAction: nextAction
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "0A0A0A"))
    }
}
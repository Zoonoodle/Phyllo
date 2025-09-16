//
//  SectionNavigationView.swift
//  NutriSync
//
//  Section navigation header for NutriSync onboarding
//

import SwiftUI

struct SectionNavigationView: View {
    let currentSection: NutriSyncOnboardingSection
    let completedSections: Set<NutriSyncOnboardingSection>
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(NutriSyncOnboardingSection.allCases, id: \.self) { section in
                if section != NutriSyncOnboardingSection.allCases.first {
                    // Connection line
                    Rectangle()
                        .fill(lineColor(for: section))
                        .frame(height: 2)
                        .frame(maxWidth: 40)
                }
                
                // Section icon
                ZStack {
                    Circle()
                        .fill(backgroundColor(for: section))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(iconColor(for: section))
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func backgroundColor(for section: NutriSyncOnboardingSection) -> Color {
        if section == currentSection {
            return Color.white
        } else if completedSections.contains(section) {
            return Color.white
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    private func iconColor(for section: NutriSyncOnboardingSection) -> Color {
        if section == currentSection || completedSections.contains(section) {
            return Color.nutriSyncBackground
        } else {
            return Color.white.opacity(0.5)
        }
    }
    
    private func lineColor(for section: NutriSyncOnboardingSection) -> Color {
        let previousSection = NutriSyncOnboardingSection.allCases[
            NutriSyncOnboardingSection.allCases.firstIndex(of: section)! - 1
        ]
        
        if completedSections.contains(previousSection) {
            return Color.white.opacity(0.5)
        } else {
            return Color.white.opacity(0.2)
        }
    }
}

// MARK: - Section Intro View
struct SectionIntroView: View {
    let section: NutriSyncOnboardingSection
    let completedSections: Set<NutriSyncOnboardingSection>
    let onContinue: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            Color.nutriSyncBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button to go back to previous section
                HStack {
                    Spacer()
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 8)
                
                // Section title
                Text(section == .basics ? "Welcome" : section.rawValue)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 32)
                
                // Navigation dots
                SectionNavigationView(
                    currentSection: section,
                    completedSections: completedSections
                )
                .padding(.top, 40)
                
                // Section subtitle
                Text(section.rawValue)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.top, 48)
                
                // Description
                Text(section.description)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Continue button
                Button {
                    onContinue()
                } label: {
                    Text(section.buttonTitle)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.nutriSyncBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
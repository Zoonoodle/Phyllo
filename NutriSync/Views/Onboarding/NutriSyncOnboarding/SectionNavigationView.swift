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

    // Filter out story section from checkpoint display
    private var visibleSections: [NutriSyncOnboardingSection] {
        NutriSyncOnboardingSection.allCases.filter { $0 != .story }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(visibleSections, id: \.self) { section in
                if section != visibleSections.first {
                    // Connection line with proportional width based on previous section's screen count
                    Rectangle()
                        .fill(lineColor(for: section))
                        .frame(height: 2)
                        .frame(width: lineWidth(for: section))
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
        .padding(.horizontal, 48)
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

    private func lineWidth(for section: NutriSyncOnboardingSection) -> CGFloat {
        // Get the previous section (the line connects from previous to current)
        guard let sectionIndex = NutriSyncOnboardingSection.allCases.firstIndex(of: section),
              sectionIndex > 0 else {
            return 40 // Fallback width
        }

        let previousSection = NutriSyncOnboardingSection.allCases[sectionIndex - 1]

        // Get screen count for previous section
        let screenCount = NutriSyncOnboardingFlow.sections[previousSection]?.count ?? 1

        // Calculate proportional width
        // Base width of 8 points per screen, minimum 16, maximum 80
        let baseWidthPerScreen: CGFloat = 8
        let calculatedWidth = CGFloat(screenCount) * baseWidthPerScreen
        return min(max(calculatedWidth, 16), 80)
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
                .padding(.horizontal, 40)
                
                // Section title
                Text(section == .basics ? "Welcome" : section.rawValue)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 48)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 48)
                    .padding(.top, 48)

                // Description
                Text(section.description)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 48)
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
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}
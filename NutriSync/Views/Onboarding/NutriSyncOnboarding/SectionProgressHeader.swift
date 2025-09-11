//
//  SectionProgressHeader.swift
//  NutriSync
//
//  Section-based progress header for onboarding flow
//

import SwiftUI

struct SectionProgressHeader: View {
    let currentSection: NutriSyncOnboardingSection
    let nextSection: NutriSyncOnboardingSection?
    let progress: Double // 0.0 to 1.0 within section
    
    var body: some View {
        HStack(spacing: 12) {
            // Current section icon
            Image(systemName: currentSection.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                )
            
            // Progress dashes
            ProgressDashes(progress: progress)
                .frame(height: 2)
                .frame(maxWidth: .infinity)
            
            // Next section icon (grayed if exists)
            if let next = nextSection {
                Image(systemName: next.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
            } else {
                // Finish flag for last section
                Image(systemName: "flag.checkered")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ProgressDashes: View {
    let progress: Double
    let dashCount: Int = 8
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<dashCount, id: \.self) { index in
                    let isCompleted = Double(index) / Double(dashCount) <= progress
                    
                    Rectangle()
                        .fill(isCompleted ? Color.white : Color.white.opacity(0.2))
                        .frame(height: 2)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }
            }
        }
    }
}

// Helper extension to calculate progress within section
extension NutriSyncOnboardingViewModel {
    func getCurrentSectionProgress() -> (section: NutriSyncOnboardingSection, nextSection: NutriSyncOnboardingSection?, progress: Double) {
        guard let currentScreen = currentScreen else {
            return (.basics, .notice, 0.0)
        }
        
        // Find current section
        guard let section = NutriSyncOnboardingFlow.section(for: currentScreen) else {
            return (.basics, .notice, 0.0)
        }
        
        // Get screens in current section
        let sectionScreens = NutriSyncOnboardingFlow.screens(for: section)
        
        // Calculate progress within section
        guard let screenIndex = sectionScreens.firstIndex(of: currentScreen) else {
            return (section, nil, 0.0)
        }
        
        let progress = Double(screenIndex + 1) / Double(sectionScreens.count)
        
        // Find next section
        let allSections = NutriSyncOnboardingSection.allCases
        guard let currentSectionIndex = allSections.firstIndex(of: section) else {
            return (section, nil, progress)
        }
        
        let nextSection = currentSectionIndex < allSections.count - 1 ? allSections[currentSectionIndex + 1] : nil
        
        return (section, nextSection, progress)
    }
}

struct SectionProgressHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SectionProgressHeader(
                currentSection: .basics,
                nextSection: .notice,
                progress: 0.5
            )
            
            SectionProgressHeader(
                currentSection: .goalSetting,
                nextSection: .program,
                progress: 0.8
            )
            
            SectionProgressHeader(
                currentSection: .finish,
                nextSection: nil,
                progress: 1.0
            )
        }
        .padding()
        .background(Color.nutriSyncBackground)
    }
}
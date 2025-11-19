//
//  OnboardingSectionData.swift
//  NutriSync
//
//  Section structure and flow for NutriSync onboarding
//

import SwiftUI

// MARK: - Section Type
enum NutriSyncOnboardingSection: String, CaseIterable {
    case story = "Welcome"
    case basics = "Basics"
    case notice = "Notice"
    case goalSetting = "Goal Setting"
    case program = "Program"
    case finish = "Finish"

    var icon: String {
        switch self {
        case .story: return "sparkles"
        case .basics: return "person.fill"
        case .notice: return "shield.fill"
        case .goalSetting: return "target"
        case .program: return "book.fill"
        case .finish: return "flag.fill"
        }
    }

    var description: String {
        switch self {
        case .story:
            return "Welcome to NutriSync - Your personalized meal planning system"
        case .basics:
            return "NutriSync's optimal eating windows are based on estimates of your daily energy expenditure. We will fine-tune those estimates over time. For now, we need some basic information to calculate your starting point."
        case .notice:
            return "Health Disclaimer"
        case .goalSetting:
            return "NutriSync's targets will be customized to keep you on track with the goal you specify. Don't worry – you can update your goal any time."
        case .program:
            return "We will now create a nutrition program based on your information. It will dynamically adapt to your energy expenditure every week. Don't worry – you can always change the program or manually create one later."
        case .finish:
            return "Review Your Program"
        }
    }

    var buttonTitle: String {
        switch self {
        case .story: return "Discover NutriSync"
        case .basics: return "Begin with the basics"
        case .notice: return "Accept and Continue"
        case .goalSetting: return "Go to Goal Setup"
        case .program: return "Go to Program Design"
        case .finish: return "Finish Setup"
        }
    }
}

// MARK: - Screen Assignment
struct NutriSyncOnboardingFlow {
    static let sections: [NutriSyncOnboardingSection: [String]] = [
        .story: [
            "Welcome to NutriSync",
            "The Plan Advantage",
            "Your Day Optimized",
            "Ready to Build"
        ],
        .basics: [
            "Sex Selection",
            "Birth Date",
            "Height",
            "Weight",
            "Exercise",
            "Activity",
            "Expenditure"
        ],
        .notice: [
            "Health Disclaimer",
            "Your Plan Evolves"
        ],
        .goalSetting: [
            "Your Transformation",
            "Specific Goals",  // NEW: Multi-select specific goals (shown FIRST)
            "Goal Selection",  // Traditional goal selection (conditional based on weight goal)
            "Trend Weight",  // Conditional: shown if weightManagement selected
            "Weight Goal",   // Conditional: shown if weightManagement selected
            "Goal Summary"
            // ========== TEMPORARILY DISABLED - Remaining Goal Setting Refactor Screens ==========
            // These screens are fully implemented but temporarily removed from flow
            // To re-enable: uncomment the lines below
            // "Goal Ranking",  // NEW: Conditional - shown if 2+ goals selected
            // "Sleep Preferences",  // NEW: Conditional - shown if betterSleep in rank 1-2
            // "Energy Preferences",  // NEW: Conditional - shown if steadyEnergy in rank 1-2
            // "Muscle Preferences",  // NEW: Conditional - shown if muscleGain in rank 1-2
            // "Performance Preferences",  // NEW: Conditional - shown if athleticPerformance in rank 1-2
            // "Metabolic Preferences",  // NEW: Conditional - shown if metabolicHealth in rank 1-2
            // "Goal Impact Preview"  // NEW: Preview of how goals will shape meal plan
            // ====================================================================================
        ],
        .program: [
            "Diet Preference",
            "Sleep Schedule",
            "Meal Frequency",
            "Dietary Restrictions",
            "Macro Customization"
        ],
        .finish: [
            "Your Plan is Ready",
            "Review Program"
        ]
    ]
    
    static func screens(
        for section: NutriSyncOnboardingSection,
        goal: String? = nil,
        selectedSpecificGoals: Set<SpecificGoal> = [],
        rankedGoals: [RankedGoal] = [],
        hasCompletedSpecificGoals: Bool = false
    ) -> [String] {
        var screens = sections[section] ?? []

        // Dynamic goal setting flow based on specific goals selection
        if section == .goalSetting {
            // BEFORE specific goals selected: show minimal initial flow
            if !hasCompletedSpecificGoals {
                return ["Your Transformation", "Specific Goals"]
            }

            // AFTER specific goals selected: build complete dynamic flow
            screens = ["Your Transformation", "Specific Goals"]

            // Add Goal Ranking if 2+ goals selected
            if selectedSpecificGoals.count >= 2 {
                screens.append("Goal Ranking")
            }

            // IMPORTANT: Weight Management is ALWAYS shown if selected (regardless of rank)
            if selectedSpecificGoals.contains(.weightManagement) {
                screens.append("Goal Selection")

                // Further conditional based on traditional goal choice
                if let goal = goal?.lowercased() {
                    if goal == "maintain weight" {
                        screens.append("Trend Weight")
                    } else if goal == "lose weight" || goal == "gain weight" {
                        screens.append("Weight Goal")
                    }
                }
            }

            // ADAPTIVE FLOW: Add preference screens for rank 1-2 goals only
            // Note: Weight Management handled separately above (always shown if selected)

            // Use ranked goals if available (after ranking screen)
            if !rankedGoals.isEmpty {
                // Sort by rank to ensure correct order
                let sortedGoals = rankedGoals.sorted { $0.rank < $1.rank }

                // Add preference screens for top 2 ranked goals only
                for rankedGoal in sortedGoals where rankedGoal.rank < 2 {
                    switch rankedGoal.goal {
                    case .betterSleep:
                        screens.append("Sleep Preferences")
                    case .steadyEnergy:
                        screens.append("Energy Preferences")
                    case .muscleGain:
                        screens.append("Muscle Preferences")
                    case .athleticPerformance:
                        screens.append("Performance Preferences")
                    case .metabolicHealth:
                        screens.append("Metabolic Preferences")
                    case .weightManagement:
                        // Already handled above - weight management always shown
                        break
                    }
                }

            }

            // Always end with Goal Summary
            screens.append("Goal Summary")

            return screens
        }

        return screens
    }
    
    static func section(for screenName: String) -> NutriSyncOnboardingSection? {
        for (section, screens) in sections {
            if screens.contains(screenName) {
                return section
            }
        }
        return nil
    }
}
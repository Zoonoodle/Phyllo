//
//  OnboardingSectionData.swift
//  NutriSync
//
//  Section structure and flow for NutriSync onboarding
//

import SwiftUI

// MARK: - Section Type
enum NutriSyncOnboardingSection: String, CaseIterable {
    case basics = "Basics"
    case notice = "Notice"
    case goalSetting = "Goal Setting"
    case program = "Program"
    case finish = "Finish"
    
    var icon: String {
        switch self {
        case .basics: return "person.fill"
        case .notice: return "shield.fill"
        case .goalSetting: return "target"
        case .program: return "book.fill"
        case .finish: return "flag.fill"
        }
    }
    
    var description: String {
        switch self {
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
            "Not to Worry"
        ],
        .goalSetting: [
            "Goal Intro",
            "Goal Selection",
            "Maintenance Strategy",
            "Weight Goal",
            "Pre-Workout Nutrition",
            "Post-Workout Nutrition"
        ],
        .program: [
            "Almost There",
            "Diet Preference",
            "Training Plan",
            "Calorie Floor",
            "Sleep Schedule",
            "Meal Frequency",
            "Eating Window",
            "Dietary Restrictions",
            "Meal Timing",
            "Window Flexibility"
        ],
        .finish: [
            "Review Program"
        ]
    ]
    
    static func screens(for section: NutriSyncOnboardingSection) -> [String] {
        sections[section] ?? []
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
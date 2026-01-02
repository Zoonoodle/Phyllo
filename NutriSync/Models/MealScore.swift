//
//  MealScore.swift
//  NutriSync
//
//  Scoring models for health, window, and daily scores
//

import Foundation
import FirebaseFirestore

// MARK: - Health Score

/// Health score calculated from AI-provided health factors
struct HealthScore: Codable, Equatable {
    let score: Int  // 0-100 (internal)
    let factors: [HealthFactor]
    let reasoning: String?
    let calculatedAt: Date

    /// Detailed breakdown of score components (optional, for enhanced display)
    var breakdown: MealScoreBreakdown?

    /// Human-readable insight explaining the score (replaces generic reasoning in UI)
    var insight: String?

    struct HealthFactor: Codable, Equatable {
        let name: String       // "whole_foods", "high_fiber", "processed", etc.
        let impact: Impact
        let weight: Double     // 0.0-1.0 (importance)

        enum Impact: String, Codable {
            case positive
            case neutral
            case negative
        }
    }

    // MARK: - Display Score (1-10 scale)

    /// Score on 1-10 scale for display
    var displayScore: Double {
        Double(score) / 10.0
    }

    /// Formatted score string (e.g., "8.6")
    var displayScoreFormatted: String {
        String(format: "%.1f", displayScore)
    }

    /// Score color based on value
    var scoreColorName: String {
        switch displayScore {
        case 8.5...10.0: return "excellent"
        case 7.0..<8.5: return "good"
        case 5.0..<7.0: return "okay"
        case 3.0..<5.0: return "poor"
        default: return "bad"
        }
    }
}

// MARK: - Meal Score Breakdown

/// Detailed breakdown of meal health score components
struct MealScoreBreakdown: Codable, Equatable {
    /// Base score before adjustments (always 5.0)
    let baseScore: Double

    /// Macro balance contribution (30% weight)
    let macroBalance: CategoryScore

    /// Food quality contribution (25% weight)
    let foodQuality: CategoryScore

    /// Protein efficiency contribution (20% weight)
    let proteinEfficiency: CategoryScore

    /// Micronutrient density contribution (15% weight)
    let micronutrients: CategoryScore

    /// Portion size appropriateness (10% weight)
    let portionSize: CategoryScore

    /// Total adjustment from all categories
    var totalAdjustment: Double {
        macroBalance.subtotal +
        foodQuality.subtotal +
        proteinEfficiency.subtotal +
        micronutrients.subtotal +
        portionSize.subtotal
    }

    /// Final calculated score
    var finalScore: Double {
        baseScore + totalAdjustment
    }
}

/// Score contribution from a single category
struct CategoryScore: Codable, Equatable {
    /// Display label (e.g., "Macro Balance")
    let label: String

    /// Weight of this category (0-1, e.g., 0.30 for 30%)
    let weight: Double

    /// Individual factor contributions
    let factors: [FactorContribution]

    /// Subtotal contribution from this category
    var subtotal: Double {
        factors.reduce(0) { $0 + $1.value }
    }
}

/// Individual factor's contribution to score
struct FactorContribution: Codable, Equatable {
    /// Factor name (e.g., "Protein ratio")
    let name: String

    /// Description (e.g., "29% of calories")
    let description: String

    /// Contribution value (+/- adjustment)
    let value: Double
}

// MARK: - Window Score

/// Window adherence score based on tolerance-based macro matching
struct WindowScore: Codable, Equatable {
    let score: Int  // 0-100 (internal)
    let windowId: String
    let breakdown: MacroScoreBreakdown
    let calculatedAt: Date

    /// Per-macro adherence factors with contributions
    var factors: [AdherenceFactor]?

    /// Human-readable insight explaining the score
    var insight: String?

    struct MacroScoreBreakdown: Codable, Equatable {
        let calorieScore: Int    // 0-100
        let proteinScore: Int    // 0-100
        let carbScore: Int       // 0-100
        let fatScore: Int        // 0-100

        /// Weighted average based on window purpose
        var weightedAverage: Int {
            // Default equal weights - actual weighting done in ScoringService
            (calorieScore + proteinScore + carbScore + fatScore) / 4
        }
    }

    // MARK: - Display Score (1-10 scale)

    /// Score on 1-10 scale for display
    var displayScore: Double {
        Double(score) / 10.0
    }

    /// Formatted score string (e.g., "3.9")
    var displayScoreFormatted: String {
        String(format: "%.1f", displayScore)
    }

    /// Generate insight text based on adherence
    var generatedInsight: String {
        if let existingInsight = insight {
            return existingInsight
        }

        // Generate based on breakdown
        let totalTarget = 400 // Placeholder - actual targets come from window
        let overUnder = breakdown.calorieScore < 50 ? "over" : "under"

        if breakdown.weightedAverage >= 90 {
            return "On target"
        } else if breakdown.weightedAverage >= 70 {
            return "Close to target"
        } else if breakdown.calorieScore < 50 {
            return "Over target"
        } else {
            return "Under target"
        }
    }
}

/// Per-macro adherence factor for window scoring
struct AdherenceFactor: Codable, Equatable {
    /// Macro name (e.g., "Calories", "Protein")
    let macro: String

    /// Actual amount consumed
    let actual: Int

    /// Target amount for window
    let target: Int

    /// Percentage of target (e.g., 167 for 167%)
    var percentageOfTarget: Int {
        guard target > 0 else { return 0 }
        return Int((Double(actual) / Double(target)) * 100)
    }

    /// Contribution to score (+/-)
    let contribution: Double

    /// Formatted percentage string
    var percentageText: String {
        "\(percentageOfTarget)% of target"
    }
}

// MARK: - Daily Score

/// Aggregate daily score from all windows
struct DailyScore: Codable, Equatable, Identifiable {
    let id: String  // Date string: "yyyy-MM-dd"
    let date: Date
    let score: Int  // 0-100 (internal)
    let windowScores: [String: Int]  // windowId -> score
    let averageHealthScore: Int?  // Average of meal health scores
    let completedWindows: Int
    let totalWindows: Int
    let calculatedAt: Date

    /// Enhanced breakdown with sub-scores
    var breakdown: DailyScoreBreakdown?

    /// Human-readable insight for the day
    var insight: String?

    // MARK: - Display Score (1-10 scale)

    /// Score on 1-10 scale for display
    var displayScore: Double {
        Double(score) / 10.0
    }

    /// Formatted score string (e.g., "6.2")
    var displayScoreFormatted: String {
        String(format: "%.1f", displayScore)
    }
}

/// Enhanced breakdown for daily score
struct DailyScoreBreakdown: Codable, Equatable {
    /// Window adherence component (40% weight)
    let adherenceScore: Int  // 0-100

    /// Food quality component (25% weight)
    let foodQualityScore: Int  // 0-100

    /// Timing component (20% weight)
    let timingScore: Int  // 0-100

    /// Consistency component (15% weight)
    let consistencyScore: Int  // 0-100

    // Sub-component descriptions
    let adherenceDetail: String  // "3 of 3 windows on target"
    let qualityDetail: String    // "Average meal score: 8.2"
    let timingDetail: String     // "All meals within windows"
    let consistencyDetail: String  // "Calories front-loaded"

    // Display scores (1-10)
    var adherenceDisplayScore: Double { Double(adherenceScore) / 10.0 }
    var qualityDisplayScore: Double { Double(foodQualityScore) / 10.0 }
    var timingDisplayScore: Double { Double(timingScore) / 10.0 }
    var consistencyDisplayScore: Double { Double(consistencyScore) / 10.0 }
}

// MARK: - Search Source

/// Search source from Gemini grounding metadata
struct SearchSource: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let url: String
    let sourceType: SourceType

    enum SourceType: String, Codable {
        case usda = "USDA"
        case restaurant = "Restaurant"
        case academic = "Academic"
        case general = "General"
    }

    init(id: UUID = UUID(), title: String, url: String, sourceType: SourceType = .general) {
        self.id = id
        self.title = title
        self.url = url
        self.sourceType = sourceType
    }

    /// Display label for UI
    var displayLabel: String {
        switch sourceType {
        case .usda: return "USDA Verified"
        case .restaurant: return "Official Menu"
        case .academic: return "Research-Backed"
        case .general: return "Verified"
        }
    }
}

// MARK: - Firestore Conversion

extension HealthScore {
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "score": score,
            "calculatedAt": calculatedAt
        ]

        if let reasoning = reasoning {
            data["reasoning"] = reasoning
        }

        data["factors"] = factors.map { factor in
            [
                "name": factor.name,
                "impact": factor.impact.rawValue,
                "weight": factor.weight
            ]
        }

        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> HealthScore? {
        guard let score = data["score"] as? Int,
              let calculatedAt = (data["calculatedAt"] as? Timestamp)?.dateValue() else {
            return nil
        }

        let reasoning = data["reasoning"] as? String

        var factors: [HealthFactor] = []
        if let factorsData = data["factors"] as? [[String: Any]] {
            factors = factorsData.compactMap { factorData in
                guard let name = factorData["name"] as? String,
                      let impactRaw = factorData["impact"] as? String,
                      let impact = HealthFactor.Impact(rawValue: impactRaw),
                      let weight = factorData["weight"] as? Double else {
                    return nil
                }
                return HealthFactor(name: name, impact: impact, weight: weight)
            }
        }

        return HealthScore(
            score: score,
            factors: factors,
            reasoning: reasoning,
            calculatedAt: calculatedAt
        )
    }
}

extension SearchSource {
    func toFirestore() -> [String: Any] {
        [
            "id": id.uuidString,
            "title": title,
            "url": url,
            "sourceType": sourceType.rawValue
        ]
    }

    static func fromFirestore(_ data: [String: Any]) -> SearchSource? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = data["title"] as? String,
              let url = data["url"] as? String else {
            return nil
        }

        let sourceType = (data["sourceType"] as? String).flatMap { SourceType(rawValue: $0) } ?? .general

        return SearchSource(id: id, title: title, url: url, sourceType: sourceType)
    }
}

extension WindowScore {
    func toFirestore() -> [String: Any] {
        [
            "score": score,
            "windowId": windowId,
            "breakdown": [
                "calorieScore": breakdown.calorieScore,
                "proteinScore": breakdown.proteinScore,
                "carbScore": breakdown.carbScore,
                "fatScore": breakdown.fatScore
            ],
            "calculatedAt": calculatedAt
        ]
    }

    static func fromFirestore(_ data: [String: Any]) -> WindowScore? {
        guard let score = data["score"] as? Int,
              let windowId = data["windowId"] as? String,
              let breakdownData = data["breakdown"] as? [String: Any],
              let calculatedAt = (data["calculatedAt"] as? Timestamp)?.dateValue() else {
            return nil
        }

        let breakdown = MacroScoreBreakdown(
            calorieScore: breakdownData["calorieScore"] as? Int ?? 0,
            proteinScore: breakdownData["proteinScore"] as? Int ?? 0,
            carbScore: breakdownData["carbScore"] as? Int ?? 0,
            fatScore: breakdownData["fatScore"] as? Int ?? 0
        )

        return WindowScore(
            score: score,
            windowId: windowId,
            breakdown: breakdown,
            calculatedAt: calculatedAt
        )
    }
}

extension DailyScore {
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "date": date,
            "score": score,
            "windowScores": windowScores,
            "completedWindows": completedWindows,
            "totalWindows": totalWindows,
            "calculatedAt": calculatedAt
        ]

        if let avgHealth = averageHealthScore {
            data["averageHealthScore"] = avgHealth
        }

        return data
    }

    static func fromFirestore(_ data: [String: Any]) -> DailyScore? {
        guard let id = data["id"] as? String,
              let date = (data["date"] as? Timestamp)?.dateValue(),
              let score = data["score"] as? Int,
              let calculatedAt = (data["calculatedAt"] as? Timestamp)?.dateValue() else {
            return nil
        }

        return DailyScore(
            id: id,
            date: date,
            score: score,
            windowScores: data["windowScores"] as? [String: Int] ?? [:],
            averageHealthScore: data["averageHealthScore"] as? Int,
            completedWindows: data["completedWindows"] as? Int ?? 0,
            totalWindows: data["totalWindows"] as? Int ?? 0,
            calculatedAt: calculatedAt
        )
    }
}

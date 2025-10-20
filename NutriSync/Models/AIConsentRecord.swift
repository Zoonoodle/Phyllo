//
//  AIConsentRecord.swift
//  NutriSync
//
//  Legal record of user consent for AI processing and data sharing
//  Required for CCPA/CPRA compliance
//

import Foundation
import FirebaseFirestore

/// Record of user's consent to AI processing and third-party data sharing
/// Saved to Firestore for legal compliance and audit trail
struct AIConsentRecord: Codable {
    let userId: String
    let consentedAt: Date
    let aiMealAnalysisConsent: Bool
    let aiWindowGenerationConsent: Bool
    let googleDataSharingConsent: Bool
    let consentVersion: String

    init(
        userId: String,
        consentedAt: Date = Date(),
        aiMealAnalysisConsent: Bool = true,
        aiWindowGenerationConsent: Bool = true,
        googleDataSharingConsent: Bool = true,
        consentVersion: String = "1.0"
    ) {
        self.userId = userId
        self.consentedAt = consentedAt
        self.aiMealAnalysisConsent = aiMealAnalysisConsent
        self.aiWindowGenerationConsent = aiWindowGenerationConsent
        self.googleDataSharingConsent = googleDataSharingConsent
        self.consentVersion = consentVersion
    }

    /// Convert to Firestore-compatible dictionary
    func toFirestore() -> [String: Any] {
        return [
            "userId": userId,
            "consentedAt": Timestamp(date: consentedAt),
            "aiMealAnalysisConsent": aiMealAnalysisConsent,
            "aiWindowGenerationConsent": aiWindowGenerationConsent,
            "googleDataSharingConsent": googleDataSharingConsent,
            "consentVersion": consentVersion
        ]
    }

    /// Initialize from Firestore document
    static func fromFirestore(_ data: [String: Any]) -> AIConsentRecord? {
        guard let userId = data["userId"] as? String,
              let consentVersion = data["consentVersion"] as? String else {
            return nil
        }

        let consentedAt = (data["consentedAt"] as? Timestamp)?.dateValue() ?? Date()
        let aiMealAnalysis = data["aiMealAnalysisConsent"] as? Bool ?? false
        let aiWindowGen = data["aiWindowGenerationConsent"] as? Bool ?? false
        let googleSharing = data["googleDataSharingConsent"] as? Bool ?? false

        return AIConsentRecord(
            userId: userId,
            consentedAt: consentedAt,
            aiMealAnalysisConsent: aiMealAnalysis,
            aiWindowGenerationConsent: aiWindowGen,
            googleDataSharingConsent: googleSharing,
            consentVersion: consentVersion
        )
    }
}

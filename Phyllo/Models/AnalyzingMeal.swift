//
//  AnalyzingMeal.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import Foundation
import FirebaseFirestore

struct AnalyzingMeal: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    var windowId: UUID? // Which window this meal will belong to
    let imageData: Data? // Store captured image data
    let voiceDescription: String? // Optional voice description
    
    init(id: UUID = UUID(), timestamp: Date, windowId: UUID? = nil, imageData: Data? = nil, voiceDescription: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.windowId = windowId
        self.imageData = imageData
        self.voiceDescription = voiceDescription
    }
    
    // Convert to LoggedMeal once analysis is complete
    func toLoggedMeal(name: String, calories: Int, protein: Int, carbs: Int, fat: Int) -> LoggedMeal {
        LoggedMeal(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp,
            windowId: windowId
        )
    }
}

// MARK: - Firestore Conversion
extension AnalyzingMeal {
    func toFirestore() -> [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "timestamp": Timestamp(date: timestamp)
        ]
        
        if let windowId = windowId {
            data["windowId"] = windowId.uuidString
        }
        
        if let imageData = imageData {
            data["imageDataSize"] = imageData.count
        }
        
        if let voiceDescription = voiceDescription {
            data["voiceDescription"] = voiceDescription
        }
        
        return data
    }
    
    static func fromFirestore(_ data: [String: Any]) -> AnalyzingMeal? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        let windowId: UUID? = {
            if let windowIdString = data["windowId"] as? String {
                return UUID(uuidString: windowIdString)
            }
            return nil
        }()
        
        let meal = AnalyzingMeal(
            id: id,
            timestamp: timestamp.dateValue(),
            windowId: windowId,
            imageData: nil,
            voiceDescription: data["voiceDescription"] as? String
        )
        
        // Note: We don't store actual image data in Firestore, just the size for reference
        
        return meal
    }
}
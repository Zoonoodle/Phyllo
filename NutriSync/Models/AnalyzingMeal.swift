//
//  AnalyzingMeal.swift
//  NutriSync
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
    var analysisMetadata: AnalysisMetadata? // Track analysis complexity and tools used
    
    init(id: UUID = UUID(), timestamp: Date, windowId: UUID? = nil, imageData: Data? = nil, voiceDescription: String? = nil, analysisMetadata: AnalysisMetadata? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.windowId = windowId
        self.imageData = imageData
        self.voiceDescription = voiceDescription
        self.analysisMetadata = analysisMetadata
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

// MARK: - Analysis Metadata
struct AnalysisMetadata: Codable, Equatable {
    let toolsUsed: [AnalysisTool]
    let complexity: ComplexityRating
    let analysisTime: TimeInterval
    let confidence: Double
    let brandDetected: String?
    let ingredientCount: Int
    
    enum AnalysisTool: String, Codable, CaseIterable {
        case brandSearch = "brand_search"
        case deepAnalysis = "deep_analysis"
        case nutritionLookup = "nutrition_lookup"
        
        var displayName: String {
            switch self {
            case .brandSearch: return "Restaurant Search"
            case .deepAnalysis: return "Deep Analysis"
            case .nutritionLookup: return "Nutrition Database"
            }
        }
        
        var icon: String {
            switch self {
            case .brandSearch: return "magnifyingglass.circle.fill"
            case .deepAnalysis: return "eye.circle.fill"
            case .nutritionLookup: return "book.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .brandSearch: return "#4CAF50" // Green
            case .deepAnalysis: return "#2196F3" // Blue
            case .nutritionLookup: return "#FF9800" // Orange
            }
        }
    }
    
    enum ComplexityRating: String, Codable, CaseIterable {
        case simple
        case moderate
        case complex
        case restaurant
        
        var displayName: String {
            switch self {
            case .simple: return "Simple"
            case .moderate: return "Moderate"
            case .complex: return "Complex"
            case .restaurant: return "Restaurant"
            }
        }
        
        var icon: String {
            switch self {
            case .simple: return "circle.fill"
            case .moderate: return "circle.lefthalf.filled"
            case .complex: return "circle.grid.3x3.fill"
            case .restaurant: return "storefront.fill"
            }
        }
        
        var description: String {
            switch self {
            case .simple: return "Quick analysis"
            case .moderate: return "Standard analysis"
            case .complex: return "Deep ingredient analysis"
            case .restaurant: return "Official nutrition data"
            }
        }
    }
}
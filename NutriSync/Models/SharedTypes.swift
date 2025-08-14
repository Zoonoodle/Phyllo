//
//  SharedTypes.swift
//  NutriSync
//
//  Created on 8/6/25.
//

import Foundation

// MARK: - Gender
enum Gender: String, CaseIterable, Codable {
    case male = "male"
    case female = "female"
    case other = "other"
    case preferNotToSay = "preferNotToSay"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}
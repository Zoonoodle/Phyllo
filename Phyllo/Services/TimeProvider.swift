//
//  TimeProvider.swift
//  Phyllo
//
//  Created on 7/28/25.
//

import Foundation

class TimeProvider: ObservableObject {
    static let shared = TimeProvider()
    
    @Published private var simulatedTime: Date?
    
    private init() {}
    
    var currentTime: Date {
        return simulatedTime ?? Date()
    }
    
    func setSimulatedTime(_ date: Date?) {
        simulatedTime = date
    }
    
    func resetToRealTime() {
        simulatedTime = nil
    }
    
    var isSimulating: Bool {
        simulatedTime != nil
    }
}
//
//  NudgeManager.swift
//  Phyllo
//
//  Created on 7/29/25.
//

import SwiftUI
import Combine

class NudgeManager: ObservableObject {
    static let shared = NudgeManager()
    
    @Published var activeNudge: NudgeType?
    @Published var queuedNudges: [NudgeType] = []
    @Published var dismissedNudges: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    
    enum NudgeType: Identifiable {
        case morningCheckIn
        case firstTimeTutorial(page: Int)
        case mealLoggedCelebration(meal: LoggedMeal)
        case missedWindow(window: MealWindow)
        case activeWindowReminder(window: MealWindow, timeRemaining: Int)
        
        var id: String {
            switch self {
            case .morningCheckIn:
                return "morning_checkin"
            case .firstTimeTutorial(let page):
                return "tutorial_\(page)"
            case .mealLoggedCelebration(let meal):
                return "celebration_\(meal.id)"
            case .missedWindow(let window):
                return "missed_\(window.id)"
            case .activeWindowReminder(let window, _):
                return "reminder_\(window.id)"
            }
        }
        
        var priority: NudgePriority {
            switch self {
            case .morningCheckIn, .missedWindow:
                return .critical
            case .activeWindowReminder:
                return .prominent
            case .mealLoggedCelebration, .firstTimeTutorial:
                return .gentle
            }
        }
    }
    
    enum NudgePriority: Int, Comparable {
        case subtle = 1
        case gentle = 2
        case prominent = 3
        case critical = 4
        
        static func < (lhs: NudgePriority, rhs: NudgePriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // For now, we'll set up basic observers
        // In a real app, these would observe actual data changes
        
        // Check morning check-in status periodically
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                if MockDataManager.shared.morningCheckIn == nil {
                    self?.triggerNudge(.morningCheckIn)
                }
            }
            .store(in: &cancellables)
    }
    
    func triggerNudge(_ nudge: NudgeType) {
        // Check if already dismissed
        guard !dismissedNudges.contains(nudge.id) else { return }
        
        // If no active nudge, show immediately
        if activeNudge == nil {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                activeNudge = nudge
            }
        } else {
            // Queue based on priority
            queuedNudges.append(nudge)
            queuedNudges.sort { $0.priority > $1.priority }
        }
    }
    
    func dismissCurrentNudge() {
        guard let nudge = activeNudge else { return }
        
        // Mark as dismissed (some nudges can reappear)
        if shouldPermanentlyDismiss(nudge) {
            dismissedNudges.insert(nudge.id)
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            activeNudge = nil
        }
        
        // Show next queued nudge after delay
        if !queuedNudges.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                if let nextNudge = self?.queuedNudges.removeFirst() {
                    self?.triggerNudge(nextNudge)
                }
            }
        }
    }
    
    private func shouldPermanentlyDismiss(_ nudge: NudgeType) -> Bool {
        switch nudge {
        case .firstTimeTutorial, .mealLoggedCelebration:
            return true
        case .morningCheckIn, .missedWindow, .activeWindowReminder:
            return false // Can reappear
        }
    }
    
    // Test helpers
    func resetAllNudges() {
        activeNudge = nil
        queuedNudges.removeAll()
        dismissedNudges.removeAll()
    }
    
    func triggerTestNudge(_ type: NudgeType) {
        dismissedNudges.remove(type.id)
        triggerNudge(type)
    }
}
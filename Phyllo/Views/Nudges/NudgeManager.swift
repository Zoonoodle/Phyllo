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
    
    // Computed property for NotificationManager coordination
    var hasActiveNudge: Bool {
        activeNudge != nil
    }
    
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
        // Check for morning check-in status periodically
        Timer.publish(every: 300, on: .main, in: .common) // Check every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkMorningCheckInStatus()
                }
            }
            .store(in: &cancellables)
        
        // Observe meal windows for reminders
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkWindowStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkMorningCheckInStatus() async {
        do {
            let today = Calendar.current.startOfDay(for: TimeProvider.shared.currentTime)
            let checkIn = try await DataSourceProvider.shared.provider.getMorningCheckIn(for: today)
            
            // Only show morning nudge between 6 AM and 11 AM
            let hour = Calendar.current.component(.hour, from: TimeProvider.shared.currentTime)
            if checkIn == nil && hour >= 6 && hour < 11 {
                // Check if we haven't shown this nudge today
                let lastShown = UserDefaults.standard.object(forKey: "lastMorningNudgeDate") as? Date ?? Date.distantPast
                if !Calendar.current.isDateInToday(lastShown) {
                    await MainActor.run {
                        self.triggerNudge(.morningCheckIn)
                        UserDefaults.standard.set(Date(), forKey: "lastMorningNudgeDate")
                    }
                }
            }
        } catch {
            print("Error checking morning check-in status: \(error)")
        }
    }
    
    private func checkWindowStatus() async {
        do {
            let today = Calendar.current.startOfDay(for: TimeProvider.shared.currentTime)
            let windows = try await DataSourceProvider.shared.provider.getWindows(for: today)
            let meals = try await DataSourceProvider.shared.provider.getMeals(for: today)
            let currentTime = TimeProvider.shared.currentTime
            
            for window in windows {
                // Check for active window reminder
                if window.isActive {
                    let windowMeals = meals.filter { meal in
                        meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                    }
                    
                    // If no meals logged and window has been active for 15+ minutes
                    if windowMeals.isEmpty {
                        let minutesActive = Int(currentTime.timeIntervalSince(window.startTime) / 60)
                        if minutesActive >= 15 {
                            let timeRemaining = Int(window.endTime.timeIntervalSince(currentTime) / 60)
                            if timeRemaining > 0 && !hasShownNudgeRecently(for: "reminder_\(window.id)") {
                                await MainActor.run {
                                    self.triggerNudge(.activeWindowReminder(window: window, timeRemaining: timeRemaining))
                                    self.markNudgeAsShown(for: "reminder_\(window.id)")
                                }
                            }
                        }
                    }
                }
                
                // Check for missed window
                if window.isPast && window.endTime.timeIntervalSince(currentTime) > -300 { // Within 5 minutes of closing
                    let windowMeals = meals.filter { meal in
                        meal.timestamp >= window.startTime && meal.timestamp <= window.endTime
                    }
                    
                    if windowMeals.isEmpty && !hasShownNudgeRecently(for: "missed_\(window.id)") {
                        await MainActor.run {
                            self.triggerNudge(.missedWindow(window: window))
                            self.markNudgeAsShown(for: "missed_\(window.id)")
                        }
                    }
                }
            }
        } catch {
            print("Error checking window status: \(error)")
        }
    }
    
    private func hasShownNudgeRecently(for nudgeId: String) -> Bool {
        let key = "nudgeShown_\(nudgeId)"
        if let lastShown = UserDefaults.standard.object(forKey: key) as? Date {
            // Don't show same nudge within 30 minutes
            return Date().timeIntervalSince(lastShown) < 1800
        }
        return false
    }
    
    private func markNudgeAsShown(for nudgeId: String) {
        let key = "nudgeShown_\(nudgeId)"
        UserDefaults.standard.set(Date(), forKey: key)
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
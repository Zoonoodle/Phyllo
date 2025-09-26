//
//  NudgeManager.swift
//  NutriSync
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
        case dailySync
        case firstTimeTutorial(page: Int)
        case mealLoggedCelebration(meal: LoggedMeal, metadata: AnalysisMetadata?)
        case activeWindowReminder(window: MealWindow, timeRemaining: Int)
        case postMealCheckIn(meal: LoggedMeal)
        case voiceInputTips
        
        var id: String {
            switch self {
            case .dailySync:
                return "daily_sync"
            case .firstTimeTutorial(let page):
                return "tutorial_\(page)"
            case .mealLoggedCelebration(let meal, _):
                return "celebration_\(meal.id)"
            case .activeWindowReminder(let window, _):
                return "reminder_\(window.id)"
            case .postMealCheckIn(let meal):
                return "postmeal_checkin_\(meal.id)"
            case .voiceInputTips:
                return "voice_input_tips"
            }
        }
        
        var priority: NudgePriority {
            switch self {
            case .dailySync:
                return .critical
            case .activeWindowReminder, .postMealCheckIn:
                return .prominent
            case .mealLoggedCelebration, .firstTimeTutorial, .voiceInputTips:
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
        // Check for daily sync status periodically
        Timer.publish(every: 300, on: .main, in: .common) // Check every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.checkDailySyncStatus()
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
    
    private func checkDailySyncStatus() async {
        do {
            // Morning check-in is important for all users, including first-day users
            // First-day users need check-in data to generate better windows
            
            let today = Calendar.current.startOfDay(for: TimeProvider.shared.currentTime)
            let sync = try await DataSourceProvider.shared.provider.getDailySync(for: today)
            
            // Debug logging to understand why sync keeps appearing
            await DebugLogger.shared.log("🔍 Checking Daily Sync - Date: \(today), Found: \(sync != nil)", category: .data)
            
            // Show morning nudge if not completed, regardless of time
            // This makes it mandatory
            if sync == nil {
                // Check if we haven't shown this nudge in the last 30 minutes
                let lastShown = UserDefaults.standard.object(forKey: "lastMorningNudgeDate") as? Date ?? Date.distantPast
                let timeSinceLastShown = Date().timeIntervalSince(lastShown)
                
                // Show again if it's been more than 30 minutes since last shown
                // This ensures the nudge keeps appearing until completed
                if timeSinceLastShown > 1800 { // 30 minutes
                    await MainActor.run {
                        self.triggerNudge(.dailySync)
                        UserDefaults.standard.set(Date(), forKey: "lastMorningNudgeDate")
                    }
                }
            }
        } catch {
            await DebugLogger.shared.error("Error checking morning check-in status: \(error)")
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
                // Removed missedWindow nudge logic as per Phase A requirements
                // This functionality has been removed from the app
            }
        } catch {
            await DebugLogger.shared.error("Error checking window status: \(error)")
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
        case .firstTimeTutorial, .mealLoggedCelebration, .voiceInputTips:
            return true
        case .dailySync, .activeWindowReminder, .postMealCheckIn:
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
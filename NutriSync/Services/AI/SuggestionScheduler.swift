//
//  SuggestionScheduler.swift
//  NutriSync
//
//  Schedules and triggers food suggestion generation 15 minutes before each window starts
//

import Foundation
import Combine

/// Manages automatic triggering of food suggestion generation
@MainActor
class SuggestionScheduler: ObservableObject {
    static let shared = SuggestionScheduler()

    // MARK: - Published Properties

    @Published private(set) var isRunning = false
    @Published private(set) var lastGenerationTime: Date?
    @Published private(set) var activeGenerations: Set<String> = [] // Window IDs being generated

    // MARK: - Configuration

    /// Time before window start to trigger generation (15 minutes)
    private let triggerLeadTime: TimeInterval = 15 * 60

    /// Minimum time between generation attempts for same window
    private let regenerationCooldown: TimeInterval = 30 * 60

    // MARK: - Dependencies

    private let suggestionService = FoodSuggestionService.shared
    private let timeProvider = TimeProvider.shared
    private let notificationManager = NotificationManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Track which windows have been generated this session
    private var generatedWindowIds: Set<String> = []

    // Store current context for immediate triggering
    private var currentWindows: [MealWindow] = []
    private var currentProfile: UserProfile?
    private var currentMeals: [LoggedMeal] = []
    private var currentUpdateCallback: ((MealWindow) async throws -> Void)?

    private init() {
        // Listen for countdown reaching zero to trigger immediate check
        NotificationCenter.default.publisher(for: .suggestionCountdownReachedZero)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.triggerImmediateCheck()
                }
            }
            .store(in: &cancellables)

        // Also listen for app data refresh to re-check pending windows
        NotificationCenter.default.publisher(for: .appDataRefreshed)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.triggerImmediateCheck()
                }
            }
            .store(in: &cancellables)

        // Phase 7: Listen for meal logged events to refresh future suggestions
        NotificationCenter.default.publisher(for: .mealLogged)
            .sink { [weak self] notification in
                Task { @MainActor in
                    await self?.handleMealLogged(notification)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// Start monitoring windows and scheduling generation
    func start(
        windows: [MealWindow],
        profile: UserProfile,
        todaysMeals: [LoggedMeal],
        updateWindow: @escaping (MealWindow) async throws -> Void
    ) {
        guard !isRunning else {
            // If already running, just update the context with new windows
            updateContext(windows: windows, profile: profile, meals: todaysMeals, updateCallback: updateWindow)
            return
        }
        isRunning = true

        // Store context for immediate triggering later
        updateContext(windows: windows, profile: profile, meals: todaysMeals, updateCallback: updateWindow)

        DebugLogger.shared.info("[SuggestionScheduler] Starting scheduler with \(windows.count) windows")

        // Check immediately for any windows that need generation
        Task {
            await checkAndGenerateSuggestions(
                windows: windows,
                profile: profile,
                todaysMeals: todaysMeals,
                updateWindow: updateWindow
            )
        }

        // Set up periodic check (every minute)
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                await self.checkAndGenerateSuggestions(
                    windows: self.currentWindows,
                    profile: self.currentProfile ?? profile,
                    todaysMeals: self.currentMeals,
                    updateWindow: self.currentUpdateCallback ?? updateWindow
                )
            }
        }
    }

    /// Update the scheduler's context with fresh data (call when windows/meals change)
    func updateContext(
        windows: [MealWindow],
        profile: UserProfile,
        meals: [LoggedMeal],
        updateCallback: @escaping (MealWindow) async throws -> Void
    ) {
        currentWindows = windows
        currentProfile = profile
        currentMeals = meals
        currentUpdateCallback = updateCallback
    }

    /// Trigger an immediate check for pending suggestions (used when countdown hits 0 or app returns to foreground)
    func triggerImmediateCheck() async {
        guard isRunning,
              let profile = currentProfile,
              let updateCallback = currentUpdateCallback else {
            DebugLogger.shared.warning("[SuggestionScheduler] Cannot trigger immediate check - scheduler not properly initialized")
            return
        }

        DebugLogger.shared.info("[SuggestionScheduler] Triggering immediate check for pending suggestions")

        await checkAndGenerateSuggestions(
            windows: currentWindows,
            profile: profile,
            todaysMeals: currentMeals,
            updateWindow: updateCallback
        )
    }

    /// Stop monitoring
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        DebugLogger.shared.info("[SuggestionScheduler] Stopped scheduler")
    }

    /// Force regenerate suggestions for a specific window
    func regenerateSuggestions(
        for window: MealWindow,
        profile: UserProfile,
        todaysMeals: [LoggedMeal],
        allWindows: [MealWindow],
        updateWindow: @escaping (MealWindow) async throws -> Void
    ) async {
        // Remove from generated set to allow regeneration
        generatedWindowIds.remove(window.id)

        await generateSuggestionsForWindow(
            window,
            profile: profile,
            todaysMeals: todaysMeals,
            previousWindows: getPreviousWindows(for: window, allWindows: allWindows),
            updateWindow: updateWindow
        )
    }

    /// Check if a window needs suggestions generated
    func windowNeedsSuggestions(_ window: MealWindow, now: Date? = nil) -> Bool {
        let currentTime = now ?? timeProvider.currentTime

        // Already has suggestions
        if window.suggestionStatus == .ready && !window.smartSuggestions.isEmpty {
            return false
        }

        // Currently generating
        if window.suggestionStatus == .generating || activeGenerations.contains(window.id) {
            return false
        }

        // Already generated this session
        if generatedWindowIds.contains(window.id) {
            return false
        }

        // Window is in the past
        if window.endTime < currentTime {
            return false
        }

        // Check if within trigger window (15 minutes before start OR already active)
        let timeUntilStart = window.startTime.timeIntervalSince(currentTime)

        // Generate if:
        // 1. Window starts within 15 minutes, OR
        // 2. Window is currently active and no suggestions yet
        return timeUntilStart <= triggerLeadTime || window.isActive
    }

    // MARK: - Private Methods

    private func checkAndGenerateSuggestions(
        windows: [MealWindow],
        profile: UserProfile,
        todaysMeals: [LoggedMeal],
        updateWindow: @escaping (MealWindow) async throws -> Void
    ) async {
        let now = timeProvider.currentTime

        // Sort windows by start time
        let sortedWindows = windows.sorted { $0.startTime < $1.startTime }

        for window in sortedWindows {
            if windowNeedsSuggestions(window, now: now) {
                let previousWindows = getPreviousWindows(for: window, allWindows: sortedWindows)

                await generateSuggestionsForWindow(
                    window,
                    profile: profile,
                    todaysMeals: todaysMeals,
                    previousWindows: previousWindows,
                    updateWindow: updateWindow
                )
            }
        }
    }

    private func generateSuggestionsForWindow(
        _ window: MealWindow,
        profile: UserProfile,
        todaysMeals: [LoggedMeal],
        previousWindows: [MealWindow],
        updateWindow: @escaping (MealWindow) async throws -> Void
    ) async {
        // Mark as generating
        activeGenerations.insert(window.id)

        // Update window status to generating
        var updatingWindow = window
        updatingWindow.suggestionStatus = .generating
        try? await updateWindow(updatingWindow)

        DebugLogger.shared.info("[SuggestionScheduler] Generating suggestions for window: \(window.name)")

        do {
            let result = try await suggestionService.generateSuggestions(
                for: window,
                profile: profile,
                todaysMeals: todaysMeals,
                previousWindows: previousWindows
            )

            // Update window with suggestions
            var updatedWindow = window
            updatedWindow.smartSuggestions = result.suggestions
            updatedWindow.suggestionContextNote = result.contextNote
            updatedWindow.suggestionStatus = .ready
            updatedWindow.suggestionsGeneratedAt = Date()

            try await updateWindow(updatedWindow)

            // Mark as generated
            generatedWindowIds.insert(window.id)
            lastGenerationTime = Date()

            DebugLogger.shared.success("[SuggestionScheduler] Generated \(result.suggestions.count) suggestions for \(window.name)")

            // Send notification that suggestions are ready
            await notificationManager.notifySuggestionsReady(
                for: updatedWindow,
                suggestionCount: result.suggestions.count
            )

        } catch {
            DebugLogger.shared.error("[SuggestionScheduler] Failed to generate suggestions: \(error.localizedDescription)")

            // Update window status to failed
            var failedWindow = window
            failedWindow.suggestionStatus = .failed
            try? await updateWindow(failedWindow)
        }

        activeGenerations.remove(window.id)
    }

    private func getPreviousWindows(for window: MealWindow, allWindows: [MealWindow]) -> [MealWindow] {
        allWindows.filter { $0.startTime < window.startTime }
            .sorted { $0.startTime < $1.startTime }
    }

    /// Reset session state (call on new day or when windows are regenerated)
    func resetSession() {
        generatedWindowIds.removeAll()
        activeGenerations.removeAll()
        lastGenerationTime = nil
        DebugLogger.shared.info("[SuggestionScheduler] Session reset")
    }

    // MARK: - Phase 7: Meal Logged Handling

    /// Handle a meal logged notification and refresh suggestions for future windows
    private func handleMealLogged(_ notification: Notification) async {
        guard isRunning,
              let profile = currentProfile,
              let updateCallback = currentUpdateCallback
        else {
            DebugLogger.shared.info("[SuggestionScheduler] Ignoring meal logged - scheduler not ready")
            return
        }

        // Get the logged meal info if provided
        let loggedWindowId = notification.userInfo?["windowId"] as? String

        DebugLogger.shared.info("[SuggestionScheduler] Meal logged, refreshing future window suggestions")

        let now = timeProvider.currentTime

        // Find future windows that might need refreshed suggestions
        let futureWindows = currentWindows.filter { window in
            // Window starts in the future
            window.startTime > now &&
            // Window has existing suggestions that might now be stale
            window.suggestionStatus == .ready &&
            !window.smartSuggestions.isEmpty
        }

        guard !futureWindows.isEmpty else {
            DebugLogger.shared.info("[SuggestionScheduler] No future windows to refresh")
            return
        }

        // Only refresh the next upcoming window to avoid excessive regeneration
        // More windows can be regenerated as they approach
        if let nextWindow = futureWindows.sorted(by: { $0.startTime < $1.startTime }).first {
            DebugLogger.shared.info("[SuggestionScheduler] Refreshing suggestions for: \(nextWindow.name)")

            // Clear the generated flag so it can be regenerated
            generatedWindowIds.remove(nextWindow.id)

            // Regenerate with updated meal context
            await generateSuggestionsForWindow(
                nextWindow,
                profile: profile,
                todaysMeals: currentMeals,
                previousWindows: getPreviousWindows(for: nextWindow, allWindows: currentWindows),
                updateWindow: updateCallback
            )
        }
    }

    /// Manually trigger suggestion refresh for all future windows after meal logged
    func refreshSuggestionsAfterMealLogged(
        updatedMeals: [LoggedMeal],
        windows: [MealWindow],
        profile: UserProfile,
        updateWindow: @escaping (MealWindow) async throws -> Void
    ) async {
        // Update current context
        currentMeals = updatedMeals
        currentWindows = windows
        currentProfile = profile
        currentUpdateCallback = updateWindow

        let now = timeProvider.currentTime

        // Find the next future window with existing suggestions
        let nextWindow = windows
            .filter { $0.startTime > now && $0.suggestionStatus == .ready }
            .sorted { $0.startTime < $1.startTime }
            .first

        guard let window = nextWindow else {
            DebugLogger.shared.info("[SuggestionScheduler] No future windows to refresh after meal")
            return
        }

        DebugLogger.shared.info("[SuggestionScheduler] Refreshing next window after meal: \(window.name)")

        // Clear the generated flag and regenerate
        generatedWindowIds.remove(window.id)

        await generateSuggestionsForWindow(
            window,
            profile: profile,
            todaysMeals: updatedMeals,
            previousWindows: getPreviousWindows(for: window, allWindows: windows),
            updateWindow: updateWindow
        )
    }
}

// MARK: - Meal Logged Notification

extension Notification.Name {
    /// Posted when a meal is successfully logged/saved
    static let mealLogged = Notification.Name("mealLogged")
}

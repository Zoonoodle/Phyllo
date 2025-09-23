import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Manager
/// Manages push notifications for meal windows, check-ins, and coaching
@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var notificationPreferences = NotificationPreferences()
    @Published var pendingNotificationCount = 0
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let nudgeManager = NudgeManager.shared
    private let timeProvider = TimeProvider.shared
    private let dataProvider = DataSourceProvider.shared.provider
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
        loadPreferences()
        Task { await checkAuthorizationStatus() }
    }
    
    // MARK: - Public Methods
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .provisional, .providesAppNotificationSettings]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
                DebugLogger.shared.notification("Push notification permission: \(granted ? "granted" : "denied")")
            }
            
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            DebugLogger.shared.error("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        self.isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        DebugLogger.shared.notification("Current notification status: \(settings.authorizationStatus.rawValue)")
    }
    
    /// Request full authorization if currently provisional
    func requestFullAuthorization() async -> Bool {
        // Only request if currently provisional
        guard authorizationStatus == .provisional else {
            return authorizationStatus == .authorized
        }
        
        // Request without provisional flag to prompt for full authorization
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge, .providesAppNotificationSettings]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
                DebugLogger.shared.notification("Full authorization request: \(granted ? "granted" : "denied")")
            }
            
            return granted
        } catch {
            DebugLogger.shared.error("Failed to request full authorization: \(error)")
            return false
        }
    }
    
    /// Schedule notifications for meal windows
    func scheduleWindowNotifications(for windows: [MealWindow]) async {
        guard isAuthorized else {
            DebugLogger.shared.warning("Cannot schedule notifications - not authorized")
            return
        }
        
        // Cancel existing window notifications
        await cancelWindowNotifications()
        
        let now = timeProvider.currentTime
        
        for window in windows {
            // Skip past windows
            guard window.endTime > now else { continue }
            
            // Window starting soon (15 minutes before)
            if window.startTime > now {
                let notificationTime = window.startTime.addingTimeInterval(-15 * 60)
                if notificationTime > now {
                    await scheduleNotification(
                        id: "window-start-\(window.id)",
                        title: "\(windowDisplayName(window)) Starting Soon",
                        body: "Your \(window.purpose.rawValue) window starts in 15 minutes • \(window.targetCalories) cal",
                        date: notificationTime,
                        category: .windowReminder,
                        userInfo: ["windowId": window.id, "type": "windowStart"]
                    )
                }
            }
            
            // Active window reminder (30 minutes into flexible windows)
            if window.flexibility != .strict && window.contains(timestamp: now.addingTimeInterval(30 * 60)) {
                let reminderTime = window.startTime.addingTimeInterval(30 * 60)
                if reminderTime > now {
                    await scheduleNotification(
                        id: "window-active-\(window.id)",
                        title: "Active Meal Window",
                        body: "\(window.timeRemaining ?? 0) minutes remaining • Time to fuel up!",
                        date: reminderTime,
                        category: .windowReminder,
                        userInfo: ["windowId": window.id, "type": "windowActive"]
                    )
                }
            }
            
            // Window ending alert (15 minutes before close)
            let endingTime = window.endTime.addingTimeInterval(-15 * 60)
            if endingTime > now && window.contains(timestamp: now) {
                await scheduleNotification(
                    id: "window-ending-\(window.id)",
                    title: "\(windowDisplayName(window)) Ending Soon",
                    body: "15 minutes left to log your meal",
                    date: endingTime,
                    category: .windowReminder,
                    userInfo: ["windowId": window.id, "type": "windowEnding"]
                )
            }
        }
        
        DebugLogger.shared.success("Scheduled notifications for \(windows.count) windows")
    }
    
    /// Schedule morning check-in reminder
    func scheduleMorningCheckInReminder(for date: Date) async {
        guard isAuthorized else { return }
        
        let calendar = Calendar.current
        
        // Progressive reminders: 8 AM, 9:30 AM, 11 AM
        let reminderTimes = [
            (hour: 8, minute: 0, message: "Good morning! How did you sleep?"),
            (hour: 9, minute: 30, message: "Start your day right with a quick check-in"),
            (hour: 11, minute: 0, message: "Last chance for morning check-in!")
        ]
        
        for (index, reminder) in reminderTimes.enumerated() {
            var components = calendar.dateComponents([.year, .month, .day], from: date)
            components.hour = reminder.hour
            components.minute = reminder.minute
            
            guard let notificationDate = calendar.date(from: components),
                  notificationDate > timeProvider.currentTime else { continue }
            
            await scheduleNotification(
                id: "morning-checkin-\(index)-\(ISO8601DateFormatter.yyyyMMdd.string(from: date))",
                title: "Morning Check-In",
                body: reminder.message,
                date: notificationDate,
                category: .checkInReminder,
                userInfo: ["type": "morningCheckIn", "reminderIndex": index]
            )
        }
    }
    
    /// Schedule post-meal check-in reminder
    func schedulePostMealCheckIn(for meal: LoggedMeal) async {
        guard isAuthorized else { return }
        
        let checkInTime = meal.timestamp.addingTimeInterval(30 * 60) // 30 minutes after meal
        
        guard checkInTime > timeProvider.currentTime else { return }
        
        await scheduleNotification(
            id: "postmeal-checkin-\(meal.id)",
            title: "How are you feeling?",
            body: "Quick check-in after your \(meal.name)",
            date: checkInTime,
            category: .checkInReminder,
            userInfo: ["type": "postMealCheckIn", "mealId": meal.id.uuidString, "mealName": meal.name]
        )
    }
    
    /// Handle window missed notification
    func notifyMissedWindow(_ window: MealWindow) async {
        guard isAuthorized,
              notificationPreferences.missedWindowAlerts else { return }
        
        // Check if app is in foreground - let NudgeManager handle it
        if UIApplication.shared.applicationState == .active {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Missed \(windowDisplayName(window))"
        content.body = "You can still log a meal for tracking"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.missedWindow.rawValue
        content.userInfo = ["windowId": window.id, "type": "missedWindow"]
        
        let request = UNNotificationRequest(
            identifier: "missed-window-\(window.id)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        do {
            try await notificationCenter.add(request)
            DebugLogger.shared.notification("Sent missed window notification for \(window.purpose.rawValue)")
        } catch {
            DebugLogger.shared.error("Failed to send missed window notification: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func scheduleNotification(
        id: String,
        title: String,
        body: String,
        date: Date,
        category: NotificationCategory,
        userInfo: [String: Any]
    ) async {
        // Check quiet hours
        if isInQuietHours(date) {
            DebugLogger.shared.notification("Skipping notification during quiet hours: \(title)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.rawValue
        content.userInfo = userInfo
        
        // Add actions based on category
        switch category {
        case .windowReminder:
            content.categoryIdentifier = NotificationCategory.windowReminder.rawValue
        case .checkInReminder:
            content.categoryIdentifier = NotificationCategory.checkInReminder.rawValue
        default:
            break
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            DebugLogger.shared.notification("Scheduled: \(title) at \(date)")
        } catch {
            DebugLogger.shared.error("Failed to schedule notification: \(error)")
        }
    }
    
    private func isInQuietHours(_ date: Date) -> Bool {
        guard notificationPreferences.quietHoursEnabled else { return false }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        let startHour = notificationPreferences.quietHoursStart
        let endHour = notificationPreferences.quietHoursEnd
        
        if startHour <= endHour {
            // Normal case: e.g., 22:00 - 07:00
            return hour >= startHour || hour < endHour
        } else {
            // Crosses midnight: e.g., 22:00 - 07:00
            return hour >= startHour || hour < endHour
        }
    }
    
    private func windowDisplayName(_ window: MealWindow) -> String {
        let hour = Calendar.current.component(.hour, from: window.startTime)
        switch hour {
        case 5...10: return "Breakfast Window"
        case 11...14: return "Lunch Window"
        case 15...17: return "Snack Window"
        case 18...21: return "Dinner Window"
        default: return "Late Snack Window"
        }
    }
    
    // MARK: - Notification Management
    
    func cancelWindowNotifications() async {
        let identifiers = await notificationCenter.pendingNotificationRequests()
            .map { $0.identifier }
            .filter { $0.hasPrefix("window-") }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        DebugLogger.shared.notification("Cancelled \(identifiers.count) window notifications")
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        DebugLogger.shared.notification("Cancelled all notifications")
    }
    
    // MARK: - Preferences
    
    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "notificationPreferences"),
           let preferences = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            self.notificationPreferences = preferences
        }
    }
    
    func savePreferences() {
        if let data = try? JSONEncoder().encode(notificationPreferences) {
            UserDefaults.standard.set(data, forKey: "notificationPreferences")
        }
    }
    
    // MARK: - Additional Public Methods
    
    /// Get count of pending notifications
    func getPendingNotificationCount() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        pendingNotificationCount = requests.count
        DebugLogger.shared.notification("Pending notifications: \(requests.count)")
    }
    
    /// Clear all scheduled notifications
    func clearAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        pendingNotificationCount = 0
        DebugLogger.shared.notification("Cleared all notifications")
    }
    
    /// Schedule a test notification with delay
    func scheduleTestNotification(type: NotificationType, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        
        switch type {
        case .windowStartingSoon(let window):
            content.title = "Meal Window Starting Soon"
            content.body = "Your \(window.purpose.rawValue) window starts in 15 minutes. Get ready to fuel your body!"
            content.categoryIdentifier = "WINDOW_REMINDER"
            content.userInfo = [
                "type": "windowStartingSoon",
                "windowId": window.id
            ]
            
        case .activeWindowReminder(let window, let timeRemaining):
            content.title = "Active Meal Window"
            content.body = "\(Int(timeRemaining)) minutes left in your \(window.purpose.rawValue) window. Don't miss out!"
            content.categoryIdentifier = "WINDOW_REMINDER"
            content.userInfo = [
                "type": "activeWindowReminder",
                "windowId": window.id
            ]
            
        case .windowEndingAlert(let window):
            content.title = "Window Closing Soon"
            content.body = "Your \(window.purpose.rawValue) window closes in 15 minutes. Last chance to log a meal!"
            content.categoryIdentifier = "WINDOW_REMINDER"
            content.userInfo = [
                "type": "windowEndingAlert",
                "windowId": window.id
            ]
            
        case .missedWindow(let window):
            content.title = "Missed Meal Window"
            content.body = "You missed your \(window.purpose.rawValue) window. Your remaining windows have been adjusted."
            content.categoryIdentifier = "MISSED_WINDOW"
            content.userInfo = [
                "type": "missedWindow",
                "windowId": window.id
            ]
            
        case .morningCheckIn:
            content.title = "Good Morning!"
            content.body = "Start your day right with a quick check-in to personalize today's meal windows."
            content.categoryIdentifier = "CHECK_IN"
            content.userInfo = ["type": "morningCheckIn"]
            
        case .postMealCheckIn(let meal):
            content.title = "How are you feeling?"
            content.body = "Quick check-in after your \(meal.name). Track how this meal affects your energy."
            content.categoryIdentifier = "CHECK_IN"
            content.userInfo = [
                "type": "postMealCheckIn",
                "mealId": meal.id.uuidString
            ]
        }
        
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        
        // Create trigger with delay
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "test-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
            await getPendingNotificationCount()
            DebugLogger.shared.notification("Scheduled test notification: \(type) with \(Int(delay))s delay")
        } catch {
            DebugLogger.shared.error("Failed to schedule test notification: \(error)")
        }
    }
}

// MARK: - Notification Types

enum NotificationType {
    case windowStartingSoon(window: MealWindow)
    case activeWindowReminder(window: MealWindow, timeRemaining: TimeInterval)
    case windowEndingAlert(window: MealWindow)
    case missedWindow(window: MealWindow)
    case morningCheckIn
    case postMealCheckIn(meal: LoggedMeal)
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notifications when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Check if we should suppress this notification
        if NudgeManager.shared.hasActiveNudge {
            // Don't show notification if there's already an in-app nudge
            completionHandler([])
            return
        }
        
        // Show banner and play sound
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
    
    // Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            self.handleNotificationResponse(response)
        }
        completionHandler()
    }
    
    @MainActor
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            if let type = userInfo["type"] as? String {
                switch type {
                case "windowStart", "windowActive", "windowEnding":
                    // Navigate to scan tab
                    NotificationCenter.default.post(
                        name: .navigateToTab,
                        object: nil,
                        userInfo: ["tab": "scan"]
                    )
                    
                case "morningCheckIn":
                    // Trigger morning check-in nudge
                    nudgeManager.triggerNudge(.morningCheckIn)
                    
                case "postMealCheckIn":
                    // Trigger post-meal check-in nudge
                    if let mealIdString = userInfo["mealId"] as? String {
                        Task {
                            do {
                                if let meal = try await dataProvider.getMeal(id: mealIdString) {
                                    await MainActor.run {
                                        nudgeManager.triggerNudge(.postMealCheckIn(meal: meal))
                                    }
                                } else {
                                    // Fallback to schedule tab if meal not found
                                    await MainActor.run {
                                        NotificationCenter.default.post(
                                            name: .navigateToTab,
                                            object: nil,
                                            userInfo: ["tab": "schedule"]
                                        )
                                    }
                                }
                            } catch {
                                print("Error fetching meal: \(error)")
                                // Fallback to schedule tab on error
                                await MainActor.run {
                                    NotificationCenter.default.post(
                                        name: .navigateToTab,
                                        object: nil,
                                        userInfo: ["tab": "schedule"]
                                    )
                                }
                            }
                        }
                    }
                    
                default:
                    break
                }
            }
            
        case NotificationAction.logMeal.rawValue:
            // Quick action: Log meal
            NotificationCenter.default.post(
                name: .navigateToTab,
                object: nil,
                userInfo: ["tab": "scan"]
            )
            
        case NotificationAction.remindLater.rawValue:
            // Snooze for 15 minutes
            Task {
                await rescheduleNotification(response.notification, delayMinutes: 15)
            }
            
        case NotificationAction.viewDetails.rawValue:
            // Navigate to schedule/timeline
            NotificationCenter.default.post(
                name: .navigateToTab,
                object: nil,
                userInfo: ["tab": "schedule"]
            )
            
        default:
            break
        }
    }
    
    private func rescheduleNotification(_ notification: UNNotification, delayMinutes: Int) async {
        let content = notification.request.content.mutableCopy() as! UNMutableNotificationContent
        content.title = "Reminder: \(content.title)"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(delayMinutes * 60),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(notification.request.identifier)-snoozed",
            content: content,
            trigger: trigger
        )
        
        try? await notificationCenter.add(request)
    }
}

// MARK: - Notification Models

/// Notification categories for different types
enum NotificationCategory: String {
    case windowReminder = "WINDOW_REMINDER"
    case checkInReminder = "CHECKIN_REMINDER"
    case missedWindow = "MISSED_WINDOW"
    case goalProgress = "GOAL_PROGRESS"
    case coaching = "COACHING"
}

/// Notification actions
enum NotificationAction: String {
    case logMeal = "LOG_MEAL"
    case remindLater = "REMIND_LATER"
    case dismiss = "DISMISS"
    case viewDetails = "VIEW_DETAILS"
    case completeCheckIn = "COMPLETE_CHECKIN"
}

/// User notification preferences
struct NotificationPreferences: Codable, Equatable {
    // Notification types
    var windowReminders = true
    var checkInReminders = true
    var missedWindowAlerts = true
    var goalProgress = true
    var coachingTips = true
    
    // Timing preferences
    var quietHoursEnabled = true
    var quietHoursStart = 22 // 10 PM
    var quietHoursEnd = 7 // 7 AM
    
    // Frequency limits
    var maxDailyNotifications = 10
    var smartLearning = true // Reduce frequency if ignored
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let navigateToTab = Notification.Name("navigateToTab")
    static let clearAllDataNotification = Notification.Name("clearAllDataNotification")
    static let appDataRefreshed = Notification.Name("appDataRefreshed")
}

// MARK: - Helper Extensions

extension ISO8601DateFormatter {
    static let yyyyMMdd: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return formatter
    }()
}
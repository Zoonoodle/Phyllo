//
//  DeveloperDashboardView.swift
//  NutriSync
//
//  Simplified version without MockDataManager
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DeveloperDashboardView: View {
    @State private var selectedTab = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.nutriSyncBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Tab Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            DashboardTab(title: "Data Viewer", icon: "doc.text", isSelected: selectedTab == 0) {
                                selectedTab = 0
                            }
                            DashboardTab(title: "Debug Logs", icon: "ladybug.fill", isSelected: selectedTab == 1) {
                                selectedTab = 1
                            }
                            DashboardTab(title: "Firebase", icon: "flame", isSelected: selectedTab == 2) {
                                selectedTab = 2
                            }
                            DashboardTab(title: "Trial & Sub", icon: "creditcard.fill", isSelected: selectedTab == 3) {
                                selectedTab = 3
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    
                    // Tab Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case 0:
                                DataViewerTabView()
                            case 1:
                                DebugLogView()
                            case 2:
                                FirebaseTabView()
                            case 3:
                                TrialSubscriptionTabView()
                            default:
                                EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Developer Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.nutriSyncAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Tab Button Component
struct DashboardTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .nutriSyncAccent : .white.opacity(0.5))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.nutriSyncAccent.opacity(0.2) : Color.clear)
            .cornerRadius(12)
        }
    }
}

// MARK: - Data Viewer Tab
struct DataViewerTabView: View {
    private var dataProvider: DataProvider {
        DataSourceProvider.shared.provider
    }
    
    @State private var todaysMeals: [LoggedMeal] = []
    @State private var todaysWindows: [MealWindow] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Today's Meals
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Meals")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(todaysMeals.count) meals")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if todaysMeals.isEmpty {
                    Text("No meals logged yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(todaysMeals) { meal in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(meal.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("\(meal.calories) cal • P: \(meal.protein)g • C: \(meal.carbs)g • F: \(meal.fat)g")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text(meal.timestamp, formatter: timeFormatter)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.nutriSyncSurface)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.nutriSyncElevated)
            .cornerRadius(16)
            
            // Today's Windows
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Today's Windows")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(todaysWindows.count) windows")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                if todaysWindows.isEmpty {
                    Text("No windows generated yet")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                } else {
                    ForEach(todaysWindows) { window in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(window.purpose.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("\(window.targetCalories) cal target")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text("\(window.startTime, formatter: timeFormatter) - \(window.endTime, formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding()
                        .background(Color.nutriSyncSurface)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.nutriSyncElevated)
            .cornerRadius(16)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            do {
                let meals = try await dataProvider.getMeals(for: Date())
                let windows = try await dataProvider.getWindows(for: Date())
                
                await MainActor.run {
                    self.todaysMeals = meals.sorted { $0.timestamp < $1.timestamp }
                    self.todaysWindows = windows.sorted { $0.startTime < $1.startTime }
                    self.isLoading = false
                }
            } catch {
                print("Error loading data: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Firebase Tab
struct FirebaseTabView: View {
    @State private var totalMeals = 0
    @State private var isClearing = false
    @State private var showClearConfirmation = false
    @State private var isRegeneratingWindows = false
    @State private var showRegenerateConfirmation = false
    @State private var regenerateMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Firebase Stats
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Firebase Database")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if totalMeals > 0 {
                        Text("\(totalMeals) total meals")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: fetchFirebaseStats) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Text("All meals across all dates in Firebase")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(Color.nutriSyncElevated)
            .cornerRadius(16)
            
            // Regenerate Windows Button
            Button(action: {
                showRegenerateConfirmation = true
            }) {
                HStack {
                    if isRegeneratingWindows {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text("Regenerate Today's Windows")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(isRegeneratingWindows ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRegeneratingWindows)
            .confirmationDialog("Regenerate Windows", isPresented: $showRegenerateConfirmation) {
                Button("Regenerate with AI", role: .destructive) {
                    regenerateTodaysWindows()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete today's meal windows and generate new ones with corrected timestamps based on your wake time.")
            }
            
            if !regenerateMessage.isEmpty {
                Text(regenerateMessage)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
            }
            
            // Clear Data Button
            Button(action: {
                showClearConfirmation = true
            }) {
                HStack {
                    if isClearing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text("Clear Today's Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(isClearing ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isClearing)
            .confirmationDialog("Clear Today's Data", isPresented: $showClearConfirmation) {
                Button("Clear Today's Data", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete today's windows, meals, and DailySync data. You'll be able to redo the DailySync → window generation flow.")
            }
        }
        .onAppear {
            fetchFirebaseStats()
        }
    }
    
    private func fetchFirebaseStats() {
        Task {
            do {
                let snapshot = try await Firestore.firestore()
                    .collection("users")
                    .document("dev_user_001")
                    .collection("meals")
                    .getDocuments()
                
                await MainActor.run {
                    totalMeals = snapshot.documents.count
                }
            } catch {
                print("Error fetching stats: \(error)")
            }
        }
    }
    
    private func regenerateTodaysWindows() {
        isRegeneratingWindows = true
        regenerateMessage = ""
        
        Task {
            do {
                // Get Firebase data provider
                guard let firebaseProvider = DataSourceProvider.shared.provider as? FirebaseDataProvider else {
                    throw NSError(domain: "DeveloperDashboard", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "Firebase provider not available"])
                }
                
                // Get user profile - it will create a default one if none exists
                let profile = try await firebaseProvider.getUserProfile()
                
                // Ensure we have a profile (should always succeed due to auto-creation)
                guard let validProfile = profile else {
                    throw NSError(domain: "DeveloperDashboard", code: 2,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to create or fetch user profile"])
                }
                
                // Log profile fetch success
                await MainActor.run {
                    DebugLogger.shared.info("Successfully fetched user profile: \(validProfile.name)")
                }
                
                // Get check-in data (optional - can be nil)
                let checkIn = try? await firebaseProvider.getMorningCheckIn(for: Date())
                
                // Clear and regenerate windows
                let newWindows = try await firebaseProvider.clearAndRegenerateWindows(
                    for: Date(),
                    profile: validProfile,
                    checkIn: checkIn
                )
                
                await MainActor.run {
                    isRegeneratingWindows = false
                    regenerateMessage = "Successfully regenerated \(newWindows.count) windows with corrected timestamps"
                    DebugLogger.shared.success("Regenerated \(newWindows.count) windows for today")
                    
                    // Clear message after 3 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        regenerateMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isRegeneratingWindows = false
                    regenerateMessage = "Failed: \(error.localizedDescription)"
                    DebugLogger.shared.error("Failed to regenerate windows: \(error)")
                    
                    // Clear error message after 5 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        regenerateMessage = ""
                    }
                }
            }
        }
    }
    
    private func clearAllData() {
        isClearing = true

        Task {
            do {
                // Use FirebaseDataProvider's clearTodayData method
                // This clears: today's windows, meals, dailySync, dayPurpose, contextInsights, analyzing meals
                // And resets: DailySyncManager state
                try await FirebaseDataProvider.shared.clearTodayData()

                await MainActor.run {
                    isClearing = false
                    totalMeals = 0

                    // Clear in-memory check-in data
                    CheckInManager.shared.morningCheckIns.removeAll()
                    CheckInManager.shared.hasCompletedMorningCheckIn = false
                    CheckInManager.shared.postMealCheckIns.removeAll()
                    CheckInManager.shared.pendingPostMealCheckIns.removeAll()

                    // Post notification to refresh ViewModels
                    NotificationCenter.default.post(name: .clearAllDataNotification, object: nil)

                    DebugLogger.shared.success("✅ Cleared today's data - ready for fresh DailySync!")
                }

                // Refresh stats after clearing
                fetchFirebaseStats()

            } catch {
                await MainActor.run {
                    isClearing = false
                    DebugLogger.shared.error("Failed to clear today's data: \(error)")
                }
            }
        }
    }
}

// MARK: - Trial & Subscription Tab
struct TrialSubscriptionTabView: View {
    @EnvironmentObject private var gracePeriodManager: GracePeriodManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    @State private var isResettingTrial = false
    @State private var isExpiringTrial = false
    @State private var isClearingSubscription = false
    @State private var isMockingSubscription = false
    @State private var actionMessage = ""
    @State private var showResetConfirmation = false
    @State private var showExpireConfirmation = false
    @State private var showClearSubConfirmation = false
    @State private var showMockSubConfirmation = false

    var body: some View {
        VStack(spacing: 20) {
            // Trial Status Display
            VStack(alignment: .leading, spacing: 12) {
                Text("Trial Status")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(gracePeriodManager.isInGracePeriod ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(gracePeriodManager.isInGracePeriod ? "Active" : "Inactive")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        if gracePeriodManager.isInGracePeriod {
                            Text("⏱️ Time: \(gracePeriodManager.remainingHours) hours remaining")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            Text("📸 Scans: \(gracePeriodManager.remainingScans)/4 remaining")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            Text("🪟 Windows: \(gracePeriodManager.remainingWindowGens)/1 remaining")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            if let endDate = gracePeriodManager.gracePeriodEndDate {
                                Text("🏁 Expires: \(endDate, formatter: fullDateFormatter)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        } else if gracePeriodManager.gracePeriodEndDate != nil {
                            Text("⚠️ Trial expired")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("ℹ️ No trial initialized")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color.nutriSyncElevated)
            .cornerRadius(16)

            // Subscription Status Display
            VStack(alignment: .leading, spacing: 12) {
                Text("Subscription Status")
                    .font(.headline)
                    .foregroundColor(.white)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(subscriptionManager.isSubscribed ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(subscriptionManager.isSubscribed ? "Subscribed" : "Not Subscribed")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Text("Status: \(subscriptionStatusText)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color.nutriSyncElevated)
            .cornerRadius(16)

            // Reset Trial Button
            Button(action: {
                showResetConfirmation = true
            }) {
                HStack {
                    if isResettingTrial {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise.circle.fill")
                    }
                    Text("Reset Trial (Fresh Start)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(isResettingTrial ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isResettingTrial)
            .confirmationDialog("Reset Trial", isPresented: $showResetConfirmation) {
                Button("Reset Trial", role: .destructive) {
                    resetTrial()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset the trial to a fresh state: 24 hours, 4 scans, 1 window generation.")
            }

            // Expire Trial Now Button
            Button(action: {
                showExpireConfirmation = true
            }) {
                HStack {
                    if isExpiringTrial {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "hourglass.bottomhalf.filled")
                    }
                    Text("Expire Trial Now")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(isExpiringTrial ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isExpiringTrial || !gracePeriodManager.isInGracePeriod)
            .confirmationDialog("Expire Trial", isPresented: $showExpireConfirmation) {
                Button("Expire Trial", role: .destructive) {
                    expireTrialNow()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will immediately expire the trial and trigger the hard paywall.")
            }

            // Clear Subscription Status Button
            Button(action: {
                showClearSubConfirmation = true
            }) {
                HStack {
                    if isClearingSubscription {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "trash.circle.fill")
                    }
                    Text("Clear Subscription Status")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(isClearingSubscription ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isClearingSubscription)
            .confirmationDialog("Clear Subscription", isPresented: $showClearSubConfirmation) {
                Button("Clear Subscription", role: .destructive) {
                    clearSubscriptionStatus()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all subscription data from RevenueCat. Use to test non-subscribed state.")
            }

            // Mock Subscription Button
            Button(action: {
                showMockSubConfirmation = true
            }) {
                HStack {
                    if isMockingSubscription {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    Text("Mock Subscription (Active)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(isMockingSubscription ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isMockingSubscription || subscriptionManager.isSubscribed)
            .confirmationDialog("Mock Subscription", isPresented: $showMockSubConfirmation) {
                Button("Activate Mock Subscription") {
                    mockSubscription()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will simulate an active subscription. (Note: Only works if test purchases are enabled)")
            }

            // Action Message
            if !actionMessage.isEmpty {
                Text(actionMessage)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var subscriptionStatusText: String {
        switch subscriptionManager.subscriptionStatus {
        case .unknown:
            return "Unknown"
        case .trial:
            return "Trial (via RevenueCat)"
        case .active:
            return "Active Subscription"
        case .expired:
            return "Expired"
        case .gracePeriod:
            return "Grace Period (Payment Issue)"
        }
    }

    // MARK: - Actions

    private func resetTrial() {
        isResettingTrial = true
        actionMessage = ""

        Task {
            do {
                // Start fresh trial
                try await gracePeriodManager.startGracePeriod()

                await MainActor.run {
                    isResettingTrial = false
                    actionMessage = "✅ Trial reset! 24 hours, 4 scans, 1 window gen available."
                    DebugLogger.shared.success("Trial reset to fresh state")

                    // Clear message after 3 seconds
                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        actionMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isResettingTrial = false
                    actionMessage = "❌ Failed: \(error.localizedDescription)"
                    DebugLogger.shared.error("Failed to reset trial: \(error)")

                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        actionMessage = ""
                    }
                }
            }
        }
    }

    private func expireTrialNow() {
        isExpiringTrial = true
        actionMessage = ""

        Task {
            do {
                // Set grace period end date to now (expired)
                guard let userId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "TrialManagement", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "No user ID"])
                }

                let db = Firestore.firestore()
                try await db.collection("users").document(userId)
                    .collection("subscription").document("gracePeriod")
                    .updateData([
                        "endDate": Timestamp(date: Date().addingTimeInterval(-1))  // 1 second ago
                    ])

                // Update local state
                await MainActor.run {
                    gracePeriodManager.gracePeriodEndDate = Date().addingTimeInterval(-1)
                    gracePeriodManager.isInGracePeriod = false

                    isExpiringTrial = false
                    actionMessage = "✅ Trial expired! Hard paywall should appear."
                    DebugLogger.shared.success("Trial manually expired")

                    // Trigger grace period check
                    Task {
                        await gracePeriodManager.checkGracePeriodExpiration()
                    }

                    Task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        actionMessage = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isExpiringTrial = false
                    actionMessage = "❌ Failed: \(error.localizedDescription)"
                    DebugLogger.shared.error("Failed to expire trial: \(error)")

                    Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        actionMessage = ""
                    }
                }
            }
        }
    }

    private func clearSubscriptionStatus() {
        isClearingSubscription = true
        actionMessage = ""

        Task {
            // Note: This won't actually clear RevenueCat data (requires API call)
            // But we can reset local subscription state
            await subscriptionManager.checkSubscriptionStatus()

            await MainActor.run {
                isClearingSubscription = false
                actionMessage = "✅ Subscription status refreshed from RevenueCat"
                DebugLogger.shared.info("Subscription status cleared/refreshed")

                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    actionMessage = ""
                }
            }
        }
    }

    private func mockSubscription() {
        isMockingSubscription = true
        actionMessage = ""

        Task {
            await MainActor.run {
                // Note: This is a UI-only mock
                // Real subscription requires actual RevenueCat purchase
                isMockingSubscription = false
                actionMessage = "ℹ️ Mock subscription requires actual test purchase in sandbox"
                DebugLogger.shared.warning("Mock subscription not implemented - use real test purchase")

                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    actionMessage = ""
                }
            }
        }
    }
}

// MARK: - Debug Log Tab
// Note: DebugLogView, FilterChip, and DebugLogRow are defined in DebugLogger.swift
// We just reference them here in the tab switcher

// MARK: - Formatters
private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter
}()

private let debugTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
}()

private let fullDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

#Preview {
    DeveloperDashboardView()
        .preferredColorScheme(.dark)
}
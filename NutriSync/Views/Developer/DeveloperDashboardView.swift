//
//  DeveloperDashboardView.swift
//  NutriSync
//
//  Simplified version without MockDataManager
//

import SwiftUI
import FirebaseFirestore

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
                    Text("Clear All Firebase Data")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(isClearing ? 0.5 : 0.8))
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isClearing)
            .confirmationDialog("Clear All Data", isPresented: $showClearConfirmation) {
                Button("Clear ALL Data from Firebase", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete ALL data from Firebase. This action cannot be undone.")
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
                
                // Get user profile and check-in data
                guard let profile = try await firebaseProvider.getUserProfile() else {
                    throw NSError(domain: "DeveloperDashboard", code: 2,
                                userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
                }
                
                let checkIn = try await firebaseProvider.getMorningCheckIn(for: Date())
                
                // Clear and regenerate windows
                let newWindows = try await firebaseProvider.clearAndRegenerateWindows(
                    for: Date(),
                    profile: profile,
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
                let userRef = Firestore.firestore()
                    .collection("users")
                    .document("dev_user_001")
                
                // Clear all meals
                let mealsSnapshot = try await userRef
                    .collection("meals")
                    .getDocuments()
                
                for doc in mealsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Clear all windows
                let windowsSnapshot = try await userRef
                    .collection("windows")
                    .getDocuments()
                
                for doc in windowsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Clear all check-ins (IMPORTANT!)
                let checkInsSnapshot = try await userRef
                    .collection("checkIns")
                    .getDocuments()
                
                for doc in checkInsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Clear analyzing meals
                let analyzingSnapshot = try await userRef
                    .collection("analyzingMeals")
                    .getDocuments()
                
                for doc in analyzingSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Clear insights
                let insightsSnapshot = try await userRef
                    .collection("insights")
                    .getDocuments()
                
                for doc in insightsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                await MainActor.run {
                    isClearing = false
                    totalMeals = 0
                    
                    // Clear in-memory check-in data to prevent immediate regeneration
                    CheckInManager.shared.morningCheckIns.removeAll()
                    CheckInManager.shared.hasCompletedMorningCheckIn = false
                    CheckInManager.shared.postMealCheckIns.removeAll()
                    CheckInManager.shared.pendingPostMealCheckIns.removeAll()
                    
                    // Post notification to clear check-in data in ViewModels
                    NotificationCenter.default.post(name: .clearAllDataNotification, object: nil)
                    
                    DebugLogger.shared.success("Cleared all Firebase data and in-memory check-ins")
                }
            } catch {
                await MainActor.run {
                    isClearing = false
                    DebugLogger.shared.error("Failed to clear data: \(error)")
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

#Preview {
    DeveloperDashboardView()
        .preferredColorScheme(.dark)
}
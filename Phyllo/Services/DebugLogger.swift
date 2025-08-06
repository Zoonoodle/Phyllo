//
//  DebugLogger.swift
//  Phyllo
//
//  Created on 8/6/25.
//

import Foundation
import SwiftUI

// MARK: - Debug Categories
enum DebugCategory: String, CaseIterable {
    case navigation = "🧭 NAV"
    case dataProvider = "💾 DATA"
    case mealAnalysis = "🔬 ANALYSIS"
    case firebase = "🔥 FIREBASE"
    case ui = "🎨 UI"
    case notification = "🔔 NOTIF"
    case error = "❌ ERROR"
    case success = "✅ SUCCESS"
    case warning = "⚠️ WARN"
    case info = "ℹ️ INFO"
    case performance = "⚡ PERF"
    
    var color: String {
        switch self {
        case .navigation: return "🟦"
        case .dataProvider: return "🟩"
        case .mealAnalysis: return "🟪"
        case .firebase: return "🟧"
        case .ui: return "🟨"
        case .notification: return "⬜"
        case .error: return "🟥"
        case .success: return "🟢"
        case .warning: return "🟡"
        case .info: return "⚪"
        case .performance: return "🟣"
        }
    }
}

// MARK: - Debug Logger
@MainActor
class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published var isEnabled = true
    @Published var enabledCategories: Set<DebugCategory> = Set(DebugCategory.allCases)
    @Published var logHistory: [DebugLogEntry] = []
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    private init() {}
    
    // MARK: - Logging Methods
    
    func log(_ message: String, category: DebugCategory, file: String = #file, function: String = #function, line: Int = #line) {
        guard isEnabled && enabledCategories.contains(category) else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let location = "\(fileName).\(function):\(line)"
        
        let logEntry = DebugLogEntry(
            timestamp: Date(),
            category: category,
            message: message,
            location: location
        )
        
        // Add to history
        logHistory.append(logEntry)
        if logHistory.count > 1000 {
            logHistory.removeFirst(100)
        }
        
        // Print to console with formatting
        print("\n\(category.color) [\(timestamp)] \(category.rawValue)")
        print("📍 \(location)")
        print("💬 \(message)")
        print("─────────────────────────────────────────")
    }
    
    // MARK: - Convenience Methods
    
    func navigation(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .navigation, file: file, function: function, line: line)
    }
    
    func dataProvider(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .dataProvider, file: file, function: function, line: line)
    }
    
    func mealAnalysis(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .mealAnalysis, file: file, function: function, line: line)
    }
    
    func firebase(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .firebase, file: file, function: function, line: line)
    }
    
    func ui(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .ui, file: file, function: function, line: line)
    }
    
    func notification(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .notification, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .error, file: file, function: function, line: line)
    }
    
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .success, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .warning, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .info, file: file, function: function, line: line)
    }
    
    func performance(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, category: .performance, file: file, function: function, line: line)
    }
    
    // MARK: - Performance Timing
    
    func startTiming(_ label: String) -> Date {
        let start = Date()
        performance("⏱️ Started timing: \(label)")
        return start
    }
    
    func endTiming(_ label: String, start: Date) {
        let elapsed = Date().timeIntervalSince(start)
        performance("⏱️ Completed \(label) in \(String(format: "%.3f", elapsed))s")
    }
    
    // MARK: - Data Logging
    
    func logMeal(_ meal: LoggedMeal, action: String) {
        let details = """
        Meal: \(meal.name)
        ID: \(meal.id)
        Calories: \(meal.calories) | P: \(meal.protein) | C: \(meal.carbs) | F: \(meal.fat)
        Timestamp: \(dateFormatter.string(from: meal.timestamp))
        Window ID: \(meal.windowId?.uuidString ?? "nil")
        Ingredients: \(meal.ingredients.count)
        """
        dataProvider("\(action): \n\(details)")
    }
    
    func logWindow(_ window: MealWindow, action: String) {
        let details = """
        Window: \(window.purpose.rawValue)
        ID: \(window.id)
        Time: \(dateFormatter.string(from: window.startTime)) - \(dateFormatter.string(from: window.endTime))
        Purpose: \(window.purpose)
        Target Calories: \(window.targetCalories)
        """
        dataProvider("\(action): \n\(details)")
    }
    
    func logAnalyzingMeal(_ meal: AnalyzingMeal, action: String) {
        let details = """
        Analyzing Meal ID: \(meal.id)
        Timestamp: \(dateFormatter.string(from: meal.timestamp))
        Window ID: \(meal.windowId?.uuidString ?? "nil")
        Has Image: \(meal.imageData != nil)
        Voice Description: \(meal.voiceDescription ?? "nil")
        """
        mealAnalysis("\(action): \n\(details)")
    }
    
    // MARK: - Clear History
    
    func clearHistory() {
        logHistory.removeAll()
        info("Log history cleared")
    }
}

// MARK: - Debug Log Entry
struct DebugLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let category: DebugCategory
    let message: String
    let location: String
}

// MARK: - Debug View (for Developer Dashboard)
struct DebugLogView: View {
    @StateObject private var logger = DebugLogger.shared
    @State private var selectedCategory: DebugCategory? = nil
    
    var filteredLogs: [DebugLogEntry] {
        if let category = selectedCategory {
            return logger.logHistory.filter { $0.category == category }
        }
        return logger.logHistory
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(DebugCategory.allCases, id: \.self) { category in
                            FilterChip(
                                title: category.rawValue,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                Divider()
                
                // Log List
                List(filteredLogs.reversed()) { entry in
                    DebugLogRow(entry: entry)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        logger.clearHistory()
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.1))
                )
        }
    }
}

struct DebugLogRow: View {
    let entry: DebugLogEntry
    @State private var isExpanded = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.category.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(dateFormatter.string(from: entry.timestamp))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Text(entry.message)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(isExpanded ? nil : 2)
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }
            
            if isExpanded {
                Text(entry.location)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 8)
    }
}
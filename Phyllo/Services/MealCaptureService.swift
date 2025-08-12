import Foundation
import UIKit
import Combine

// MARK: - Meal Capture Service
/// Service that coordinates meal capture between data provider and AI analysis
@MainActor
class MealCaptureService: ObservableObject {
    static let shared = MealCaptureService()
    
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentError: Error?
    
    private let dataProvider = DataSourceProvider.shared.provider
    private let vertexAI = VertexAIService.shared
    private let agent = MealAnalysisAgent.shared
    private let timeProvider = TimeProvider.shared
    private let notificationManager = NotificationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Subscribe to VertexAI progress
        vertexAI.$analysisProgress
            .assign(to: &$analysisProgress)
        
        vertexAI.$isAnalyzing
            .assign(to: &$isAnalyzing)
    }
    
    /// Start analyzing a meal from captured data
    func startMealAnalysis(
        image: UIImage?,
        voiceTranscript: String? = nil,
        barcode: String? = nil
    ) async throws -> AnalyzingMeal {
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Starting meal analysis - Image: \(image != nil), Voice: \(voiceTranscript != nil), Barcode: \(barcode != nil)")
        }
        
        // Find the best window for this meal
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Fetching current windows")
        }
        let currentDate = timeProvider.currentTime
        let currentWindows = try await dataProvider.getWindows(for: currentDate)
        let now = currentDate
        
        // Debug logging for window assignment
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Finding window for meal at \(now) - \(currentWindows.count) windows available")
        }
        
        // 1) If any active window, use it
        var bestWindow = currentWindows.first { $0.contains(timestamp: now) }
        
        // 2) Otherwise, choose the nearest window by absolute time distance
        if bestWindow == nil {
            var nearest: MealWindow?
            var nearestDistance = TimeInterval.greatestFiniteMagnitude
            
            for window in currentWindows {
                let distance: TimeInterval
                if now < window.startTime {
                    distance = window.startTime.timeIntervalSince(now)
                } else if now > window.endTime {
                    distance = now.timeIntervalSince(window.endTime)
                } else {
                    distance = 0
                }
                if distance < nearestDistance {
                    nearestDistance = distance
                    nearest = window
                }
            }
            
            // 3) Nudge toward upcoming window if it's within the window's flexibility buffer
            if let upcoming = currentWindows
                .filter({ now < $0.startTime })
                .sorted(by: { $0.startTime < $1.startTime })
                .first,
               now >= upcoming.startTime.addingTimeInterval(-upcoming.flexibility.timeBuffer) {
                bestWindow = upcoming
                Task { @MainActor in
                    DebugLogger.shared.success("Assigning to upcoming window within flexibility buffer: \(upcoming.purpose.rawValue) (starts in \(Int(upcoming.startTime.timeIntervalSince(now)/60))m)")
                }
            } else if let nearest {
                bestWindow = nearest
                Task { @MainActor in
                    let mins = Int(nearestDistance/60)
                    DebugLogger.shared.warning("Assigning to nearest window by distance: \(nearest.purpose.rawValue) (\(mins)m away)")
                }
            }
        }
        
        if let window = bestWindow {
            Task { @MainActor in
                DebugLogger.shared.logWindow(window, action: "Found best window for meal")
                DebugLogger.shared.success("Assigned meal to window \(window.id) (\(window.purpose.rawValue) \(window.startTime) - \(window.endTime))")
            }
        } else {
            Task { @MainActor in
                DebugLogger.shared.warning("No suitable window found for meal - will save without window assignment")
            }
        }
        
        // Create analyzing meal
        let analyzingMeal = AnalyzingMeal(
            timestamp: now,
            windowId: bestWindow?.id,
            imageData: image.flatMap { makePreviewData(from: $0) },
            voiceDescription: voiceTranscript
        )
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Created AnalyzingMeal with ID: \(analyzingMeal.id), Window ID: \(bestWindow?.id.uuidString ?? "nil")")
        }
        
        // Start analyzing in data provider
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Starting analyzing meal in data provider")
        }
        try await dataProvider.startAnalyzingMeal(analyzingMeal)
        
        // Perform analysis in background
        Task {
            do {
                if let image = image {
                    Task { @MainActor in
                        DebugLogger.shared.mealAnalysis("Processing image-based analysis")
                    }
                    // Use VertexAI for photo analysis
                    let result = try await analyzeWithAI(
                        image: image,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed
                    if !result.clarifications.isEmpty {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("Clarification needed - \(result.clarifications.count) questions")
                        }
                        // Present clarification questions
                        await MainActor.run {
                            ClarificationManager.shared.presentClarification(
                                for: analyzingMeal,
                                with: result
                            )
                        }
                    } else {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("No clarification needed - completing analysis")
                        }
                        // No clarification needed, complete the analysis
                        var savedMeal = try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        // Preserve captured image from the session when coming from photo library/camera
                        if savedMeal.imageData == nil, let img = analyzingMeal.imageData {
                            savedMeal.imageData = img
                            try? await dataProvider.updateMeal(savedMeal)
                        }
                        
                        Task { @MainActor in
                            DebugLogger.shared.success("Meal analysis completed: \(result.mealName)")
                            DebugLogger.shared.notification("Posting mealAnalysisCompleted notification")
                        }
                        
                        // Schedule post-meal check-in reminder
                        await notificationManager.schedulePostMealCheckIn(for: savedMeal)
                        
                        // Post notification with the completed meal
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .mealAnalysisCompleted,
                                object: analyzingMeal,
                                userInfo: ["result": result, "savedMeal": savedMeal]
                            )
                        }
                    }
                    
                } else if let barcode = barcode {
                    // TODO: Implement barcode lookup
                    // For now, create a mock result
                    let mockResult = createMockBarcodeResult(barcode: barcode)
                    let savedMeal = try await dataProvider.completeAnalyzingMeal(
                        id: analyzingMeal.id.uuidString,
                        result: mockResult
                    )
                    
                    // Post notification with the completed meal
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .mealAnalysisCompleted,
                            object: analyzingMeal,
                            userInfo: ["result": mockResult, "savedMeal": savedMeal]
                        )
                    }
                    
                } else if let voiceTranscript = voiceTranscript {
                    // Voice-only analysis
                    // TODO: Implement voice-only analysis
                    let mockResult = createMockVoiceResult(transcript: voiceTranscript)
                    let savedMeal = try await dataProvider.completeAnalyzingMeal(
                        id: analyzingMeal.id.uuidString,
                        result: mockResult
                    )
                    
                    // Post notification with the completed meal
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .mealAnalysisCompleted,
                            object: analyzingMeal,
                            userInfo: ["result": mockResult, "savedMeal": savedMeal]
                        )
                    }
                }
                
            } catch {
                Task { @MainActor in
                    DebugLogger.shared.error("Meal analysis failed: \(error)")
                }
                await MainActor.run {
                    self.currentError = error
                }
                
                // Remove the analyzing meal on error so it doesn't get stuck
                do {
                    Task { @MainActor in
                        DebugLogger.shared.dataProvider("Cancelling analyzing meal due to error")
                    }
                    try await dataProvider.cancelAnalyzingMeal(id: analyzingMeal.id.uuidString)
                } catch {
                    Task { @MainActor in
                        DebugLogger.shared.error("Failed to remove analyzing meal after error: \(error)")
                    }
                }
            }
        }
        
        return analyzingMeal
    }
    
    /// Analyze meal with AI
    private func analyzeWithAI(
        image: UIImage,
        voiceTranscript: String?,
        analyzingMeal: AnalyzingMeal
    ) async throws -> MealAnalysisResult {
        
        // Get current user context
        let userProfile = try await dataProvider.getUserProfile() ?? UserProfile.defaultProfile
        
        // Find assigned window
        let windows = try await dataProvider.getWindows(for: analyzingMeal.timestamp)
        let assignedWindow = windows.first { window in
            window.contains(timestamp: analyzingMeal.timestamp)
        }
        
        // Create context for AI
        let context = UserNutritionContext(
            primaryGoal: userProfile.primaryGoal,
            dailyCalorieTarget: userProfile.dailyCalorieTarget,
            dailyProteinTarget: userProfile.dailyProteinTarget,
            dailyCarbTarget: userProfile.dailyCarbTarget,
            dailyFatTarget: userProfile.dailyFatTarget
        )
        
        // Create analysis request
        let request = MealAnalysisRequest(
            image: image,
            voiceTranscript: voiceTranscript,
            userContext: context,
            mealWindow: assignedWindow
        )
        
        // Perform AI analysis with intelligent agent tools
        return try await agent.analyzeMealWithTools(request)
    }
    
    /// Handle clarification answers
    func completeWithClarification(
        analyzingMeal: AnalyzingMeal,
        originalResult: MealAnalysisResult,
        clarificationAnswers: [String: String]
    ) async throws {
        // Compute adjusted nutrition based on clarification answers.
        // Keys are currently stored as question indices in string form. We'll map them back to options.
        var calorieDelta = 0
        var proteinDelta: Double = 0
        var carbDelta: Double = 0
        var fatDelta: Double = 0

        var appliedClarifications: [String: String] = [:] // clarificationType -> option text

        for (key, selectedOptionId) in clarificationAnswers {
            guard let questionIndex = Int(key),
                  originalResult.clarifications.indices.contains(questionIndex) else { continue }
            let question = originalResult.clarifications[questionIndex]
            // Match by exact text or case-insensitive ID fallback
            let matched = question.options.first { opt in
                let normalized = opt.text.lowercased().replacingOccurrences(of: " ", with: "_")
                return opt.text == selectedOptionId || normalized == selectedOptionId.lowercased()
            }
            if let opt = matched {
                calorieDelta += opt.calorieImpact
                proteinDelta += opt.proteinImpact ?? 0
                carbDelta += opt.carbImpact ?? 0
                fatDelta += opt.fatImpact ?? 0
                appliedClarifications[question.clarificationType] = opt.text
            }
        }

        // Apply deltas
        let adjustedCalories = max(0, originalResult.nutrition.calories + calorieDelta)
        let adjustedProtein = max(0, originalResult.nutrition.protein + proteinDelta)
        let adjustedCarbs = max(0, originalResult.nutrition.carbs + carbDelta)
        let adjustedFat = max(0, originalResult.nutrition.fat + fatDelta)

        // Build adjusted result to flow through existing save path
        let adjustedResult = MealAnalysisResult(
            mealName: originalResult.mealName,
            confidence: originalResult.confidence,
            ingredients: originalResult.ingredients,
            nutrition: .init(
                calories: adjustedCalories,
                protein: adjustedProtein,
                carbs: adjustedCarbs,
                fat: adjustedFat
            ),
            micronutrients: originalResult.micronutrients,
            clarifications: originalResult.clarifications
        )

        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Applied clarification deltas -> cal: \(calorieDelta), P: \(proteinDelta), C: \(carbDelta), F: \(fatDelta)")
            DebugLogger.shared.mealAnalysis("Adjusted totals -> \(adjustedCalories) cal, \(String(format: "%.1f", adjustedProtein))P, \(String(format: "%.1f", adjustedCarbs))C, \(String(format: "%.1f", adjustedFat))F")
        }

        // Save with adjusted result
        var savedMeal = try await dataProvider.completeAnalyzingMeal(
            id: analyzingMeal.id.uuidString,
            result: adjustedResult
        )

        // Persist applied clarifications on the saved meal and update record
        savedMeal.appliedClarifications = appliedClarifications
        // Attach image data if available from capture time
        if savedMeal.imageData == nil {
            savedMeal.imageData = analyzingMeal.imageData
        }
        try? await dataProvider.updateMeal(savedMeal)
        
        // Schedule post-meal check-in reminder
        await notificationManager.schedulePostMealCheckIn(for: savedMeal)
        
        // Post notification with the completed meal
        await MainActor.run {
            NotificationCenter.default.post(
                name: .mealAnalysisCompleted,
                object: analyzingMeal,
                userInfo: ["result": adjustedResult, "savedMeal": savedMeal]
            )
        }
    }
    
    // MARK: - Mock Results (Temporary)
    
    private func createMockBarcodeResult(barcode: String) -> MealAnalysisResult {
        MealAnalysisResult(
            mealName: "Protein Bar",
            confidence: 1.0,
            ingredients: [
                .init(name: "Protein Bar", amount: "1", unit: "bar", foodGroup: "Snack")
            ],
            nutrition: .init(
                calories: 250,
                protein: 20,
                carbs: 25,
                fat: 8
            ),
            micronutrients: [
                .init(name: "Calcium", amount: 100, unit: "mg", percentRDA: 10),
                .init(name: "Iron", amount: 2, unit: "mg", percentRDA: 11)
            ],
            clarifications: []
        )
    }
    
    private func createMockVoiceResult(transcript: String) -> MealAnalysisResult {
        MealAnalysisResult(
            mealName: "Voice Logged Meal",
            confidence: 0.7,
            ingredients: [
                .init(name: "Unknown", amount: "1", unit: "serving", foodGroup: "Unknown")
            ],
            nutrition: .init(
                calories: 400,
                protein: 25,
                carbs: 45,
                fat: 15
            ),
            micronutrients: [],
            clarifications: []
        )
    }
}

// MARK: - Helper Extensions

private func makePreviewData(from image: UIImage) -> Data? {
    // Create a small preview image suitable for Firestore (<1 MB)
    let maxDimension: CGFloat = 640
    let widthScale = maxDimension / image.size.width
    let heightScale = maxDimension / image.size.height
    let scale = min(1.0, min(widthScale, heightScale))
    let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resized?.jpegData(compressionQuality: 0.65)
}

// MARK: - Notification Names

extension Notification.Name {
    static let mealAnalysisStarted = Notification.Name("mealAnalysisStarted")
    static let mealAnalysisCompleted = Notification.Name("mealAnalysisCompleted")
    static let mealAnalysisFailed = Notification.Name("mealAnalysisFailed")
}
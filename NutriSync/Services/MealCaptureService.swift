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
    
    // Store last analysis metadata for celebration nudge
    private var lastAnalysisMetadata: [UUID: AnalysisMetadata] = [:]
    
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
        barcode: String? = nil,
        timestamp: Date? = nil
    ) async throws -> AnalyzingMeal {
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Starting meal analysis - Image: \(image != nil), Voice: \(voiceTranscript != nil), Barcode: \(barcode != nil)")
        }
        
        // Validate that we have at least one input
        let hasImage = image != nil
        let hasVoice = voiceTranscript != nil && !voiceTranscript!.isEmpty
        let hasBarcode = barcode != nil && !barcode!.isEmpty
        
        if !hasImage && !hasVoice && !hasBarcode {
            Task { @MainActor in
                DebugLogger.shared.error("Cannot analyze meal without any input (no image, voice, or barcode)")
            }
            throw NSError(
                domain: "MealCaptureService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Cannot analyze meal without any input. Please capture a photo, provide a voice description, or scan a barcode."]
            )
        }
        
        // Find the best window for this meal
        Task { @MainActor in
            DebugLogger.shared.dataProvider("Fetching current windows")
        }
        let mealTimestamp = timestamp ?? timeProvider.currentTime
        let windowsDate = Calendar.current.startOfDay(for: mealTimestamp)
        let currentWindows = try await dataProvider.getWindows(for: windowsDate)
        let now = mealTimestamp
        
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
        let previewData = image.flatMap { makePreviewData(from: $0) }
        
        Task { @MainActor in
            if let image = image {
                let imageSize = image.size
                let imageMB = (image.jpegData(compressionQuality: 1.0)?.count ?? 0) / (1024 * 1024)
                DebugLogger.shared.mealAnalysis("Image provided: \(imageSize.width)x\(imageSize.height), ~\(imageMB)MB")
                if previewData == nil {
                    DebugLogger.shared.warning("Failed to create preview data from image")
                } else {
                    DebugLogger.shared.info("Preview data created: \(previewData?.count ?? 0) bytes")
                }
            } else {
                DebugLogger.shared.mealAnalysis("No image provided for analysis")
            }
        }
        
        let analyzingMeal = AnalyzingMeal(
            timestamp: now,
            windowId: bestWindow?.id,
            imageData: previewData,
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
                    let (result, analysisMetadata) = try await analyzeWithAI(
                        image: image,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed (always show if confidence < 0.85 or clarifications exist)
                    if !result.clarifications.isEmpty || result.confidence < 0.85 {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("Clarification needed - \(result.clarifications.count) questions (confidence: \(result.confidence))")
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
                        
                        // Store metadata for celebration nudge
                        storeAnalysisMetadata(analysisMetadata, for: savedMeal.id)
                        
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
                                userInfo: ["result": result, "savedMeal": savedMeal, "metadata": analysisMetadata as Any]
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
                    Task { @MainActor in
                        DebugLogger.shared.mealAnalysis("Processing voice-only analysis")
                    }
                    
                    // Use VertexAI for voice-only analysis
                    let (result, analysisMetadata) = try await analyzeWithAI(
                        image: nil,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed (always show if confidence < 0.85 or clarifications exist)
                    if !result.clarifications.isEmpty || result.confidence < 0.85 {
                        Task { @MainActor in
                            DebugLogger.shared.mealAnalysis("Clarification needed with \(result.clarifications.count) questions")
                        }
                        // Complete the meal in data provider
                        let savedMeal = try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        
                        // Store metadata for celebration nudge
                        storeAnalysisMetadata(analysisMetadata, for: savedMeal.id)
                        
                        // Post notification with clarification
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .mealAnalysisClarificationNeeded,
                                object: analyzingMeal,
                                userInfo: ["result": result, "savedMeal": savedMeal, "metadata": analysisMetadata as Any]
                            )
                        }
                    } else {
                        // Complete analysis without clarification
                        var savedMeal = try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        
                        // Store metadata for celebration nudge
                        storeAnalysisMetadata(analysisMetadata, for: savedMeal.id)
                        
                        Task { @MainActor in
                            DebugLogger.shared.success("Voice-only meal analysis completed: \(result.mealName)")
                            DebugLogger.shared.notification("Posting mealAnalysisCompleted notification")
                        }
                        
                        // Schedule post-meal check-in reminder
                        await notificationManager.schedulePostMealCheckIn(for: savedMeal)
                        
                        // Post notification with the completed meal
                        await MainActor.run {
                            NotificationCenter.default.post(
                                name: .mealAnalysisCompleted,
                                object: analyzingMeal,
                                userInfo: ["result": result, "savedMeal": savedMeal, "metadata": analysisMetadata as Any]
                            )
                        }
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
        image: UIImage?,
        voiceTranscript: String?,
        analyzingMeal: AnalyzingMeal
    ) async throws -> (MealAnalysisResult, AnalysisMetadata?) {
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("analyzeWithAI called - Image: \(image != nil), Voice: \(voiceTranscript != nil ? "\"\(voiceTranscript!)\"" : "nil")")
            if let image = image {
                DebugLogger.shared.info("Image size for AI: \(image.size.width)x\(image.size.height)")
            }
        }
        
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
        
        Task { @MainActor in
            DebugLogger.shared.mealAnalysis("Created MealAnalysisRequest - Has Image: \(request.image != nil), Has Voice: \(request.voiceTranscript != nil)")
        }
        
        // Perform AI analysis with intelligent agent tools
        let (result, metadata) = try await agent.analyzeMealWithTools(request)
        
        // Note: metadata is available but we can't modify the analyzingMeal parameter
        // The metadata will be available in the notification userInfo instead
        
        return (result, metadata)
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
            clarifications: originalResult.clarifications,
            requestedTools: originalResult.requestedTools,
            brandDetected: originalResult.brandDetected
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
                userInfo: ["result": adjustedResult, "savedMeal": savedMeal, "metadata": Optional<AnalysisMetadata>.none as Any]
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
            clarifications: [],
            requestedTools: nil,
            brandDetected: nil
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
            clarifications: [],
            requestedTools: nil,
            brandDetected: nil
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

// MARK: - Metadata Management

extension MealCaptureService {
    func getAnalysisMetadata(for mealId: UUID) -> AnalysisMetadata? {
        return lastAnalysisMetadata[mealId]
    }
    
    private func storeAnalysisMetadata(_ metadata: AnalysisMetadata?, for mealId: UUID) {
        guard let metadata = metadata else { return }
        lastAnalysisMetadata[mealId] = metadata
        
        // Clean up old metadata (keep only last 10)
        if lastAnalysisMetadata.count > 10 {
            let sortedKeys = lastAnalysisMetadata.keys.sorted { a, b in
                // Keep most recent based on insertion order (no timestamp available)
                return true
            }
            if let oldestKey = sortedKeys.first {
                lastAnalysisMetadata.removeValue(forKey: oldestKey)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let mealAnalysisStarted = Notification.Name("mealAnalysisStarted")
    static let mealAnalysisCompleted = Notification.Name("mealAnalysisCompleted")
    static let mealAnalysisFailed = Notification.Name("mealAnalysisFailed")
    static let mealAnalysisClarificationNeeded = Notification.Name("mealAnalysisClarificationNeeded")
}
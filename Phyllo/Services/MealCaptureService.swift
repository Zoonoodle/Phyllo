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
        DebugLogger.shared.mealAnalysis("Starting meal analysis - Image: \(image != nil), Voice: \(voiceTranscript != nil), Barcode: \(barcode != nil)")
        
        // Find the active window for this meal
        DebugLogger.shared.dataProvider("Fetching current windows")
        let currentWindows = try await dataProvider.getWindows(for: Date())
        let activeWindow = currentWindows.first { window in
            window.contains(timestamp: Date())
        }
        if let window = activeWindow {
            DebugLogger.shared.logWindow(window, action: "Found active window")
        } else {
            DebugLogger.shared.warning("No active window found for current time")
        }
        
        // Create analyzing meal
        let analyzingMeal = AnalyzingMeal(
            timestamp: Date(),
            windowId: activeWindow?.id,
            imageData: image?.jpegData(compressionQuality: 0.8),
            voiceDescription: voiceTranscript
        )
        
        // Start analyzing in data provider
        DebugLogger.shared.dataProvider("Starting analyzing meal in data provider")
        try await dataProvider.startAnalyzingMeal(analyzingMeal)
        
        // Perform analysis in background
        Task {
            do {
                if let image = image {
                    DebugLogger.shared.mealAnalysis("Processing image-based analysis")
                    // Use VertexAI for photo analysis
                    let result = try await analyzeWithAI(
                        image: image,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed
                    if !result.clarifications.isEmpty {
                        DebugLogger.shared.mealAnalysis("Clarification needed - \(result.clarifications.count) questions")
                        // Present clarification questions
                        await MainActor.run {
                            ClarificationManager.shared.presentClarification(
                                for: analyzingMeal,
                                with: result
                            )
                        }
                    } else {
                        DebugLogger.shared.mealAnalysis("No clarification needed - completing analysis")
                        // No clarification needed, complete the analysis
                        try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
                        
                        DebugLogger.shared.success("Meal analysis completed: \(result.mealName)")
                        
                        // Post notification with the completed meal
                        await MainActor.run {
                            DebugLogger.shared.notification("Posting mealAnalysisCompleted notification")
                            NotificationCenter.default.post(
                                name: .mealAnalysisCompleted,
                                object: analyzingMeal,
                                userInfo: ["result": result]
                            )
                        }
                    }
                    
                } else if let barcode = barcode {
                    // TODO: Implement barcode lookup
                    // For now, create a mock result
                    let mockResult = createMockBarcodeResult(barcode: barcode)
                    try await dataProvider.completeAnalyzingMeal(
                        id: analyzingMeal.id.uuidString,
                        result: mockResult
                    )
                    
                } else if let voiceTranscript = voiceTranscript {
                    // Voice-only analysis
                    // TODO: Implement voice-only analysis
                    let mockResult = createMockVoiceResult(transcript: voiceTranscript)
                    try await dataProvider.completeAnalyzingMeal(
                        id: analyzingMeal.id.uuidString,
                        result: mockResult
                    )
                }
                
            } catch {
                DebugLogger.shared.error("Meal analysis failed: \(error)")
                await MainActor.run {
                    self.currentError = error
                }
                
                // Remove the analyzing meal on error so it doesn't get stuck
                do {
                    DebugLogger.shared.dataProvider("Cancelling analyzing meal due to error")
                    try await dataProvider.cancelAnalyzingMeal(id: analyzingMeal.id.uuidString)
                } catch {
                    DebugLogger.shared.error("Failed to remove analyzing meal after error: \(error)")
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
        let userProfile = try await dataProvider.getUserProfile() ?? UserProfile.mockProfile
        
        // Find assigned window
        let windows = try await dataProvider.getWindows(for: Date())
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
        
        // Perform AI analysis
        return try await vertexAI.analyzeMeal(request)
    }
    
    /// Handle clarification answers
    func completeWithClarification(
        analyzingMeal: AnalyzingMeal,
        originalResult: MealAnalysisResult,
        clarificationAnswers: [String: String]
    ) async throws {
        
        // TODO: Re-analyze with clarification answers
        // For now, just complete with original result
        
        try await dataProvider.completeAnalyzingMeal(
            id: analyzingMeal.id.uuidString,
            result: originalResult
        )
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
            clarifications: [
                .init(
                    question: "What type of meal was this?",
                    options: ["Breakfast", "Lunch", "Dinner", "Snack"],
                    clarificationType: "meal_type"
                )
            ]
        )
    }
}

// MARK: - Helper Extensions

// MARK: - Notification Names

extension Notification.Name {
    static let mealAnalysisStarted = Notification.Name("mealAnalysisStarted")
    static let mealAnalysisCompleted = Notification.Name("mealAnalysisCompleted")
    static let mealAnalysisFailed = Notification.Name("mealAnalysisFailed")
}
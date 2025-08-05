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
        
        // Find the active window for this meal
        let currentWindows = try await dataProvider.getWindows(for: Date())
        let activeWindow = currentWindows.first { window in
            window.contains(timestamp: Date())
        }
        
        // Create analyzing meal
        var analyzingMeal = AnalyzingMeal(
            timestamp: Date(),
            windowId: activeWindow?.id,
            imageData: image?.jpegData(compressionQuality: 0.8),
            voiceDescription: voiceTranscript
        )
        
        // Start analyzing in data provider
        try await dataProvider.startAnalyzingMeal(analyzingMeal)
        
        // Perform analysis in background
        Task {
            do {
                if let image = image {
                    // Use VertexAI for photo analysis
                    let result = try await analyzeWithAI(
                        image: image,
                        voiceTranscript: voiceTranscript,
                        analyzingMeal: analyzingMeal
                    )
                    
                    // Check if clarification is needed
                    if !result.clarifications.isEmpty {
                        // Present clarification questions
                        await MainActor.run {
                            ClarificationManager.shared.presentClarification(
                                for: analyzingMeal,
                                with: result
                            )
                        }
                    } else {
                        // No clarification needed, complete the analysis
                        try await dataProvider.completeAnalyzingMeal(
                            id: analyzingMeal.id.uuidString,
                            result: result
                        )
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
                self.currentError = error
                print("❌ Meal analysis failed: \(error)")
                // TODO: Remove analyzing meal on error
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
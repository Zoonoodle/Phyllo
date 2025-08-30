# Firebase AI Logic (Vertex AI) 2025 - Complete Integration Guide

## Overview
Firebase AI Logic (formerly Vertex AI in Firebase) provides seamless integration of Gemini models into iOS apps.

## Setup & Installation

### Swift Package Manager
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
]
```

## API Provider Selection

### Gemini Developer API (Recommended for Start)
- **Free tier**: No-cost prototyping
- **Best for**: Quick development, POCs
- **Limitations**: Rate limits, basic features

### Vertex AI Gemini API (Production)
- **Enterprise features**: High availability, scalability
- **Governance**: Full audit trails
- **Performance**: Robust for production loads

## Swift Implementation

### Basic Setup
```swift
import FirebaseVertexAI
import FirebaseCore

// App initialization
FirebaseApp.configure()

// Initialize Vertex AI
let vertexAI = VertexAI.vertexAI()
```

### Model Configuration
```swift
// Gemini Flash for quick responses
let flashModel = vertexAI.generativeModel(
    model: "gemini-2.0-flash",
    generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.95,
        topK: 40,
        maxOutputTokens: 2000,
        responseMimeType: "application/json"
    ),
    systemInstruction: """
        You are a nutrition expert AI assistant.
        Analyze meal photos and provide structured JSON responses.
        Be concise and accurate.
    """
)

// Gemini Pro for complex tasks
let proModel = vertexAI.generativeModel(
    model: "gemini-2.0-pro",
    generationConfig: GenerationConfig(
        maxOutputTokens: 1500
    )
)
```

### Multimodal Prompts with Images
```swift
func analyzeMealPhoto(_ image: UIImage) async throws -> MealAnalysis {
    // Compress image for cost optimization
    guard let imageData = image.jpegData(compressionQuality: 0.7),
          imageData.count <= 500_000 else {
        throw AnalysisError.imageTooLarge
    }
    
    let prompt = """
    Analyze this meal photo and return JSON:
    {
        "items": [
            {
                "name": "string",
                "portion": "string",
                "calories": number,
                "protein": number,
                "carbs": number,
                "fat": number
            }
        ],
        "confidence": 0.0-1.0,
        "clarifications": ["max 2 questions"]
    }
    """
    
    let response = try await flashModel.generateContent(prompt, imageData)
    return try JSONDecoder().decode(MealAnalysis.self, from: response.data)
}
```

### Structured Output with JSON Schema
```swift
let schema = """
{
    "type": "object",
    "properties": {
        "windows": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "start": {"type": "string"},
                    "end": {"type": "string"},
                    "purpose": {"type": "string"},
                    "targetCalories": {"type": "number"},
                    "macros": {
                        "type": "object",
                        "properties": {
                            "protein": {"type": "number"},
                            "carbs": {"type": "number"},
                            "fat": {"type": "number"}
                        }
                    }
                }
            }
        }
    }
}
"""

let config = GenerationConfig(
    responseMimeType: "application/json",
    responseSchema: schema
)
```

## Security Implementation

### Firebase App Check
```swift
import FirebaseAppCheck

// Configure App Check
let providerFactory = AppCheckDebugProviderFactory()
AppCheck.setAppCheckProviderFactory(providerFactory)

// Protect API calls
func secureAPICall() async throws {
    let token = try await AppCheck.appCheck().token(forcingRefresh: false)
    // Include token in API requests
}
```

### Security Rules
```javascript
// Firestore rules for AI data
match /users/{userId}/ai_requests/{requestId} {
    allow read, write: if request.auth != null 
        && request.auth.uid == userId
        && request.time < resource.data.expiry;
}
```

## Cost Optimization

### Token Pricing (2025)
```swift
struct GeminiPricing {
    // Gemini Flash
    static let flashInput = 0.075 / 1_000_000  // per token
    static let flashOutput = 0.30 / 1_000_000  // per token
    
    // Gemini Pro  
    static let proInput = 0.50 / 1_000_000
    static let proOutput = 1.50 / 1_000_000
    
    // Cost targets
    static let maxCostPerMealScan = 0.03  // $0.03
    static let maxCostPerWindowGen = 0.03  // $0.03
}
```

### Optimization Strategies
```swift
extension PromptOptimizer {
    // Minimize tokens
    static func compress(_ prompt: String) -> String {
        return prompt
            .replacingOccurrences(of: "please ", with: "")
            .replacingOccurrences(of: "could you ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Cache frequent responses
    static let responseCache = NSCache<NSString, CachedResponse>()
    
    // Batch similar requests
    static func batchRequests(_ requests: [Request]) -> BatchedRequest {
        // Combine similar prompts to reduce API calls
    }
}
```

## Cloud Storage Integration

### Large File Handling
```swift
import FirebaseStorage

func uploadAndAnalyze(_ image: UIImage) async throws {
    let storage = Storage.storage()
    let imageRef = storage.reference().child("meals/\(UUID().uuidString).jpg")
    
    // Upload compressed image
    guard let data = image.jpegData(compressionQuality: 0.7) else { return }
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    
    _ = try await imageRef.putDataAsync(data, metadata: metadata)
    let url = try await imageRef.downloadURL()
    
    // Reference in prompt
    let prompt = "Analyze the meal at: \(url.absoluteString)"
    // Auto-delete after 24 hours via lifecycle rules
}
```

## Remote Config Integration

### Dynamic Prompt Management
```swift
import FirebaseRemoteConfig

class PromptManager {
    static func fetchPrompts() async {
        let remoteConfig = RemoteConfig.remoteConfig()
        
        // Set defaults
        remoteConfig.setDefaults([
            "meal_analysis_prompt": defaultMealPrompt,
            "window_generation_prompt": defaultWindowPrompt,
            "model_version": "gemini-2.0-flash"
        ])
        
        // Fetch and activate
        try? await remoteConfig.fetchAndActivate()
        
        // Use updated values
        let prompt = remoteConfig["meal_analysis_prompt"].stringValue
        let model = remoteConfig["model_version"].stringValue
    }
}
```

## Function Calling

### Extend Model Capabilities
```swift
let tools = [
    Tool(
        functionDeclarations: [
            FunctionDeclaration(
                name: "getNutritionData",
                description: "Get nutrition info for food items",
                parameters: [
                    "foodName": .string(description: "Name of food"),
                    "quantity": .number(description: "Amount in grams")
                ]
            )
        ]
    )
]

let model = vertexAI.generativeModel(
    model: "gemini-2.0-flash",
    tools: tools
)

// Handle function calls in response
if let functionCall = response.functionCalls.first {
    let result = await executeFunction(functionCall)
    // Send result back to model
}
```

## Error Handling

```swift
enum AIError: Error {
    case quotaExceeded
    case invalidResponse
    case networkError
    case tokenLimitExceeded
    
    var userMessage: String {
        switch self {
        case .quotaExceeded:
            return "Daily limit reached. Try again tomorrow."
        case .invalidResponse:
            return "Could not analyze. Please try again."
        case .networkError:
            return "Check your connection and retry."
        case .tokenLimitExceeded:
            return "Response too long. Simplifying request."
        }
    }
}

// Retry logic
func withRetry<T>(
    maxAttempts: Int = 3,
    delay: TimeInterval = 1.0,
    operation: () async throws -> T
) async throws -> T {
    for attempt in 1...maxAttempts {
        do {
            return try await operation()
        } catch {
            if attempt == maxAttempts { throw error }
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    throw AIError.networkError
}
```

## Best Practices

1. **Start with Gemini Developer API** for prototyping
2. **Implement App Check** before production
3. **Compress images** to < 500KB
4. **Cache responses** aggressively
5. **Use structured output** with JSON schemas
6. **Monitor costs** via Firebase Console
7. **Set rate limits** per user
8. **Handle errors gracefully**
9. **Use Remote Config** for prompt iteration
10. **Batch similar requests** when possible

## Model Selection Guide

### Gemini 2.0 Flash
- **Use for**: Meal photo analysis, quick responses
- **Token limit**: 2000 output tokens
- **Response time**: < 2 seconds
- **Cost**: ~$0.01-0.02 per request

### Gemini 2.0 Pro
- **Use for**: Complex window generation, reasoning
- **Token limit**: 1500 output tokens
- **Response time**: 2-5 seconds
- **Cost**: ~$0.02-0.03 per request

### Gemini 2.5 (Preview)
- **Location**: Global only
- **Features**: Enhanced reasoning, better context
- **Note**: No three-digit suffix in model names
# Plan: Authentication & Onboarding Integration
## Option C - Hybrid Progressive Approach

**Plan Date:** 2025-01-09  
**Planner:** Claude (Phase 2: Planning Agent)  
**Approach:** Hybrid Progressive with Silent Anonymous Auth  
**Timeline:** 2-3 weeks for full implementation

---

## 🎯 Strategic Overview

### Chosen Approach: Option C - Hybrid Progressive
We're implementing a user-friendly approach that combines the best of anonymous and authenticated experiences:

1. **Silent anonymous authentication** on first launch
2. **Immediate onboarding** without barriers
3. **Progressive data saving** throughout onboarding
4. **Soft account creation prompts** at strategic points
5. **Seamless upgrade path** from anonymous to authenticated
6. **TestFlight-optimized** for comprehensive testing

### Why Option C for TestFlight
- Lowest friction for testers
- Tests both anonymous and authenticated flows
- Provides metrics on voluntary account creation
- Simulates real App Store user experience
- Allows quick testing without commitment

---

## 📋 Implementation Phases

### Phase 1: Foundation (Days 1-3)
**Goal:** Establish authentication infrastructure and routing

### Phase 2: Profile Integration (Days 4-6)
**Goal:** Connect onboarding with Firebase profile creation

### Phase 3: Progressive Saving (Days 7-9)
**Goal:** Implement data persistence during onboarding

### Phase 4: Account Upgrade (Days 10-12)
**Goal:** Add optional account creation flow

### Phase 5: Polish & Testing (Days 13-15)
**Goal:** Error handling, edge cases, and TestFlight preparation

---

## 🔄 User Experience Flows

### Flow 1: New User Journey
```
App Launch (First Time)
    ↓
Silent Anonymous Auth (automatic)
    ↓
Check Profile Existence (none found)
    ↓
Start Onboarding Immediately
    ↓
Section 1: Basic Info
    ↓
[SOFT PROMPT: Create Account?]
    → Skip (continue anonymous)
    → Create (show options)
    ↓
Continue Onboarding (Sections 2-5)
    ↓
Complete & Save Profile
    ↓
Generate Initial Windows
    ↓
Navigate to Main App
```

### Flow 2: Returning Anonymous User
```
App Launch
    ↓
Check Existing Auth (anonymous found)
    ↓
Check Profile Existence (found)
    ↓
Load Profile & Settings
    ↓
Navigate to Main App
    ↓
[PERIODIC: Account upgrade prompts]
```

### Flow 3: Account Upgrade Flow
```
User Chooses "Create Account"
    ↓
Show Account Options:
- Continue with Apple (recommended)
- Email & Password
- Skip for Now
    ↓
If Apple/Email Selected:
    ↓
Link Anonymous Account
    ↓
Preserve All Data
    ↓
Update Profile with Email
    ↓
Show Success & Benefits
```

### Flow 4: TestFlight-Specific Flow
```
Detect TestFlight Build
    ↓
Add Debug Overlay
    ↓
Show "TestFlight" Badge
    ↓
Enable Extra Logging
    ↓
Track Additional Metrics
```

---

## 🛠 Technical Implementation Tasks

### PHASE 1: Foundation (Days 1-3)

#### Task 1.1: Fix Firebase Authentication
**File:** `NutriSync/FirebaseConfig.swift`

```swift
// Current state: Has methods but not called
// Target state: Auto-initialize on app launch

class FirebaseConfig: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isAnonymous = true
    @Published var authState: AuthState = .unknown
    
    enum AuthState {
        case unknown
        case authenticating
        case anonymous
        case authenticated
        case failed(Error)
    }
    
    func initializeAuth() async {
        authState = .authenticating
        
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            self.isAnonymous = user.isAnonymous
            self.authState = user.isAnonymous ? .anonymous : .authenticated
        } else {
            await signInAnonymously()
        }
    }
    
    func signInAnonymously() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.currentUser = result.user
            self.isAuthenticated = true
            self.isAnonymous = true
            self.authState = .anonymous
        } catch {
            self.authState = .failed(error)
            // Handle offline mode
        }
    }
}
```

#### Task 1.2: Update App Entry Point
**File:** `NutriSync/PhylloApp.swift`

```swift
@main
struct PhylloApp: App {
    @StateObject private var firebaseConfig = FirebaseConfig.shared
    @StateObject private var dataProvider = FirebaseDataProvider.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(firebaseConfig)
                .environmentObject(dataProvider)
                .task {
                    await firebaseConfig.initializeAuth()
                }
        }
    }
}
```

#### Task 1.3: Implement Smart Routing
**File:** `NutriSync/Views/ContentView.swift`

```swift
struct ContentView: View {
    @EnvironmentObject private var firebaseConfig: FirebaseConfig
    @EnvironmentObject private var dataProvider: FirebaseDataProvider
    @State private var hasProfile = false
    @State private var isCheckingProfile = true
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            switch firebaseConfig.authState {
            case .unknown, .authenticating:
                LoadingView(message: "Initializing...")
                
            case .failed(let error):
                AuthErrorView(error: error) {
                    Task {
                        await firebaseConfig.initializeAuth()
                    }
                }
                
            case .anonymous, .authenticated:
                if isCheckingProfile {
                    LoadingView(message: "Loading your profile...")
                } else if !hasProfile {
                    OnboardingCoordinator()
                        .environmentObject(firebaseConfig)
                        .environmentObject(dataProvider)
                } else {
                    MainTabView()
                        .environmentObject(firebaseConfig)
                        .environmentObject(dataProvider)
                }
            }
        }
        .task {
            await checkProfileExistence()
        }
        .onChange(of: firebaseConfig.authState) { _, newState in
            if case .anonymous = newState {
                Task {
                    await checkProfileExistence()
                }
            } else if case .authenticated = newState {
                Task {
                    await checkProfileExistence()
                }
            }
        }
    }
    
    private func checkProfileExistence() async {
        guard firebaseConfig.isAuthenticated else { return }
        
        isCheckingProfile = true
        do {
            hasProfile = try await dataProvider.hasCompletedOnboarding()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            hasProfile = false
        }
        isCheckingProfile = false
    }
}
```

#### Task 1.4: Update FirebaseDataProvider
**File:** `NutriSync/Services/DataProvider/FirebaseDataProvider.swift`

```swift
// CRITICAL: Replace ALL instances of hardcoded userId
// From: private let userId = "dev_user_001"
// To: private var userId: String? { Auth.auth().currentUser?.uid }

extension FirebaseDataProvider {
    func hasCompletedOnboarding() async throws -> Bool {
        guard let userId = userId else { 
            throw DataProviderError.notAuthenticated 
        }
        
        let profileDoc = db.collection("users")
            .document(userId)
            .collection("profile")
            .document("current")
        
        let snapshot = try await profileDoc.getDocument()
        
        // Check if profile exists and has minimum required fields
        if let data = snapshot.data(),
           data["name"] != nil,
           data["age"] != nil,
           data["heightCM"] != nil,
           data["weightKG"] != nil {
            return true
        }
        
        return false
    }
}
```

---

### PHASE 2: Profile Integration (Days 4-6)

#### Task 2.1: Create Onboarding Progress Model
**File:** `NutriSync/Models/OnboardingProgress.swift` (NEW)

```swift
import Foundation
import FirebaseFirestore

struct OnboardingProgress: Codable {
    let userId: String
    var currentSection: Int
    var currentStep: Int
    var completedSections: Set<Int>
    
    // Section 1: Basic Info
    var name: String?
    var age: Int?
    var biologicalSex: BiologicalSex?
    var heightCM: Double?
    var weightKG: Double?
    var activityLevel: ActivityLevel?
    var bodyFatPercentage: Double?
    
    // Section 2: Goals
    var primaryGoal: UserGoals.PrimaryGoal?
    var targetWeightKG: Double?
    var weeklyWeightChangeKG: Double?
    var minimumCalories: Int?
    
    // Section 3: Lifestyle
    var wakeTime: Date?
    var bedTime: Date?
    var mealsPerDay: Int?
    var eatingWindowHours: Int?
    var breakfastPreference: Bool?
    var dietaryRestrictions: [String]?
    var dietType: String?
    
    // Section 4: Training
    var workoutsPerWeek: Int?
    var workoutDays: [Int]?
    var workoutTimes: [Date]?
    var trainingType: String?
    
    // Section 5: Optimization
    var energyPatterns: [String: Int]?
    var scheduleFlexibility: Int?
    var notificationSettings: NotificationSettings?
    
    // Metadata
    var lastUpdated: Date
    var isComplete: Bool
    
    func toFirestore() -> [String: Any] {
        // Convert to Firestore-compatible dictionary
        var dict: [String: Any] = [
            "userId": userId,
            "currentSection": currentSection,
            "currentStep": currentStep,
            "completedSections": Array(completedSections),
            "lastUpdated": Timestamp(date: lastUpdated),
            "isComplete": isComplete
        ]
        
        // Add optional fields if present
        if let name = name { dict["name"] = name }
        if let age = age { dict["age"] = age }
        // ... (add all other optional fields)
        
        return dict
    }
    
    static func fromFirestore(_ data: [String: Any]) -> OnboardingProgress? {
        // Parse from Firestore document
        // Implementation details...
    }
}
```

#### Task 2.2: Extend OnboardingCoordinator
**File:** `NutriSync/Views/Onboarding/OnboardingCoordinator.swift`

```swift
@Observable
class OnboardingCoordinator: ObservableObject {
    @Published var progress = OnboardingProgress(
        userId: Auth.auth().currentUser?.uid ?? "",
        currentSection: 1,
        currentStep: 1,
        completedSections: [],
        lastUpdated: Date(),
        isComplete: false
    )
    
    @Published var showAccountCreation = false
    @Published var isSaving = false
    @Published var saveError: Error?
    
    private let dataProvider: FirebaseDataProvider
    
    // Add auto-save on section completion
    func completeSection(_ section: Int) {
        progress.completedSections.insert(section)
        progress.currentSection = section + 1
        progress.currentStep = 1
        
        Task {
            await saveProgress()
            
            // Show account prompt after Section 1
            if section == 1 && Auth.auth().currentUser?.isAnonymous == true {
                showAccountCreation = true
            }
        }
    }
    
    @MainActor
    private func saveProgress() async {
        isSaving = true
        do {
            try await dataProvider.saveOnboardingProgress(progress)
        } catch {
            saveError = error
            // Queue for retry
        }
        isSaving = false
    }
    
    func completeOnboarding() async throws {
        // Build UserProfile from progress
        let profile = buildUserProfile()
        let goals = buildUserGoals()
        
        // Save in transaction
        try await dataProvider.createUserProfile(
            profile: profile,
            goals: goals,
            deleteProgress: true
        )
        
        // Generate initial windows
        try await dataProvider.generateInitialWindows()
        
        progress.isComplete = true
    }
}
```

#### Task 2.3: Update ReviewProgramView
**File:** `NutriSync/Views/Onboarding/ReviewProgramView.swift`

```swift
struct ReviewProgramView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @EnvironmentObject var dataProvider: FirebaseDataProvider
    @State private var isCreatingProfile = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToApp = false
    
    var body: some View {
        ScrollView {
            // ... existing review content ...
            
            Button(action: startJourney) {
                if isCreatingProfile {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Start Your Journey")
                }
            }
            .disabled(isCreatingProfile)
        }
        .navigationDestination(isPresented: $navigateToApp) {
            MainTabView()
                .navigationBarBackButtonHidden(true)
        }
        .alert("Setup Error", isPresented: $showError) {
            Button("Retry") {
                startJourney()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func startJourney() {
        Task {
            isCreatingProfile = true
            
            do {
                // Complete onboarding and create profile
                try await coordinator.completeOnboarding()
                
                // Add haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                
                // Navigate to main app
                navigateToApp = true
                
            } catch {
                errorMessage = "Failed to create your profile: \(error.localizedDescription)"
                showError = true
            }
            
            isCreatingProfile = false
        }
    }
}
```

---

### PHASE 3: Progressive Saving (Days 7-9)

#### Task 3.1: Implement Progressive Save Service
**File:** `NutriSync/Services/DataProvider/FirebaseDataProvider+Onboarding.swift` (NEW)

```swift
extension FirebaseDataProvider {
    
    func saveOnboardingProgress(_ progress: OnboardingProgress) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw DataProviderError.notAuthenticated
        }
        
        let progressRef = db.collection("users")
            .document(userId)
            .collection("onboarding")
            .document("progress")
        
        try await progressRef.setData(progress.toFirestore())
    }
    
    func loadOnboardingProgress() async throws -> OnboardingProgress? {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw DataProviderError.notAuthenticated
        }
        
        let progressRef = db.collection("users")
            .document(userId)
            .collection("onboarding")
            .document("progress")
        
        let snapshot = try await progressRef.getDocument()
        
        guard let data = snapshot.data() else { return nil }
        
        return OnboardingProgress.fromFirestore(data)
    }
    
    func createUserProfile(
        profile: UserProfile,
        goals: UserGoals,
        deleteProgress: Bool = true
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw DataProviderError.notAuthenticated
        }
        
        let batch = db.batch()
        
        // Create profile document
        let profileRef = db.collection("users")
            .document(userId)
            .collection("profile")
            .document("current")
        batch.setData(profile.toFirestore(), forDocument: profileRef)
        
        // Create goals document
        let goalsRef = db.collection("users")
            .document(userId)
            .collection("goals")
            .document("current")
        batch.setData(goals.toFirestore(), forDocument: goalsRef)
        
        // Delete progress if requested
        if deleteProgress {
            let progressRef = db.collection("users")
                .document(userId)
                .collection("onboarding")
                .document("progress")
            batch.deleteDocument(progressRef)
        }
        
        // Commit transaction
        try await batch.commit()
    }
}
```

#### Task 3.2: Add Auto-Save Triggers
**File:** `NutriSync/Views/Onboarding/NutriSyncOnboarding/BasicInfoView.swift` (and others)

```swift
struct BasicInfoView: View {
    @EnvironmentObject var coordinator: OnboardingCoordinator
    @State private var showNextButton = false
    
    var body: some View {
        // ... existing form fields ...
        
        .onChange(of: coordinator.progress.name) { _, _ in
            validateAndSave()
        }
        .onChange(of: coordinator.progress.age) { _, _ in
            validateAndSave()
        }
        .onChange(of: coordinator.progress.biologicalSex) { _, _ in
            validateAndSave()
        }
    }
    
    private func validateAndSave() {
        // Validate minimum required fields
        showNextButton = coordinator.progress.name != nil &&
                        coordinator.progress.age != nil &&
                        coordinator.progress.biologicalSex != nil
        
        // Auto-save after validation
        if showNextButton {
            Task {
                await coordinator.saveProgress()
            }
        }
    }
}
```

#### Task 3.3: Handle Interrupted Onboarding
**File:** `NutriSync/Views/ContentView.swift` (UPDATE)

```swift
// Add to ContentView
@State private var existingProgress: OnboardingProgress?

private func checkProfileExistence() async {
    guard firebaseConfig.isAuthenticated else { return }
    
    isCheckingProfile = true
    do {
        // Check for completed profile
        hasProfile = try await dataProvider.hasCompletedOnboarding()
        
        // If no profile, check for progress
        if !hasProfile {
            existingProgress = try await dataProvider.loadOnboardingProgress()
        }
    } catch {
        errorMessage = error.localizedDescription
        showError = true
        hasProfile = false
    }
    isCheckingProfile = false
}

// In body, pass progress to OnboardingCoordinator
OnboardingCoordinator(existingProgress: existingProgress)
```

---

### PHASE 4: Account Upgrade (Days 10-12)

#### Task 4.1: Create Account Creation View
**File:** `NutriSync/Views/Onboarding/AccountCreationView.swift` (NEW)

```swift
import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct AccountCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseConfig: FirebaseConfig
    @State private var selectedMethod: AccountMethod?
    @State private var email = ""
    @State private var password = ""
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    enum AccountMethod {
        case apple
        case email
        case skip
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.phylloAccent)
                    
                    Text("Secure Your Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Create an account to sync across devices and never lose your data")
                        .font(.subheadline)
                        .foregroundColor(.phylloTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // Benefits list
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(icon: "icloud", text: "Sync across all your devices")
                    BenefitRow(icon: "shield", text: "Secure data backup")
                    BenefitRow(icon: "arrow.triangle.2.circlepath", text: "Easy account recovery")
                    BenefitRow(icon: "bell", text: "Email notifications (optional)")
                }
                .padding()
                .background(Color.phylloCard)
                .cornerRadius(16)
                .padding(.horizontal)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)
                    
                    // Email option
                    Button(action: { selectedMethod = .email }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Continue with Email")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.phylloAccent.opacity(0.1))
                        .foregroundColor(.phylloAccent)
                        .cornerRadius(12)
                    }
                    
                    // Skip option
                    Button(action: skipAccountCreation) {
                        Text("Skip for Now")
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color.phylloBackground)
            .sheet(item: $selectedMethod) { method in
                if method == .email {
                    EmailSignUpView(
                        email: $email,
                        password: $password,
                        onComplete: handleEmailSignUp
                    )
                }
            }
            .alert("Account Creation Failed", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                return
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nil
            )
            
            Task {
                await linkAccount(with: credential)
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleEmailSignUp() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        let credential = EmailAuthProvider.credential(
            withEmail: email,
            password: password
        )
        
        Task {
            await linkAccount(with: credential)
        }
    }
    
    @MainActor
    private func linkAccount(with credential: AuthCredential) async {
        isCreating = true
        
        do {
            guard let user = Auth.auth().currentUser, user.isAnonymous else {
                throw AuthError.notAnonymous
            }
            
            let result = try await user.link(with: credential)
            
            // Update auth state
            firebaseConfig.currentUser = result.user
            firebaseConfig.isAnonymous = false
            firebaseConfig.authState = .authenticated
            
            // Show success
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            dismiss()
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isCreating = false
    }
    
    private func skipAccountCreation() {
        // Track skip event
        Analytics.logEvent("account_creation_skipped", parameters: [
            "screen": "onboarding_section_1"
        ])
        
        dismiss()
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.phylloAccent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}
```

#### Task 4.2: Add Account Prompts
**File:** `NutriSync/Views/Onboarding/OnboardingCoordinator.swift` (UPDATE)

```swift
// Add to OnboardingCoordinator
func shouldShowAccountPrompt(afterSection section: Int) -> Bool {
    // Show after Section 1 (basic info collected)
    guard section == 1 else { return false }
    
    // Only if still anonymous
    guard Auth.auth().currentUser?.isAnonymous == true else { return false }
    
    // Check if already dismissed once
    let hasSkippedBefore = UserDefaults.standard.bool(forKey: "skippedAccountCreation")
    
    return !hasSkippedBefore
}
```

#### Task 4.3: Settings Account Management
**File:** `NutriSync/Views/Settings/AccountSettingsView.swift` (NEW)

```swift
struct AccountSettingsView: View {
    @EnvironmentObject var firebaseConfig: FirebaseConfig
    @State private var showAccountCreation = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        List {
            Section("Account Status") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(firebaseConfig.isAnonymous ? "Guest" : "Registered")
                        .foregroundColor(.phylloTextSecondary)
                }
                
                if !firebaseConfig.isAnonymous,
                   let email = firebaseConfig.currentUser?.email {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.phylloTextSecondary)
                    }
                }
            }
            
            if firebaseConfig.isAnonymous {
                Section {
                    Button(action: { showAccountCreation = true }) {
                        Label("Create Account", systemImage: "person.badge.plus")
                            .foregroundColor(.phylloAccent)
                    }
                } footer: {
                    Text("Secure your data and enable sync across devices")
                }
            }
            
            Section {
                Button(action: { showDeleteConfirmation = true }) {
                    Label("Delete Account", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showAccountCreation) {
            AccountCreationView()
        }
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This will permanently delete all your data. This action cannot be undone.")
        }
    }
}
```

---

### PHASE 5: Polish & Testing (Days 13-15)

#### Task 5.1: Error Handling & Recovery
**File:** `NutriSync/Services/ErrorHandling/AuthErrorHandler.swift` (NEW)

```swift
enum AuthError: LocalizedError {
    case notAuthenticated
    case notAnonymous
    case networkUnavailable
    case profileCreationFailed
    case emailAlreadyInUse
    case weakPassword
    case invalidEmail
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to continue"
        case .notAnonymous:
            return "Account upgrade is only available for guest users"
        case .networkUnavailable:
            return "Please check your internet connection"
        case .profileCreationFailed:
            return "Failed to create your profile. Please try again"
        case .emailAlreadyInUse:
            return "This email is already associated with another account"
        case .weakPassword:
            return "Please use a stronger password (at least 6 characters)"
        case .invalidEmail:
            return "Please enter a valid email address"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Your data is saved locally and will sync when connected"
        case .emailAlreadyInUse:
            return "Try signing in with this email or use a different one"
        case .weakPassword:
            return "Use a mix of letters, numbers, and symbols"
        default:
            return nil
        }
    }
}
```

#### Task 5.2: Loading States
**File:** `NutriSync/Views/Components/LoadingView.swift` (NEW)

```swift
struct LoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .phylloAccent))
                .scaleEffect(1.5)
                .onAppear {
                    isAnimating = true
                }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.phylloTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.phylloBackground)
    }
}
```

#### Task 5.3: TestFlight Detection
**File:** `NutriSync/Utils/TestFlightDetector.swift` (NEW)

```swift
struct TestFlightDetector {
    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
    
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static func setupTestFlightAnalytics() {
        if isTestFlight {
            Analytics.setUserProperty("true", forName: "testflight_user")
            Analytics.logEvent("testflight_launch", parameters: [
                "build_number": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            ])
        }
    }
}
```

#### Task 5.4: Comprehensive Testing
**File:** `Testing Checklist.md` (NEW)

```markdown
# Testing Checklist

## Fresh Install Flow
- [ ] App launches successfully
- [ ] Anonymous auth completes silently
- [ ] Onboarding starts immediately
- [ ] All onboarding screens navigate correctly
- [ ] Account prompt appears after Section 1
- [ ] Skip account creation works
- [ ] Profile saves successfully
- [ ] Initial windows generate
- [ ] Main app loads

## Account Creation Flow
- [ ] Apple Sign In works
- [ ] Email sign up works
- [ ] Anonymous data preserved after upgrade
- [ ] Auth state updates correctly
- [ ] Profile linked to new account

## Interrupted Onboarding
- [ ] Kill app mid-onboarding
- [ ] Relaunch resumes from correct screen
- [ ] Previous data preserved
- [ ] Can complete from resumed state

## Network Failure
- [ ] Airplane mode during onboarding
- [ ] Data queued for retry
- [ ] Error messages clear
- [ ] Recovery works when reconnected

## Edge Cases
- [ ] Timezone change during onboarding
- [ ] Low storage scenario
- [ ] Rapid navigation between screens
- [ ] Background/foreground transitions
- [ ] Account already exists error
```

---

## 📊 Success Metrics

### TestFlight Metrics to Track
1. **Onboarding Completion Rate**: Target > 90%
2. **Account Creation Rate**: Target > 30% voluntary
3. **Drop-off Points**: Identify problematic screens
4. **Time to Complete**: Target < 5 minutes
5. **Error Frequency**: Target < 1%
6. **Skip Patterns**: Which sections users skip

### Firebase Analytics Events
```swift
// Key events to track
Analytics.logEvent("onboarding_started", parameters: nil)
Analytics.logEvent("section_completed", parameters: ["section": sectionNumber])
Analytics.logEvent("account_prompt_shown", parameters: ["timing": "after_section_1"])
Analytics.logEvent("account_created", parameters: ["method": "apple/email"])
Analytics.logEvent("account_skipped", parameters: ["screen": screenName])
Analytics.logEvent("onboarding_completed", parameters: ["duration": seconds])
Analytics.logEvent("profile_created", parameters: ["anonymous": isAnonymous])
```

---

## 🚨 Risk Mitigation

### High Priority Risks
1. **Data Loss During Onboarding**
   - Mitigation: Progressive saving after each section
   - Fallback: Local storage backup

2. **Auth State Inconsistency**
   - Mitigation: Single source of truth (FirebaseConfig)
   - Fallback: Force re-authentication

3. **Network Failures**
   - Mitigation: Offline queue for operations
   - Fallback: Local-first approach

### Medium Priority Risks
1. **Account Linking Failures**
   - Mitigation: Clear error messages
   - Fallback: Manual account creation

2. **Performance Issues**
   - Mitigation: Lazy loading, pagination
   - Fallback: Reduced animations

---

## 🔄 Rollback Plan

If critical issues discovered:
1. Revert to previous commit
2. Disable account creation temporarily
3. Use local storage only
4. Ship basic version, iterate

---

## 📅 Timeline Summary

### Week 1 (Days 1-7)
- Foundation and Profile Integration
- Core authentication flow
- Basic onboarding saves

### Week 2 (Days 8-14)
- Progressive Saving and Account Upgrade
- Account creation UI
- Error handling

### Week 3 (Days 15+)
- Polish and Testing
- TestFlight preparation
- Bug fixes based on testing

---

## ✅ Definition of Done

- [ ] Anonymous auth works on first launch
- [ ] Profile existence check routes correctly
- [ ] Onboarding saves progressively
- [ ] Account creation optional but functional
- [ ] All error states handled gracefully
- [ ] TestFlight metrics tracking enabled
- [ ] Comprehensive testing completed
- [ ] Documentation updated
- [ ] Code reviewed and cleaned

---

**PHASE 2: PLANNING COMPLETE**

This plan provides a comprehensive roadmap for implementing Option C (Hybrid Progressive) authentication and onboarding integration. The approach prioritizes user experience while maintaining data safety and providing flexibility for both anonymous and authenticated users.

Ready to proceed to Phase 3: Implementation when you start a new session.
# NutriSync Privacy Compliance Implementation Plan
## Multi-State Privacy Law Compliance (CCPA/CPRA, VCDPA, CPA, etc.)

**Created:** 2025-10-18
**Status:** Planning Phase
**Target Completion:** TBD
**Priority:** HIGH - Legal Compliance Required

---

## Executive Summary

NutriSync must comply with comprehensive privacy laws in 12+ US states (California, Virginia, Colorado, Connecticut, Utah, Montana, Oregon, Texas, Iowa, Delaware, Indiana, Tennessee, Florida, etc.). These laws grant consumers specific rights over their personal data.

**Critical Finding:** NutriSync currently has **NO opt-out mechanism for AI-powered automated decision-making**, which is a **REQUIRED** feature under several state laws (especially California CPRA).

---

## Current State Analysis

### ✅ What We Have
- Full account deletion (Firestore + Auth)
- Data correction capabilities (edit profile, meals, windows)
- UserDefaults cleanup on deletion
- Firebase Auth sign-out

### ❌ What We're Missing
1. **Data Export System** - Users can't download their data
2. **AI Opt-Out Controls** - No way to disable AI processing
3. **Privacy Request Workflow** - No formal system for privacy requests
4. **Granular Consent Management** - All-or-nothing approach
5. **Third-Party Disclosure** - Google Vertex AI sharing not clearly disclosed

---

## Data Inventory

### Personal Information We Collect

| Category | Data Points | Purpose | Third-Party Sharing |
|----------|-------------|---------|-------------------|
| **Identity** | Name, age, gender | Personalization, calorie calculation | None |
| **Biometric** | Height, weight, weight history | Goal tracking, calorie calculation | None |
| **Health** | Dietary restrictions, allergies, nutrition goals | Meal recommendations, safety | **Google Vertex AI** |
| **Nutrition** | Meal logs, calories, macros, micronutrients | Progress tracking, analytics | **Google Vertex AI** |
| **Behavioral** | Meal timing, sleep schedule, work schedule, check-ins | AI window generation | **Google Vertex AI** |
| **Device** | Meal photos, voice recordings | Meal analysis | **Google Vertex AI** |
| **Usage** | App interactions, window completion | Analytics, insights | None |

### Automated Decision-Making (Profiling)

| Process | Impact on User | User Control | Opt-Out Available? |
|---------|---------------|--------------|-------------------|
| **AI Meal Analysis** | Determines nutrition content | None | ❌ No |
| **AI Window Generation** | Tells user when to eat (significant!) | None | ❌ No |
| **Food Recommendations** | Suggests specific foods | None | ❌ No |
| **Macro Redistribution** | Adjusts daily targets | Accept/decline nudge | ⚠️ Partial |

**Legal Risk:** AI Window Generation constitutes "profiling" under CPRA § 1798.140(ag) - "processing of a consumer's personal information to evaluate, analyze, or predict personal aspects...relating to health." Users MUST have opt-out rights.

---

## Implementation Requirements

### Phase 1: Data Export System (HIGH PRIORITY)

**Legal Requirement:** Right to data portability (CCPA § 1798.100, 1798.110)

**User Story:** "As a user, I can download all my personal data in a machine-readable format (JSON/CSV)."

**Implementation Spec:**

```swift
// Service: DataExportService.swift
class DataExportService {
    func exportAllUserData(userId: String) async throws -> ExportPackage {
        // 1. Gather all user data from Firestore
        let profile = try await dataProvider.getUserProfile()
        let goals = try await dataProvider.getUserGoals()
        let meals = try await getMealsForAllTime(userId)
        let windows = try await getWindowsForAllTime(userId)
        let weightEntries = try await dataProvider.getRecentWeightEntries(userId, days: 365)
        let dailySync = try await getAllDailySyncs(userId)
        let analytics = try await getAllAnalytics(userId)

        // 2. Format as JSON
        let exportData = UserDataExport(
            profile: profile,
            goals: goals,
            meals: meals,
            windows: windows,
            weightHistory: weightEntries,
            dailySyncs: dailySync,
            analytics: analytics,
            exportDate: Date(),
            format: "JSON v1.0"
        )

        // 3. Generate downloadable file
        return try createExportPackage(exportData)
    }

    func exportAsCSV(userId: String) async throws -> [CSVFile] {
        // Alternative format for spreadsheet users
    }
}

// Model: UserDataExport.swift
struct UserDataExport: Codable {
    let profile: UserProfile
    let goals: UserGoals
    let meals: [LoggedMeal]
    let windows: [MealWindow]
    let weightHistory: [WeightEntry]
    let dailySyncs: [DailySync]
    let analytics: [DailyAnalytics]
    let exportDate: Date
    let format: String
}
```

**UI Flow:**
1. Settings > Privacy & Data > Download My Data
2. Show loading screen (may take 30-60 seconds)
3. Present share sheet with JSON/ZIP file
4. User can share via email, AirDrop, save to Files

**File Format:**
```json
{
  "export_info": {
    "user_id": "abc123...",
    "export_date": "2025-10-18T10:30:00Z",
    "format_version": "1.0"
  },
  "profile": {
    "name": "John Doe",
    "age": 30,
    "gender": "male",
    "height": 70,
    "weight": 170,
    ...
  },
  "meals": [
    {
      "id": "meal-1",
      "name": "Chicken Salad",
      "timestamp": "2025-10-18T12:00:00Z",
      "calories": 450,
      "protein": 35,
      ...
    }
  ],
  "windows": [...],
  "weight_history": [...],
  "analytics": [...]
}
```

**Testing:**
- Export with 0 meals (new user)
- Export with 1000+ meals (heavy user)
- Export with images (handle large files)
- CSV format validation

---

### Phase 2: AI Opt-Out Controls (CRITICAL PRIORITY)

**Legal Requirement:** Right to opt-out of profiling (CPRA § 1798.120, 1798.121)

**User Story:** "As a user, I can disable AI-powered features and use the app with manual controls only."

**Implementation Spec:**

```swift
// Model: PrivacyPreferences.swift
struct PrivacyPreferences: Codable {
    var allowAIMealAnalysis: Bool = true
    var allowAIWindowGeneration: Bool = true
    var allowDataSharingWithGoogle: Bool = true
    var allowAnalyticsCollection: Bool = true

    var lastUpdated: Date = Date()
    var consentVersion: String = "1.0"
}

// Extension: FirebaseDataProvider+Privacy.swift
extension FirebaseDataProvider {
    func savePrivacyPreferences(_ prefs: PrivacyPreferences) async throws {
        guard let userRef = userRef else { throw DataProviderError.notAuthenticated }
        try await userRef.collection("privacy").document("preferences").setData(prefs.toFirestore())
    }

    func getPrivacyPreferences() async throws -> PrivacyPreferences {
        guard let userRef = userRef else { throw DataProviderError.notAuthenticated }
        let doc = try await userRef.collection("privacy").document("preferences").getDocument()
        return PrivacyPreferences.fromFirestore(doc.data()) ?? PrivacyPreferences()
    }
}

// Service: PrivacyControlService.swift
class PrivacyControlService: ObservableObject {
    @Published var preferences = PrivacyPreferences()

    func checkAIPermission(for feature: AIFeature) -> Bool {
        switch feature {
        case .mealAnalysis:
            return preferences.allowAIMealAnalysis
        case .windowGeneration:
            return preferences.allowAIWindowGeneration
        }
    }

    func disableAllAI() async throws {
        preferences.allowAIMealAnalysis = false
        preferences.allowAIWindowGeneration = false
        preferences.allowDataSharingWithGoogle = false
        try await FirebaseDataProvider.shared.savePrivacyPreferences(preferences)
    }
}
```

**Behavioral Changes When AI is Disabled:**

| Feature | AI Enabled | AI Disabled (Fallback) |
|---------|-----------|----------------------|
| Meal Logging | Photo/voice → AI analysis | Manual entry only (calories, macros, name) |
| Window Generation | AI creates personalized schedule | User manually creates windows OR basic template |
| Food Suggestions | AI-powered recommendations | Generic food database lookup |
| Macro Redistribution | AI calculates adjustments | User manually adjusts or fixed split |

**UI Implementation:**

```swift
// View: PrivacyControlsView.swift
struct PrivacyControlsView: View {
    @StateObject private var privacyService = PrivacyControlService()

    var body: some View {
        List {
            Section {
                Toggle("AI Meal Analysis", isOn: $privacyService.preferences.allowAIMealAnalysis)
                    .onChange(of: privacyService.preferences.allowAIMealAnalysis) { _ in
                        Task { try? await privacyService.savePreferences() }
                    }
            } header: {
                Text("AI-Powered Features")
            } footer: {
                Text("When disabled, you'll manually enter meal information. Your meal photos will NOT be sent to Google.")
            }

            Section {
                Toggle("AI Meal Window Generation", isOn: $privacyService.preferences.allowAIWindowGeneration)
            } footer: {
                Text("When disabled, you'll create meal windows manually or use basic templates. Your profile data will NOT be sent to Google.")
            }

            Section {
                Toggle("Share Data with Google AI", isOn: $privacyService.preferences.allowDataSharingWithGoogle)
            } footer: {
                Text("Google Vertex AI (Gemini) processes your meal photos and profile to provide personalized recommendations. Disabling this will turn off all AI features.")
            }

            Section {
                Button("Disable All AI Features") {
                    Task {
                        try? await privacyService.disableAllAI()
                    }
                }
                .foregroundColor(.red)
            } footer: {
                Text("This will turn off all AI-powered analysis and switch to manual controls.")
            }
        }
        .navigationTitle("Privacy Controls")
    }
}
```

**Testing:**
- Disable AI meal analysis → Manual entry UI appears
- Disable AI window gen → Manual window creator appears
- Disable Google sharing → No API calls to Vertex AI
- Re-enable features → Works normally

---

### Phase 3: Privacy Request Workflow (MEDIUM PRIORITY)

**Legal Requirement:** Provide mechanisms for exercising privacy rights (CCPA § 1798.130)

**User Story:** "As a user, I can submit formal privacy requests (access, deletion, correction) and track their status."

**Implementation Spec:**

```swift
// Model: PrivacyRequest.swift
enum PrivacyRequestType: String, Codable {
    case dataAccess = "access"           // CCPA § 1798.110
    case dataDeletion = "deletion"       // CCPA § 1798.105
    case dataCorrection = "correction"   // CPRA § 1798.106
    case optOutSale = "opt_out_sale"     // CCPA § 1798.120 (N/A - we don't sell)
    case optOutProfiling = "opt_out_profiling" // CPRA § 1798.121
}

enum PrivacyRequestStatus: String, Codable {
    case submitted
    case verifying      // 10 days to verify identity
    case processing     // 45 days to fulfill
    case completed
    case denied         // With reason
}

struct PrivacyRequest: Codable, Identifiable {
    let id: UUID
    let userId: String
    let type: PrivacyRequestType
    var status: PrivacyRequestStatus
    let requestDate: Date
    var completionDate: Date?
    var denialReason: String?
    var notes: String?
}

// Service: PrivacyRequestService.swift
class PrivacyRequestService {
    func submitRequest(type: PrivacyRequestType, notes: String?) async throws -> PrivacyRequest {
        let request = PrivacyRequest(
            id: UUID(),
            userId: Auth.auth().currentUser?.uid ?? "",
            type: type,
            status: .submitted,
            requestDate: Date(),
            notes: notes
        )

        // Save to Firestore
        try await saveToFirestore(request)

        // Send notification to admin/compliance team
        try await notifyComplianceTeam(request)

        return request
    }

    func getMyRequests() async throws -> [PrivacyRequest] {
        // Fetch user's privacy requests
    }
}
```

**UI Flow:**
1. Settings > Privacy & Data > Submit Privacy Request
2. Select request type (Access, Delete, Correct, Opt-Out)
3. Add optional notes/details
4. Submit → Confirmation screen with request ID
5. Track status in Settings > My Privacy Requests

**Admin Dashboard (Future):**
- View pending requests
- Verify user identity
- Fulfill or deny requests
- Generate compliance reports

**Legal Compliance:**
- 10 days to verify identity (CCPA § 1798.140(x))
- 45 days to fulfill request (CCPA § 1798.130(a)(2))
- Can extend 45 days with notice (CCPA § 1798.130(a)(2))
- Must provide denial reason if denied

---

### Phase 4: Enhanced Privacy Policy (HIGH PRIORITY)

**Legal Requirement:** Clear, conspicuous disclosures (CCPA § 1798.100(b))

**Required Disclosures:**

#### Categories of Personal Information We Collect
```markdown
## Personal Information We Collect

| Category | Examples | Business Purpose |
|----------|----------|-----------------|
| **Identifiers** | Name, email, user ID | Account management, personalization |
| **Personal Characteristics** | Age, gender, height, weight | Calorie calculation, goal setting |
| **Health Information** | Dietary restrictions, allergies, nutrition goals, meal logs | Meal recommendations, safety, progress tracking |
| **Biometric Information** | Weight measurements over time | Goal tracking, trend analysis |
| **Geolocation** | None - we do not collect location data | N/A |
| **Audio/Visual** | Meal photos, voice recordings (transcribed) | Meal identification and nutrition analysis |
| **Professional** | Work schedule type (e.g., night shift, remote) | Meal timing optimization |
| **Inferences** | Predicted meal preferences, optimal meal timing | Personalized recommendations |
```

#### Third-Party Data Sharing
```markdown
## How We Share Your Information

We share your personal information with the following third parties:

**Google LLC (Vertex AI / Gemini)**
- **What we share:** Meal photos, voice transcripts, dietary preferences, nutrition goals, historical meal patterns
- **Purpose:** AI-powered meal analysis and personalized meal window generation
- **Your control:** You can opt-out in Settings > Privacy Controls > AI Features
- **Their privacy policy:** https://policies.google.com/privacy

**Firebase (Google LLC)**
- **What we share:** All user data (stored on Firebase servers)
- **Purpose:** Cloud database, authentication, analytics
- **Location:** United States
- **Their privacy policy:** https://firebase.google.com/support/privacy

We do NOT sell your personal information.
We do NOT share your data for targeted advertising.
```

#### Automated Decision-Making Disclosure
```markdown
## Automated Decision-Making

NutriSync uses artificial intelligence to make automated decisions that may significantly affect you:

**AI Meal Analysis**
- **What it does:** Analyzes photos and voice descriptions to estimate calories, macros, and ingredients
- **Impact:** Affects your daily nutrition tracking and progress metrics
- **Your control:** Opt-out available (Settings > Privacy Controls) - switch to manual entry

**AI Meal Window Generation**
- **What it does:** Creates personalized eating schedules based on your profile, goals, and daily context
- **Impact:** Determines when you should eat meals throughout the day
- **Your control:** Opt-out available (Settings > Privacy Controls) - create manual schedules
- **Logic:** Uses generative AI (Google Gemini) with inputs including: nutrition goals, work schedule, sleep patterns, dietary restrictions, past meal timing, activity level

**Food Recommendations**
- **What it does:** Suggests specific foods and meal ideas for each eating window
- **Impact:** Influences your food choices
- **Your control:** Opt-out available (Settings > Privacy Controls) - no suggestions shown

You have the right to opt-out of automated decision-making. When opted out, you will manually enter meal data and create your own meal schedules.
```

#### Your Privacy Rights
```markdown
## Your Privacy Rights (US Residents)

If you are a resident of California, Virginia, Colorado, Connecticut, Utah, or other states with comprehensive privacy laws, you have the following rights:

**Right to Know (Access)**
- Request to know what personal information we have collected about you
- Request to know how we use and share your information
- Download all your data in a portable format (JSON/CSV)
- **How to exercise:** Settings > Privacy & Data > Download My Data

**Right to Delete**
- Request deletion of your personal information
- **How to exercise:** Settings > Account > Delete Account & Data
- **Note:** Deletion is permanent and cannot be undone

**Right to Correct**
- Request correction of inaccurate personal information
- **How to exercise:** Settings > Profile (edit directly) OR submit correction request

**Right to Opt-Out**
- Opt-out of AI-powered profiling and automated decision-making
- **How to exercise:** Settings > Privacy Controls > AI Features
- **Note:** We do NOT sell personal information, so opt-out of "sale" is not applicable

**Right to Data Portability**
- Receive your personal information in a portable, machine-readable format
- **How to exercise:** Settings > Privacy & Data > Download My Data (JSON/CSV)

**Right to Non-Discrimination**
- We will not discriminate against you for exercising your privacy rights
- You will not be denied service or charged different prices

**Submitting Privacy Requests**
- In-app: Settings > Privacy & Data > Submit Privacy Request
- Email: privacy@nutrisync.app
- Response time: We will respond within 10 days and fulfill requests within 45 days

**Authorized Agents**
You may designate an authorized agent to submit privacy requests on your behalf. Email privacy@nutrisync.app with written authorization.
```

---

### Phase 5: User Interface Updates

**New Settings Sections:**

```
Settings
├── Account
│   ├── Account Status
│   ├── Sign Out
│   └── Delete Account & Data ✅ (exists)
├── Privacy & Data ⭐ (NEW)
│   ├── Privacy Controls
│   │   ├── AI Meal Analysis (toggle)
│   │   ├── AI Window Generation (toggle)
│   │   ├── Share Data with Google (toggle)
│   │   └── Analytics Collection (toggle)
│   ├── Download My Data
│   │   ├── Export as JSON
│   │   └── Export as CSV
│   ├── Submit Privacy Request
│   │   ├── Request Data Access
│   │   ├── Request Data Deletion
│   │   ├── Request Data Correction
│   │   └── Opt-Out of AI Profiling
│   └── My Privacy Requests
│       └── [List of submitted requests with status]
├── Privacy Policy (link)
└── Terms of Service (link)
```

---

## Implementation Timeline

| Phase | Priority | Estimated Effort | Dependencies |
|-------|----------|-----------------|--------------|
| **Phase 1: Data Export** | HIGH | 3-5 days | None |
| **Phase 2: AI Opt-Out** | CRITICAL | 5-7 days | Requires fallback UI for manual meal entry |
| **Phase 3: Privacy Requests** | MEDIUM | 3-4 days | Admin dashboard (future) |
| **Phase 4: Privacy Policy** | HIGH | 1-2 days | Legal review recommended |
| **Phase 5: UI Updates** | MEDIUM | 2-3 days | Phases 1-3 |
| **Phase 6: Testing** | HIGH | 3-4 days | All phases |

**Total Estimated Effort:** 17-25 days

---

## Testing Checklist

### Data Export
- [ ] Export data for new user (0 meals)
- [ ] Export data for active user (100+ meals)
- [ ] Export data for heavy user (1000+ meals, 365 days)
- [ ] Verify JSON format is valid
- [ ] Verify CSV format opens in Excel/Sheets
- [ ] Test file sharing via email, AirDrop, Files app
- [ ] Ensure meal images are NOT included (privacy)

### AI Opt-Out
- [ ] Disable AI meal analysis → Manual entry UI appears
- [ ] Manual entry saves correctly to Firestore
- [ ] Disable AI window generation → Manual window UI appears
- [ ] Manual windows save correctly
- [ ] Verify NO calls to Vertex AI when disabled
- [ ] Re-enable AI features → Everything works normally
- [ ] Test "Disable All AI" button

### Privacy Requests
- [ ] Submit data access request → Request saved
- [ ] Submit deletion request → Request saved
- [ ] View my requests → List appears correctly
- [ ] Admin can view requests (if dashboard exists)

### Privacy Policy
- [ ] All third-party services disclosed
- [ ] Automated decision-making clearly explained
- [ ] Privacy rights section is accurate
- [ ] Links to Google privacy policies work

---

## Legal Considerations

### State-Specific Requirements

**California (CPRA):**
- ✅ Right to know categories and specific pieces of data
- ✅ Right to delete
- ✅ Right to correct
- ⚠️ Right to opt-out of sharing for "cross-context behavioral advertising" (N/A - we don't do this)
- ✅ Right to limit use of sensitive personal information (health data)
- ✅ Right to opt-out of automated decision-making

**Virginia (VCDPA):**
- ✅ Right to access
- ✅ Right to delete
- ✅ Right to correct
- ✅ Right to data portability
- ✅ Right to opt-out of profiling

**Colorado (CPA):**
- ✅ Right to opt-out of profiling with "legal or similarly significant effects"
- ⚠️ AI window generation DOES have "significant effects" on health

### Sensitive Personal Information

**What qualifies as "sensitive" under state laws:**
- ✅ Health information (meal logs, dietary restrictions, allergies)
- ✅ Biometric information (weight measurements)
- ⚠️ Precise geolocation (we don't collect this)
- ⚠️ Genetic data (we don't collect this)

**Requirements for sensitive data:**
- Must obtain explicit consent (or allow opt-out)
- Must disclose purpose of collection
- Must limit use to disclosed purposes

**Current Status:**
- ⚠️ We collect health data but don't have explicit "sensitive data" consent flow
- ⚠️ Recommendation: Add consent screen during onboarding

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **User sues for CCPA violation** | Low | High ($7,500/violation) | Implement all features ASAP |
| **State AG investigation** | Very Low | Very High | Implement + update privacy policy |
| **Google changes Vertex AI terms** | Medium | Medium | Monitor Google privacy changes |
| **User can't export data on request** | Medium | High | Implement data export immediately |
| **AI opt-out not available** | High | Critical | Implement AI controls ASAP |

**Recommended Priority:**
1. **IMMEDIATE:** AI opt-out controls (Phase 2)
2. **HIGH:** Data export system (Phase 1)
3. **HIGH:** Privacy policy updates (Phase 4)
4. **MEDIUM:** Privacy request workflow (Phase 3)
5. **MEDIUM:** UI updates (Phase 5)

---

## Next Steps

1. **Review this plan** with stakeholders
2. **Get legal review** of privacy policy changes
3. **Prioritize implementation** - Start with Phase 2 (AI opt-out)
4. **Set timeline** for each phase
5. **Assign development resources**
6. **Plan user communication** about new privacy features

---

## Questions for Legal Counsel

1. Do we need explicit consent for "sensitive personal information" (health data) or is opt-out sufficient?
2. Should we treat AI window generation as "consequential decisions" under CPRA § 1798.137?
3. Do we need a Data Processing Agreement (DPA) with Google for Vertex AI?
4. Should we appoint a Chief Privacy Officer or Data Protection Officer?
5. Do we need to register as a "data broker" in any state? (Answer: Likely no, but confirm)
6. What retention period should we set for deleted user data backups?

---

**Document Version:** 1.0
**Last Updated:** 2025-10-18
**Author:** Claude Code
**Status:** Draft - Pending Review

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseAppCheck
import FirebaseAI

@MainActor
class FirebaseConfig: ObservableObject {
    static let shared = FirebaseConfig()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isAnonymous = true
    @Published var authState: AuthState = .unknown
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    enum AuthState: Equatable {
        case unknown
        case authenticating
        case anonymous
        case authenticated
        case failed(Error)
        
        static func == (lhs: AuthState, rhs: AuthState) -> Bool {
            switch (lhs, rhs) {
            case (.unknown, .unknown),
                 (.authenticating, .authenticating),
                 (.anonymous, .anonymous),
                 (.authenticated, .authenticated):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return (lhsError as NSError) == (rhsError as NSError)
            default:
                return false
            }
        }
    }
    
    private init() {
        // Don't setup auth listener here - Firebase isn't configured yet
    }
    
    private func setupAuthListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isAnonymous = user?.isAnonymous ?? true
                
                if let user = user {
                    self?.authState = user.isAnonymous ? .anonymous : .authenticated
                } else {
                    self?.authState = .unknown
                }
            }
        }
    }
    
    func configure() {
        // Check if GoogleService-Info.plist exists
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              FileManager.default.fileExists(atPath: path) else {
            Task { @MainActor in
                DebugLogger.shared.warning("Firebase not configured - GoogleService-Info.plist not found")
                DebugLogger.shared.warning("Using mock VertexAI service. See FIREBASE_SETUP_GUIDE.md for setup instructions")
            }
            print("⚠️ Firebase not configured - GoogleService-Info.plist not found")
            print("⚠️ Using mock VertexAI service. See FIREBASE_SETUP_GUIDE.md for setup instructions")
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Setup auth listener now that Firebase is configured
        setupAuthListener()
        
        // Set up App Check for security (optional but recommended)
        // This helps protect your Vertex AI quota from abuse
        #if DEBUG
        // Use debug provider for simulator/testing
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        // Use App Attest for production
        let providerFactory = CustomAppCheckProviderFactory()
        #endif
        
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024)) // 100MB cache
        Firestore.firestore().settings = settings
        
        // Enable offline persistence
        Firestore.firestore().settings.isPersistenceEnabled = true
        
        Task { @MainActor in
            DebugLogger.shared.firebase("Firebase configured successfully")
            DebugLogger.shared.info("App Check: \(AppCheck.appCheck().isTokenAutoRefreshEnabled ? "Enabled" : "Disabled")")
            DebugLogger.shared.info("Firestore offline persistence: Enabled")
        }
        print("✅ Firebase configured successfully")
    }
    
    func initializeAuth() async {
        authState = .authenticating
        
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            self.isAnonymous = user.isAnonymous
            self.authState = user.isAnonymous ? .anonymous : .authenticated
            DebugLogger.shared.firebase("Existing user found: \(user.uid), anonymous: \(user.isAnonymous)")
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
            DebugLogger.shared.firebase("Anonymous sign-in successful: \(result.user.uid)")
            print("✅ Anonymous auth successful: \(result.user.uid)")
        } catch {
            self.authState = .failed(error)
            DebugLogger.shared.error("Anonymous auth failed: \(error)")
            print("❌ Anonymous auth failed: \(error)")
            // Handle offline mode - app can still function with limited features
        }
    }
    
    func linkWithEmail(email: String, password: String) async throws -> User {
        guard let currentUser = currentUser, currentUser.isAnonymous else {
            throw AuthError.notAnonymous
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let result = try await currentUser.link(with: credential)
        
        self.currentUser = result.user
        self.isAnonymous = false
        self.authState = .authenticated
        
        return result.user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        self.currentUser = nil
        self.isAuthenticated = false
        self.isAnonymous = true
        self.authState = .unknown
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
}

// Define auth errors
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

// Custom App Check provider for production
class CustomAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            // Fallback for older iOS versions
            return DeviceCheckProvider(app: app)
        }
    }
}
